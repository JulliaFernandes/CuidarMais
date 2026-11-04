import 'package:flutter/material.dart';

/// Simulação fiel do WhatsApp — mostra pro avaliador exatamente a tela
/// que o idoso vê, já que hoje o lembrete sai por lá (ver README do
/// repositório sobre o pivô de canal). Paleta fixa do WhatsApp, propositalmente
/// fora do tema do app, pra parecer o aplicativo de verdade.
class IdosoWhatsAppScreen extends StatefulWidget {
  const IdosoWhatsAppScreen({super.key});

  @override
  State<IdosoWhatsAppScreen> createState() => _IdosoWhatsAppScreenState();
}

class _ChatMessage {
  final bool fromUser;
  final String text;
  final String time;
  const _ChatMessage({required this.fromUser, required this.text, required this.time});
}

class _IdosoWhatsAppScreenState extends State<IdosoWhatsAppScreen> {
  static const _whatsBg = Color(0xFFECE5DD);
  static const _whatsHeader = Color(0xFF075E54);
  static const _bubbleIn = Colors.white;
  static const _bubbleOut = Color(0xFFDCF8C6);
  static const _checkBlue = Color(0xFF34B7F1);

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      fromUser: false,
      text: 'Bom dia, Dona Maria! ☀️ Hora da Levotiroxina 50 mcg, 1 comprimido em jejum.',
      time: '07:00',
    ),
    const _ChatMessage(fromUser: true, text: '✅ Tomei', time: '07:03'),
    const _ChatMessage(
      fromUser: false,
      text: 'Anotado! Próximo: Losartana às 08:00. 💙',
      time: '07:03',
    ),
    const _ChatMessage(
      fromUser: false,
      text: 'Dona Maria, está na hora do seu remédio:\nLosartana 50 mg · 1 comprimido\nToque em uma opção abaixo.',
      time: '08:00',
    ),
  ];

  bool _awaitingReply = true;
  int _snoozeCount = 0;

  void _tapTomei() {
    setState(() {
      _messages.add(const _ChatMessage(fromUser: true, text: '✅ Tomei', time: '08:04'));
      _messages.add(const _ChatMessage(
        fromUser: false,
        text: 'Perfeito, Dona Maria! Registrado. Próximo: Metformina 850 mg às 12:30. 🌷',
        time: '08:04',
      ));
      _awaitingReply = false;
    });
  }

  void _tapSnooze() {
    setState(() {
      _snoozeCount += 1;
      final novoHorario = _snoozeCount == 1 ? '08:17' : '08:32';
      _messages.add(_ChatMessage(fromUser: true, text: '⏰ Me lembra em 15 min', time: _snoozeCount == 1 ? '08:02' : '08:17'));
      _messages.add(_ChatMessage(
        fromUser: false,
        text: 'Combinado! Te chamo de novo às $novoHorario.',
        time: _snoozeCount == 1 ? '08:02' : '08:17',
      ));
      if (_snoozeCount >= 2) {
        _messages.add(const _ChatMessage(
          fromUser: false,
          text: 'Ainda não recebemos sua confirmação da Losartana. Avisamos a Carla para dar uma ligadinha. 💛',
          time: '08:30',
        ));
      } else {
        _messages.add(_ChatMessage(
          fromUser: false,
          text: 'Dona Maria, passando de novo: Losartana 50 mg. Já tomou?',
          time: novoHorario,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Container(
            color: _whatsBg,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final m in _messages) _Bubble(message: m, outBg: _bubbleOut, inBg: _bubbleIn, checkColor: _checkBlue),
                if (_awaitingReply) _QuickReplies(canSnooze: _snoozeCount < 2, onTake: _tapTomei, onSnooze: _snoozeCount < 2 ? _tapSnooze : null),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _whatsHeader,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Semantics(
        header: true,
        label: 'Conversa do WhatsApp com Cuidar+ Lembretes',
        child: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text('C+', style: TextStyle(color: _whatsHeader, fontWeight: FontWeight.w800)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cuidar+ Lembretes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  Text('conta comercial verificada · simulação', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.videocam_outlined, color: Colors.white70),
            SizedBox(width: 16),
            Icon(Icons.call_outlined, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _ChatMessage message;
  final Color outBg;
  final Color inBg;
  final Color checkColor;
  const _Bubble({required this.message, required this.outBg, required this.inBg, required this.checkColor});

  @override
  Widget build(BuildContext context) {
    final align = message.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = message.fromUser ? outBg : inBg;
    return Semantics(
      label: '${message.fromUser ? "Você" : "Cuidar+"} às ${message.time}: ${message.text}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: align,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 1, offset: Offset(0, 1))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message.text, style: const TextStyle(fontSize: 15, color: Color(0xFF1B1B1B), height: 1.3)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(message.time, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A))),
                        if (message.fromUser) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.done_all_rounded, size: 15, color: checkColor),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  final bool canSnooze;
  final VoidCallback onTake;
  final VoidCallback? onSnooze;
  const _QuickReplies({required this.canSnooze, required this.onTake, required this.onSnooze});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 1, offset: Offset(0, 1))],
          ),
          child: Column(
            children: [
              _QuickReplyRow(label: '✅ Tomei', onTap: onTake),
              const Divider(height: 1),
              _QuickReplyRow(
                label: canSnooze ? '⏰ Me lembra em 15 min' : '⏰ Já adiei duas vezes',
                onTap: onSnooze,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickReplyRow extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _QuickReplyRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: onTap == null ? const Color(0xFF9E9E9E) : const Color(0xFF128C7E),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
