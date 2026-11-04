import 'package:flutter/material.dart';
import '../../../data/models/dose.dart';
import '../../../data/models/patient.dart';

const _startHour = 6;
const _endHour = 22;

double _positionFor(DateTime time) {
  final minutes = time.hour * 60 + time.minute;
  const start = _startHour * 60;
  const end = _endHour * 60;
  return ((minutes - start) / (end - start)).clamp(0.0, 1.0);
}

Color _dotColor(BuildContext context, DoseStatus s) {
  final scheme = Theme.of(context).colorScheme;
  switch (s) {
    case DoseStatus.tomada:
      return const Color(0xFF15803D);
    case DoseStatus.atrasada:
    case DoseStatus.adiada:
      return const Color(0xFFB45309);
    case DoseStatus.perdida:
      return scheme.error;
    case DoseStatus.pendente:
      return scheme.outline;
  }
}

/// Régua do dia: uma linha por paciente, de 6h a 22h, com uma bolinha por
/// dose na hora marcada — dá pra ver de relance o dia inteiro de todos os
/// pacientes, como no documento do projeto.
class DayTimeline extends StatelessWidget {
  final List<PatientSummary> patients;
  final ValueChanged<PatientSummary> onTap;
  const DayTimeline({super.key, required this.patients, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                SizedBox(width: 108),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: Text('06h', style: TextStyle(fontSize: 11))),
                      Expanded(child: Text('10h', style: TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                      Expanded(child: Text('14h', style: TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                      Expanded(child: Text('18h', style: TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                      Expanded(child: Text('22h', style: TextStyle(fontSize: 11), textAlign: TextAlign.end)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final patient in patients) _PatientRow(patient: patient, onTap: () => onTap(patient)),
          ],
        ),
      ),
    );
  }
}

class _PatientRow extends StatelessWidget {
  final PatientSummary patient;
  final VoidCallback onTap;
  const _PatientRow({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Semantics(
        button: true,
        label: '${patient.name}: ${patient.todayDoses.length} doses hoje, toque para ver detalhes',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 108,
                child: Text(
                  patient.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 22,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(height: 2, color: Theme.of(context).colorScheme.outlineVariant),
                          for (final dose in patient.todayDoses)
                            Positioned(
                              left: (_positionFor(dose.scheduledAt) * (constraints.maxWidth - 16)).clamp(0.0, constraints.maxWidth - 16),
                              child: Tooltip(
                                message:
                                    '${dose.medicationName} às ${dose.scheduledAt.hour.toString().padLeft(2, '0')}:${dose.scheduledAt.minute.toString().padLeft(2, '0')} — ${dose.status.label}',
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _dotColor(context, dose.status),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
