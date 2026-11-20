import 'package:flutter/material.dart';

enum NoticeTone { info, success, warning, danger }

/// Caixa de aviso com ícone + texto (nunca só cor, WCAG 1.4.1). Avisos de
/// perigo são anunciados pelo leitor de tela assim que aparecem.
class NoticeBox extends StatelessWidget {
  final String text;
  final String? title;
  final NoticeTone tone;
  final IconData? icon;
  final List<Widget> actions;

  const NoticeBox({
    super.key,
    required this.text,
    this.title,
    this.tone = NoticeTone.info,
    this.icon,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, defaultIcon) = switch (tone) {
      NoticeTone.info => (scheme.primaryContainer, scheme.onPrimaryContainer, Icons.info_outline_rounded),
      NoticeTone.success => (scheme.tertiaryContainer, scheme.onTertiaryContainer, Icons.check_circle_outline_rounded),
      NoticeTone.warning => (scheme.secondaryContainer, scheme.onSecondaryContainer, Icons.schedule_rounded),
      NoticeTone.danger => (scheme.errorContainer, scheme.onErrorContainer, Icons.warning_amber_rounded),
    };
    return Semantics(
      container: true,
      liveRegion: tone == NoticeTone.danger,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? defaultIcon, color: fg, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(title!, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                  ],
                  Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: fg)),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: actions),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selo pequeno com ícone + texto, mesmas regras do [NoticeBox].
class InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final NoticeTone tone;
  const InfoPill({super.key, required this.label, required this.icon, this.tone = NoticeTone.info});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      NoticeTone.info => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      NoticeTone.success => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      NoticeTone.warning => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      NoticeTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13))),
        ],
      ),
    );
  }
}
