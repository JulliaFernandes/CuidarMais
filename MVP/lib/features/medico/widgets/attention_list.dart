import 'package:flutter/material.dart';
import '../../../data/models/patient.dart';

/// Lista "Precisam de atenção" — o painel por exceção descrito no
/// documento do projeto (vermelho primeiro, depois amarelo).
class AttentionList extends StatelessWidget {
  final List<PatientSummary> patients;
  final ValueChanged<PatientSummary> onTap;
  const AttentionList({super.key, required this.patients, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: patients.map((p) {
        final critico = p.attentionLevel == AttentionLevel.critico;
        return Card(
          color: critico ? scheme.errorContainer : scheme.secondaryContainer,
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => onTap(p),
            borderRadius: BorderRadius.circular(12),
            child: Semantics(
              button: true,
              label: '${p.name}: ${p.openAlert ?? "atraso recente em uma dose"}',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      critico ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                      color: critico ? scheme.onErrorContainer : scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.openAlert ?? 'Atraso recente em uma dose',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
