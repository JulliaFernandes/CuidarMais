import 'package:flutter/material.dart';
import '../../../data/models/medication.dart';
import '../../../data/models/people.dart';
import '../../../data/store/app_scope.dart';
import '../../../shared/screens/medication_form_screen.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/notice_box.dart';
import '../../../shared/widgets/origin_chip.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../../shared/widgets/status_chip.dart';
import '../widgets/adherence_heatmap.dart';
import '../widgets/adherence_ring.dart';

/// Relatório do paciente: anel de adesão, heatmap de 14 dias por período,
/// doses de hoje (com quem confirmou) e remédios com a origem de cada um.
/// Título da página já diz quem é o paciente (WCAG 2.4.2).
class MedicoPatientScreen extends StatelessWidget {
  final String elderId;
  const MedicoPatientScreen({super.key, required this.elderId});

  void _openForm(BuildContext context, Elder elder, {Medication? initial}) {
    final me = AppScope.read(context).currentUser!;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MedicationFormScreen(
        elder: elder,
        origin: MedicationOrigin.medico,
        authorName: me.name,
        initial: initial,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final elder = store.elderOrNull(elderId);
    if (elder == null) return Scaffold(appBar: AppBar());
    final patient = store.summaryOf(elder);

    return Scaffold(
      appBar: subPageBar(context, patient.name),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AdherenceRing(breakdown: patient.historyBreakdown, percent: patient.adherencePercent),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (patient.age > 0) Text('${patient.age} anos', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(patient.conditions, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InfoPill(icon: Icons.people_alt_outlined, label: 'Cuidador: ${patient.caregiverName}'),
                          InfoPill(
                            icon: patient.usesApp ? Icons.phone_android_rounded : Icons.phonelink_erase_rounded,
                            label: patient.usesApp ? 'Usa o app' : 'Sem app: o cuidador confirma',
                            tone: patient.usesApp ? NoticeTone.info : NoticeTone.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (patient.openAlert != null) ...[
              const SizedBox(height: 20),
              NoticeBox(tone: NoticeTone.danger, text: patient.openAlert!),
            ],
            const SizedBox(height: 28),
            const SectionHeading(
              title: 'Mapa de 14 dias',
              subtitle: 'Manhã, tarde e noite — ajuda a achar um padrão de esquecimento',
            ),
            const SizedBox(height: 8),
            AdherenceHeatmap(patient: patient),
            const SizedBox(height: 28),
            const SectionHeading(title: 'Doses de hoje'),
            if (patient.todayDoses.isEmpty) const NoticeBox(text: 'Nenhuma dose hoje.'),
            ...patient.todayDoses.map(
              (d) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(d.medicationName),
                  subtitle: Text([
                    '${d.dosageText} · às ${hhmm(d.scheduledAt)}',
                    if (d.snoozeCount > 0) 'Adiou ${d.snoozeCount} ${plural(d.snoozeCount, 'vez', 'vezes')}',
                    if (d.isTaken && d.confirmedAt != null)
                      'Confirmado às ${hhmm(d.confirmedAt!)} ${d.confirmedBy == 'cuidador' ? 'pelo cuidador' : 'pelo paciente'}',
                  ].join('\n')),
                  trailing: StatusChip(status: d.status),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const SectionHeading(
              title: 'Medicamentos',
              subtitle: 'A sua prescrição prevalece se houver divergência com o que a família ou o paciente cadastrou.',
            ),
            for (final m in patient.medications)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openForm(context, elder, initial: m),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text('${m.dosage} · ${timesLabel(m.times)} · ${daysLabel(m.weekdays)}'),
                        const SizedBox(height: 8),
                        OriginChip(medication: m, viewer: UserRole.medico),
                        if (m.history.length > 1) ...[
                          const SizedBox(height: 6),
                          Text('Última alteração: ${m.history.last}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _openForm(context, elder),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Cadastrar medicamento'),
            ),
          ],
        ),
      ),
    );
  }
}
