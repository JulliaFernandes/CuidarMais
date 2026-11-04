import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../data/models/dose.dart';

/// Anel de adesão (donut) com a proporção real de tomada/atrasada ou
/// adiada/perdida nos últimos 14 dias — não só um número solto. O
/// percentual central é texto, as fatias são reforço visual (WCAG 1.4.1).
class AdherenceRing extends StatelessWidget {
  final Map<DoseStatus, int> breakdown;
  final double percent;
  const AdherenceRing({super.key, required this.breakdown, required this.percent});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tomada = breakdown[DoseStatus.tomada] ?? 0;
    final atrasoOuAdiada = (breakdown[DoseStatus.atrasada] ?? 0) + (breakdown[DoseStatus.adiada] ?? 0);
    final perdida = breakdown[DoseStatus.perdida] ?? 0;
    final total = tomada + atrasoOuAdiada + perdida;

    final sections = total == 0
        ? [
            PieChartSectionData(value: 1, color: scheme.surfaceContainerHighest, showTitle: false, radius: 14),
          ]
        : [
            if (tomada > 0)
              PieChartSectionData(value: tomada.toDouble(), color: const Color(0xFF15803D), showTitle: false, radius: 14),
            if (atrasoOuAdiada > 0)
              PieChartSectionData(value: atrasoOuAdiada.toDouble(), color: const Color(0xFFB45309), showTitle: false, radius: 14),
            if (perdida > 0)
              PieChartSectionData(value: perdida.toDouble(), color: scheme.error, showTitle: false, radius: 14),
          ];

    return Semantics(
      label: 'Adesão ao tratamento nos últimos 14 dias: ${percent.round()} por cento. '
          '$tomada doses tomadas, $atrasoOuAdiada atrasadas ou adiadas, $perdida perdidas.',
      value: '${percent.round()}%',
      child: SizedBox(
        width: 128,
        height: 128,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 42,
                sectionsSpace: 2,
                startDegreeOffset: -90,
              ),
              duration: const Duration(milliseconds: 400),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${percent.round()}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text('adesão', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
