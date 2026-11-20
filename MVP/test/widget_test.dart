// Testes de fumaça do protótipo: o app abre, o login de demonstração
// funciona e as regras de escalada passam de um perfil para o outro.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidarmais/app.dart';
import 'package:cuidarmais/data/models/care_alert.dart';
import 'package:cuidarmais/data/store/app_store.dart';

/// Rola a lista que está na frente (não a da tela de baixo nem a de uma
/// aba escondida) até achar o item e toca nele.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 150, scrollable: find.byType(Scrollable).hitTestable().last);
  // Garante que o item está inteiro na tela, e não atrás da barra de baixo.
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _loginAs(WidgetTester tester, String who) async {
  await _tapVisible(tester, find.text('Entrar'));
  await _tapVisible(tester, find.text('Entrar como $who'));
}

void main() {
  testWidgets('Abre na tela de boas-vindas', (tester) async {
    await tester.pumpWidget(const CuidarMaisApp());
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('Dona Maria entra e vê o lembrete da Losartana', (tester) async {
    await tester.pumpWidget(const CuidarMaisApp());
    await tester.pumpAndSettle();
    await _loginAs(tester, 'Dona Maria');

    // O chat abre rolado para o lembrete mais recente.
    expect(find.text('Lembretes'), findsOneWidget);
    expect(find.text('Losartana 50 mg'), findsOneWidget);
    expect(find.text('Tomei'), findsOneWidget);
    expect(find.text('Me lembra em 15 min'), findsWidgets);
  });

  // Celular pequeno (360×740) com o texto em 100% e em 200%: qualquer
  // texto que estoure a tela faz o teste falhar.
  for (final scale in [1.0, 2.0]) {
    testWidgets('Telas principais cabem no celular com texto em ${(scale * 100).round()}%', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const CuidarMaisApp());
      await tester.pumpAndSettle();
      for (var i = 0; i < (scale - 1) / 0.25; i++) {
        await tester.tap(find.byTooltip('Aumentar o texto').first);
        await tester.pumpAndSettle();
      }

      Future<void> visitTabs(List<String> tabs) async {
        for (final t in tabs) {
          await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(t)));
          await tester.pumpAndSettle();
        }
      }

      Future<void> logout() async {
        await tester.tap(find.byTooltip('Sua conta e a demonstração'));
        await tester.pumpAndSettle();
        await _tapVisible(tester, find.text('Sair')); // com texto grande, o menu rola
      }

      await _loginAs(tester, 'Dona Maria');
      await visitTabs(['Hoje', 'Remédios', 'Família', 'Lembretes']);
      await logout();

      await _loginAs(tester, 'Carla');
      await visitTabs(['Alertas', 'Início']);
      await _tapVisible(tester, find.text('Seu Antônio'));
      await tester.tap(find.text('Acompanhar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Voltar').last);
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Adicionar idoso'));
      await tester.tap(find.byTooltip('Voltar').last);
      await tester.pumpAndSettle();
      await logout();

      await _loginAs(tester, 'Dra. Helena');
      await visitTabs(['Cadastrar', 'Pacientes']);
      await _tapVisible(tester, find.text('Maria Aparecida Silva'));
      await tester.tap(find.byTooltip('Voltar').last);
      await tester.pumpAndSettle();
      await visitTabs(['Cadastrar']);
      await _tapVisible(tester, find.text('Maria Aparecida Silva'));
      expect(find.text('Revisar antes de salvar'), findsWidgets);
    });
  }

  group('Regras de escalada (store)', () {
    test('Dois adiamentos geram alerta para o cuidador', () {
      final store = AppStore();
      final dose = store.currentDose('e-maria')!;
      expect(dose.medicationName, 'Losartana 50 mg');

      store.snooze(dose);
      expect(store.openAlertsFor(['e-maria']), isEmpty);

      store.snooze(dose);
      final alerts = store.openAlertsFor(['e-maria']);
      expect(alerts, hasLength(1));
      expect(alerts.first.reason, AlertReason.adiouDuasVezes);

      store.snooze(dose); // terceira vez não é permitida
      expect(dose.snoozeCount, 2);
    });

    test('Sem resposta no prazo gera alerta', () {
      final store = AppStore();
      store.advanceClock(minutes: 30); // 08:05 → 08:35, Losartana das 08:00
      final alerts = store.openAlertsFor(['e-maria']);
      expect(alerts, hasLength(1));
      expect(alerts.first.reason, AlertReason.semResposta);
    });

    test('Confirmar encerra o alerta e não confirma duas vezes', () {
      final store = AppStore();
      final dose = store.currentDose('e-maria')!;
      store.snooze(dose);
      store.snooze(dose);
      expect(store.confirmDose(dose, byCaregiver: false), isTrue);
      expect(store.openAlertsFor(['e-maria']), isEmpty);
      expect(store.confirmDose(dose, byCaregiver: false), isFalse);
    });

    test('Idoso sem app: aviso ao cuidador a cada 15 minutos', () {
      final store = AppStore();
      final dose = store.currentDose('e-antonio')!;
      expect(dose.reminderCount, 1);
      store.advanceClock();
      expect(dose.reminderCount, 2);
      store.confirmDose(dose, byCaregiver: true);
      expect(dose.confirmedBy, 'cuidador');
    });

    test('Convite só vincula depois que o idoso aceita', () {
      final store = AppStore();
      final maria = store.elderById('e-maria');
      final invite = store.findInvite('rui-482')!;
      expect(maria.links.containsKey('u-rui'), isFalse);
      store.acceptInvite(invite, maria);
      expect(maria.links.containsKey('u-rui'), isTrue);
      expect(store.findInvite('RUI482'), isNull);
    });
  });
}
