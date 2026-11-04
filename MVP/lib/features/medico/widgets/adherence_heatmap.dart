import 'package:flutter/material.dart';
import '../../../data/models/dose.dart';
import '../../../data/models/patient.dart';

/// Heatmap de 14 dias × manhã/tarde/noite — mostra se o paciente esquece
/// sempre no mesmo período, o mesmo diferencial descrito no documento do
/// projeto ("detectar padrão de esquecimento, como o remédio da tarde").
class AdherenceHeatmap extends StatelessWidget {
  final PatientSummary patient;
  const AdherenceHeatmap({super.key, required this.patient});

  Color _color(BuildContext context, DoseStatus s) {
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
        return scheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = patient.last14DaysByPeriod;
    final worst = patient.worstPeriodPattern;

    return Semantics(
      container: true,
      label: 'Mapa de adesão dos últimos 14 dias, por manhã, tarde e noite',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Row(
                  children: List.generate(days.length, (i) {
                    final diasAtras = days.length - 1 - i;
                    return Expanded(
                      child: Text(
                        diasAtras == 0 ? 'hoje' : '-$diasAtras',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final period in DosePeriod.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(width: 48, child: Text(period.label, style: Theme.of(context).textTheme.bodySmall)),
                  Expanded(
                    child: Row(
                      children: List.generate(days.length, (i) {
                        final status = days[i][period.index];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Tooltip(
                                message: '${period.label}, ${status.label}',
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _color(context, status),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          _Legend(colorOf: (s) => _color(context, s)),
          if (worst != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights_rounded, color: Theme.of(context).colorScheme.onSecondaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Padrão identificado: costuma esquecer o remédio da ${worst.label.toLowerCase()}.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color Function(DoseStatus) colorOf;
  const _Legend({required this.colorOf});

  @override
  Widget build(BuildContext context) {
    final items = [DoseStatus.tomada, DoseStatus.atrasada, DoseStatus.perdida, DoseStatus.pendente];
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: items.map((s) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: colorOf(s), borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(s.label, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}
