import 'package:flutter/material.dart';
import '../../data/models/dose.dart';

/// Status sempre com ícone + texto, nunca só cor (WCAG 1.4.1 / técnica G14).
class StatusChip extends StatelessWidget {
  final DoseStatus status;
  const StatusChip({super.key, required this.status});

  (Color, Color, IconData) _visuals(ColorScheme scheme) {
    switch (status) {
      case DoseStatus.tomada:
        return (scheme.tertiaryContainer, scheme.onTertiaryContainer, Icons.check_circle_rounded);
      case DoseStatus.pendente:
        return (scheme.surfaceContainerHighest, scheme.onSurfaceVariant, Icons.schedule_rounded);
      case DoseStatus.adiada:
        return (scheme.secondaryContainer, scheme.onSecondaryContainer, Icons.snooze_rounded);
      case DoseStatus.atrasada:
        return (scheme.errorContainer, scheme.onErrorContainer, Icons.warning_amber_rounded);
      case DoseStatus.perdida:
        return (scheme.error, scheme.onError, Icons.error_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, icon) = _visuals(scheme);
    return Semantics(
      label: 'Status: ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(status.label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
