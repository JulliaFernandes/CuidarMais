// Teste básico de fumaça: confirma que o app abre e mostra as duas abas.

import 'package:flutter_test/flutter_test.dart';

import 'package:cuidarmais/app.dart';

void main() {
  testWidgets('Abre o app e mostra as abas Idoso e Médico', (WidgetTester tester) async {
    await tester.pumpWidget(const CuidarMaisApp());
    await tester.pumpAndSettle();

    expect(find.text('Idoso'), findsOneWidget);
    expect(find.text('Médico'), findsOneWidget);
    expect(find.text('Olá, Dona Maria'), findsOneWidget);
  });
}
