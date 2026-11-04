import 'package:flutter/material.dart';
import '../../../data/models/dose.dart';
import '../../../shared/widgets/status_chip.dart';

/// Cartão do lembrete atual — equivalente à mensagem do chat no PDF do
/// projeto, mas pensado para o app: texto grande, botões grandes, e a
/// opção de adiar continua disponível em vez de a tela simplesmente
/// travar num cronômetro (WCAG 2.2.1 — o usuário controla o tempo).
class DoseReminderCard extends StatelessWidget {
  final Dose dose;
  final VoidCallback onTake;
  final VoidCallback? onSnooze;

  const DoseReminderCard({
    super.key,
    required this.dose,
    required this.onTake,
    required this.onSnooze,
  });

  String get _timeLabel {
    final h = dose.scheduledAt.hour.toString().padLeft(2, '0');
    final m = dose.scheduledAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final late = dose.status == DoseStatus.atrasada;
    final taken = dose.status == DoseStatus.tomada;

    return Semantics(
      container: true,
      liveRegion: true, // avisa o leitor de tela quando o status muda
      label:
          'Lembrete de remédio, ${dose.medicationName}, às $_timeLabel. Status: ${dose.status.label}.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: late ? scheme.errorContainer : scheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: late ? scheme.error : scheme.primary, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(status: dose.status),
                const Spacer(),
                Text(_timeLabel, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              dose.medicationName,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(dose.dosageText, style: Theme.of(context).textTheme.titleLarge),
            if (late) ...[
              const SizedBox(height: 12),
              Text(
                'A Carla já foi avisada. Toque em "Tomei" assim que puder.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: taken ? null : onTake,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 28),
                label: Text(
                  taken ? 'Já tomado' : 'Tomei',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
              ),
            ),
            if (!taken) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSnooze,
                  icon: const Icon(Icons.snooze_rounded, size: 26),
                  label: Text(
                    onSnooze == null ? 'Já adiei duas vezes' : 'Me lembra em 15 min',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(60)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
