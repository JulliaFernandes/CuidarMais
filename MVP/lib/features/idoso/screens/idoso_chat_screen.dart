import 'package:flutter/material.dart';
import '../../../data/models/people.dart';
import '../../../data/store/app_scope.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/reminder_chat.dart';
import '../../../shared/widgets/section_heading.dart';

/// Tela principal do idoso: o chat de lembretes do documento do projeto.
class IdosoChatScreen extends StatelessWidget {
  final Elder elder;
  const IdosoChatScreen({super.key, required this.elder});

  @override
  Widget build(BuildContext context) {
    final now = AppScope.of(context).now;
    return ReminderChat(
      elder: elder,
      header: SectionHeading(title: 'Olá, ${elder.nickname}', subtitle: '${longDate(now)} · ${hhmm(now)}'),
    );
  }
}
