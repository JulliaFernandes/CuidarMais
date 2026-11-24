import 'package:flutter/material.dart';
import '../../data/models/care_alert.dart';
import '../../data/models/dose.dart';
import '../../data/models/people.dart';
import '../../data/store/app_scope.dart';
import '../../data/store/app_store.dart';
import '../../features/idoso/widgets/dose_reminder_card.dart';
import '../utils/format.dart';
import 'chat_bubble.dart';
import 'notice_box.dart';

/// Chat de lembretes (documento do projeto v2): cada horário vira uma
/// mensagem, e o lembrete atual aparece no fim com "Tomei" e "Me lembra
/// em 15 min".
///
/// Usado em dois lugares:
/// - no app do idoso ([caregiverMode] = false): pode adiar até 2 vezes;
/// - na aba do idoso sem app, no app do cuidador ([caregiverMode] = true):
///   o cuidador confirma por ele e é avisado a cada 15 minutos.
class ReminderChat extends StatelessWidget {
  final Elder elder;
  final bool caregiverMode;
  final Widget? header;

  const ReminderChat({super.key, required this.elder, this.caregiverMode = false, this.header});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final doses = store.dosesOf(elder.id);
    final items = <Widget>[
      if (header != null) header!,
      if (doses.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: NoticeBox(
            title: 'Ainda não há remédios',
            text: caregiverMode
                ? 'Cadastre os remédios de ${elder.nickname} em "Remédios" para os lembretes começarem.'
                : 'Cadastre seus remédios na aba "Remédios" ou peça para seu cuidador cadastrar.',
          ),
        ),
      for (final d in doses.where((d) => !d.scheduledAt.isAfter(store.now))) ..._messagesFor(store, d),
    ];

    final current = store.currentDose(elder.id);
    if (current != null) {
      items.add(Padding(padding: const EdgeInsets.only(top: 8, bottom: 8), child: _currentCard(context, store, current)));
    } else if (doses.isNotEmpty) {
      items.add(Padding(padding: const EdgeInsets.only(top: 8, bottom: 8), child: _idleCard(context, store)));
    }

    // Lista invertida: a conversa começa rolada para a mensagem mais nova.
    return ListView(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: items.reversed.toList(),
    );
  }

  String get _whose => caregiverMode ? 'o remédio de ${elder.nickname}' : 'o seu remédio';

  List<Widget> _messagesFor(AppStore store, Dose d) {
    final out = <Widget>[
      ChatBubble(
        text: caregiverMode
            ? 'Hora do remédio de ${elder.nickname}: ${d.medicationName}, ${d.dosageText}.'
            : 'Está na hora do seu remédio: ${d.medicationName}, ${d.dosageText}.',
        time: hhmm(d.scheduledAt),
      ),
    ];

    if (caregiverMode) {
      for (var k = 2; k <= d.reminderCount && !d.isTaken; k++) {
        out.add(ChatBubble(
          text: 'Aviso de novo: $_whose das ${hhmm(d.scheduledAt)} ainda não foi confirmado.',
          time: hhmm(d.scheduledAt.add(Duration(minutes: 15 * (k - 1)))),
        ));
      }
    } else {
      for (var i = 1; i <= d.snoozeCount; i++) {
        final at = d.scheduledAt.add(Duration(minutes: 15 * (i - 1)));
        final next = d.scheduledAt.add(Duration(minutes: 15 * i));
        out.add(ChatBubble(text: 'Me lembra em 15 min', time: hhmm(at), fromMe: true));
        out.add(ChatBubble(
          text: i < 2
              ? 'Combinado! Chamo de novo às ${hhmm(next)}.'
              : 'Combinado. Como foi a segunda vez, avisamos ${store.caregiverNames(elder)}. '
                  'Tome assim que puder e toque em "Tomei".',
          time: hhmm(at),
        ));
        if (i < 2 && !store.now.isBefore(next)) {
          out.add(ChatBubble(text: 'Lembrando de novo: ${d.medicationName}.', time: hhmm(next)));
        }
      }
      final noAnswer = store.alerts
          .where((a) => a.doseId == d.id && a.reason == AlertReason.semResposta)
          .firstOrNull;
      if (noAnswer != null) {
        out.add(ChatSystemNote(
          text: 'Sem resposta às ${hhmm(noAnswer.createdAt)}. Avisamos ${store.caregiverNames(elder)}.',
          danger: true,
        ));
      }
    }

    if (d.isTaken && d.confirmedAt != null) {
      final at = hhmm(d.confirmedAt!);
      final next = _nextAfter(store, d);
      out.add(ChatBubble(text: caregiverMode ? 'Tomou' : 'Tomei', time: at, fromMe: true));
      out.add(ChatBubble(
        text: [
          caregiverMode ? 'Registrado como confirmado por você.' : 'Anotado! Registrado às $at.',
          if (store.alertedEver(d.id) && !caregiverMode) '${store.caregiverNames(elder)} já sabe que está tudo bem.',
          if (next != null) 'O próximo é ${next.medicationName}, às ${hhmm(next.scheduledAt)}.',
        ].join(' '),
        time: at,
      ));
    }
    return out;
  }

  Dose? _nextAfter(AppStore store, Dose d) =>
      store.dosesOf(elder.id).where((x) => x.scheduledAt.isAfter(d.scheduledAt) && x.isOpen).firstOrNull;

  Widget _currentCard(BuildContext context, AppStore store, Dose d) {
    final messenger = ScaffoldMessenger.of(context);
    void say(String text) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
    }

    final next = store.nextReminderAt(d);

    if (caregiverMode) {
      return DoseReminderCard(
        dose: d,
        takeLabel: 'Confirmar que tomou',
        note: [
          'Avisamos você ${d.reminderCount} ${plural(d.reminderCount, 'vez', 'vezes')}.',
          if (next != null) 'Próximo aviso às ${hhmm(next)}.',
          'Enquanto não confirmar, chega um aviso novo a cada 15 minutos.',
        ].join(' '),
        onTake: () {
          if (store.confirmDose(d, byCaregiver: true)) {
            say('${d.medicationName} confirmado por você.');
          }
        },
        onSnooze: () {
          store.remindCaregiverLater(d);
          say(next == null ? 'Combinado. Avisamos de novo em 15 minutos.' : 'Combinado. Avisamos de novo às ${hhmm(next)}.');
        },
      );
    }

    return DoseReminderCard(
      dose: d,
      lateMessage: '${store.caregiverNames(elder)} já recebeu um alerta. Toque em "Tomei" assim que puder.',
      note: d.snoozeCount == 1
          ? [if (next != null) 'Vou te lembrar de novo às ${hhmm(next)}.', 'Você pode adiar mais 1 vez.'].join(' ')
          : null,
      onTake: () {
        if (store.confirmDose(d, byCaregiver: false)) {
          say('Anotado! ${d.medicationName} marcado como tomado às ${hhmm(store.now)}.');
        }
      },
      onSnooze: d.snoozeCount >= 2
          ? null
          : () {
              final willBe = d.snoozeCount + 1;
              final again = store.nextReminderAt(d, snoozeCount: willBe);
              store.snooze(d);
              say(willBe >= 2
                  ? 'Sem problema. ${store.caregiverNames(elder)} também recebeu um alerta desta vez.'
                  : again == null
                      ? 'Combinado! Chamo de novo em instantes.'
                      : 'Combinado! Chamo de novo às ${hhmm(again)}.');
            },
    );
  }

  Widget _idleCard(BuildContext context, AppStore store) {
    final next = store.nextDose(elder.id);
    if (next == null) {
      return NoticeBox(
        tone: NoticeTone.success,
        icon: Icons.celebration_rounded,
        title: caregiverMode ? 'Tudo confirmado hoje' : 'Você tomou todos os remédios de hoje!',
        text: caregiverMode ? 'Não há mais remédios de ${elder.nickname} para hoje.' : 'Até amanhã.',
      );
    }
    return NoticeBox(
      icon: Icons.schedule_rounded,
      title: 'Nenhum remédio agora',
      text: 'O próximo é ${next.medicationName}, às ${hhmm(next.scheduledAt)}. '
          '${caregiverMode ? 'Avisamos você' : 'Avisamos'} na hora.',
    );
  }
}
