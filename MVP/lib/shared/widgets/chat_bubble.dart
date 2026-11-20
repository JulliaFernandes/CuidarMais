import 'package:flutter/material.dart';

/// Balão do chat de lembretes. O leitor de tela lê quem falou e quando.
class ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool fromMe;
  const ChatBubble({super.key, required this.text, required this.time, this.fromMe = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = fromMe ? scheme.primary : scheme.surface;
    final fg = fromMe ? scheme.onPrimary : scheme.onSurface;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.8;
    return Semantics(
      label: '${fromMe ? 'Você' : 'CuidarMais'}, às $time: $text',
      child: ExcludeSemantics(
        child: Align(
          alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(fromMe ? 18 : 4),
                bottomRight: Radius.circular(fromMe ? 4 : 18),
              ),
              border: fromMe ? null : Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: fg,
                          fontWeight: fromMe ? FontWeight.w700 : FontWeight.w400,
                        ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fg.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso do sistema no meio da conversa (ex.: "A Carla recebeu um alerta").
class ChatSystemNote extends StatelessWidget {
  final String text;
  final bool danger;
  const ChatSystemNote({super.key, required this.text, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = danger ? scheme.errorContainer : scheme.surfaceContainerHighest;
    final fg = danger ? scheme.onErrorContainer : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(danger ? Icons.notifications_active_rounded : Icons.info_outline_rounded, size: 18, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
