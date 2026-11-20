import 'package:flutter/material.dart';
import '../../../data/models/dose.dart';
import '../../../data/models/medication.dart';
import '../../../data/models/people.dart';
import '../../../data/store/app_scope.dart';
import '../../../data/store/app_store.dart';
import '../../../shared/screens/medication_form_screen.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/notice_box.dart';
import '../../../shared/widgets/origin_chip.dart';
import '../../../shared/widgets/reminder_chat.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/week_strip.dart';
import '../widgets/alert_banner.dart';

/// Ficha de um idoso no app do cuidador.
///
/// - Idoso com app: o dia, os últimos 7 dias e os remédios.
/// - Idoso sem app: a mesma tela de lembretes que o idoso receberia, para o
///   cuidador confirmar por ele, e o acompanhamento numa segunda visão.
///   A troca é por botões, não por gesto de arrastar.
class CuidadorElderScreen extends StatefulWidget {
  final String elderId;
  const CuidadorElderScreen({super.key, required this.elderId});

  @override
  State<CuidadorElderScreen> createState() => _CuidadorElderScreenState();
}

class _CuidadorElderScreenState extends State<CuidadorElderScreen> {
  bool _showReminders = true;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final elder = store.elderOrNull(widget.elderId);
    if (elder == null) return Scaffold(appBar: AppBar());

    return Scaffold(
      appBar: subPageBar(context, elder.nickname),
      body: SafeArea(
        child: elder.usesApp
            ? _FollowUp(elder: elder, store: store)
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Lembretes'), icon: Icon(Icons.chat_bubble_outline_rounded)),
                          ButtonSegment(value: false, label: Text('Acompanhar'), icon: Icon(Icons.insights_rounded)),
                        ],
                        selected: {_showReminders},
                        onSelectionChanged: (s) => setState(() => _showReminders = s.first),
                        style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 52))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _showReminders
                        ? ReminderChat(
                            elder: elder,
                            caregiverMode: true,
                            header: NoticeBox(
                              icon: Icons.phone_android_rounded,
                              title: '${elder.nickname} não usa o app',
                              text: 'Você recebe os lembretes no lugar dele e confirma quando ele tomar. '
                                  'Enquanto não confirmar, avisamos você a cada 15 minutos.',
                            ),
                          )
                        : _FollowUp(elder: elder, store: store),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FollowUp extends StatelessWidget {
  final Elder elder;
  final AppStore store;
  const _FollowUp({required this.elder, required this.store});

  void _openForm(BuildContext context, {Medication? initial}) {
    final me = store.currentUser!;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MedicationFormScreen(
        elder: elder,
        origin: MedicationOrigin.familia,
        authorName: me.firstName,
        initial: initial,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final doses = store.dosesOf(elder.id);
    final meds = store.medicationsOf(elder.id);
    final alerts = store.openAlertsFor([elder.id]);
    final week = store.last7Days(elder);
    final weekOk = week.where((s) => s == DoseStatus.tomada).length;
    final doctors = store.doctorsOf(elder);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleAvatar(radius: 30, child: Text(elder.initials, style: const TextStyle(fontWeight: FontWeight.w700))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(elder.name, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    [if (elder.age > 0) '${elder.age} anos', elder.usesApp ? 'usa o app' : 'sem app'].join(' · '),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Ver telefone de ${elder.nickname}',
              onPressed: () => showPhoneDialog(context, elder),
              icon: const Icon(Icons.call_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final a in alerts) AlertBanner(alert: a, elder: elder),
        const SectionHeading(title: 'Hoje'),
        if (doses.isEmpty) const NoticeBox(text: 'Nenhum remédio para hoje.'),
        for (final d in doses)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              minVerticalPadding: 12,
              title: Text(d.medicationName, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text([
                '${hhmm(d.scheduledAt)} · ${d.dosageText}',
                if (d.isTaken && d.confirmedAt != null)
                  'Tomou às ${hhmm(d.confirmedAt!)}${d.confirmedBy == 'cuidador' ? ', confirmado por você' : ''}',
                if (d.snoozeCount > 0 && !d.isTaken) 'Adiou ${d.snoozeCount} ${plural(d.snoozeCount, 'vez', 'vezes')}',
              ].join('\n')),
              trailing: StatusChip(status: d.status),
            ),
          ),
        const SizedBox(height: 16),
        const SectionHeading(title: 'Últimos 7 dias'),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WeekStrip(days: week, today: store.now),
                const SizedBox(height: 12),
                Text(
                  '$weekOk de 7 dias com todos os remédios no horário.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeading(title: 'Remédios', subtitle: 'Toque em um remédio para editar.'),
        if (meds.isEmpty) const NoticeBox(text: 'Nenhum remédio cadastrado ainda.'),
        for (final m in meds)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openForm(context, initial: m),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text('${m.dosage} · ${timesLabel(m.times)} · ${daysLabel(m.weekdays)}'),
                    const SizedBox(height: 8),
                    OriginChip(medication: m, viewer: UserRole.cuidador),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.add_rounded),
          label: Text('Cadastrar remédio para ${elder.nickname}'),
        ),
        const SizedBox(height: 24),
        const SectionHeading(title: 'Médicos'),
        if (doctors.isEmpty) const NoticeBox(text: 'Nenhum médico acompanha ainda.'),
        for (final d in doctors)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(d.initials)),
            title: Text(d.name),
            subtitle: Text(d.detail ?? 'Médico(a)'),
          ),
      ],
    );
  }
}
