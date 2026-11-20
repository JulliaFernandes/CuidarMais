import 'package:flutter/material.dart';
import '../../../data/models/care_alert.dart';
import '../../../data/models/people.dart';
import '../../../shared/utils/format.dart';

/// Alerta ao cuidador: diz quem, qual remédio e por quê (documento v2).
/// É anunciado pelo leitor de tela assim que aparece.
class AlertBanner extends StatelessWidget {
  final CareAlert alert;
  final Elder elder;
  final VoidCallback? onOpen;

  const AlertBanner({super.key, required this.alert, required this.elder, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final what = alert.reason == AlertReason.adiouDuasVezes
        ? '${elder.nickname} adiou 2 vezes o lembrete da ${alert.medicationName}'
        : '${elder.nickname} não respondeu ao lembrete da ${alert.medicationName}';
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.error, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: scheme.onErrorContainer, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Alerta às ${hhmm(alert.createdAt)}',
                    style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              what,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 4),
            Text(
              'Era para as ${hhmm(alert.doseTime)}. Que tal ligar para ${elder.nickname}?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => showPhoneDialog(context, elder),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Ver telefone'),
                ),
                if (onOpen != null)
                  FilledButton.icon(
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: Text('Abrir ${elder.nickname}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mostra o telefone em texto selecionável (o protótipo não faz ligação).
Future<void> showPhoneDialog(BuildContext context, Elder elder) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Telefone de ${elder.nickname}'),
      content: SelectableText(
        elder.phone.isEmpty ? 'Nenhum telefone cadastrado.' : elder.phone,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    ),
  );
}
