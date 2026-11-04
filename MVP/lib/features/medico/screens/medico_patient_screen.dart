import 'package:flutter/material.dart';
import '../../../data/models/patient.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../../shared/widgets/status_chip.dart';
import '../widgets/adherence_heatmap.dart';
import '../widgets/adherence_ring.dart';

/// Relatório do paciente: anel de adesão, heatmap de 14 dias por período
/// e doses de hoje. Título da página já diz quem é o paciente (WCAG 2.4.2).
class MedicoPatientScreen extends StatelessWidget {
  final PatientSummary patient;
  const MedicoPatientScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(patient.name)),
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
                      Text('${patient.age} anos', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(patient.conditions, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Chip(
                        avatar: const Icon(Icons.people_alt_outlined, size: 18),
                        label: Text('Cuidador: ${patient.caregiverName}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (patient.openAlert != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.onErrorContainer, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        patient.openAlert!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
            ...patient.todayDoses.map(
              (d) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(d.medicationName),
                  subtitle: Text(
                    '${d.dosageText} · às ${d.scheduledAt.hour.toString().padLeft(2, '0')}:${d.scheduledAt.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: StatusChip(status: d.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
