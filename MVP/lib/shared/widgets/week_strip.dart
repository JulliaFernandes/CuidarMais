import 'package:flutter/material.dart';
import '../../data/models/dose.dart';
import '../utils/format.dart';
import '../../core/theme/app_colors.dart';

/// Últimos 7 dias em círculos. Cada dia tem cor, símbolo e texto para o
/// leitor de tela — a informação nunca depende só da cor (WCAG 1.4.1).
class WeekStrip extends StatelessWidget {
  final List<DoseStatus> days;
  final DateTime today;
  const WeekStrip({super.key, required this.days, required this.today});

  (Color, Color, IconData, String) _visuals(ColorScheme scheme, DoseStatus s) {
    switch (s) {
      case DoseStatus.tomada:
        return (AppColors.confirm, AppColors.onColor, Icons.check_rounded, 'tomou tudo');
      case DoseStatus.atrasada:
      case DoseStatus.adiada:
        return (AppColors.attention, AppColors.onColor, Icons.schedule_rounded, 'tomou com atraso');
      case DoseStatus.perdida:
        return (scheme.error, scheme.onError, Icons.close_rounded, 'esqueceu alguma dose');
      case DoseStatus.pendente:
        return (scheme.surfaceContainerHighest, scheme.onSurfaceVariant, Icons.more_horiz_rounded, 'ainda sem resultado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(days.length, (i) {
        final date = today.subtract(Duration(days: days.length - 1 - i));
        final label = i == days.length - 1 ? 'hoje' : weekdayShort[date.weekday - 1];
        final (bg, fg, icon, text) = _visuals(scheme, days[i]);
        return Expanded(
          child: Semantics(
            label: '$label: $text',
            child: ExcludeSemantics(
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                    child: Icon(icon, size: 20, color: fg),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
