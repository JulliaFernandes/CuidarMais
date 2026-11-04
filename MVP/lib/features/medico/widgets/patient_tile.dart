import 'package:flutter/material.dart';
import '../../../data/models/patient.dart';

/// Linha da lista de pacientes do médico. O nível de atenção some com
/// uma faixa colorida, mas também com um rótulo em texto e um ícone
/// (WCAG 1.4.1), e a linha inteira é o alvo de toque (mais fácil pra
/// quem tem pouca destreza do que acertar um botão pequeno).
class PatientTile extends StatelessWidget {
  final PatientSummary patient;
  final VoidCallback onTap;
  const PatientTile({super.key, required this.patient, required this.onTap});

  Color _levelColor(ColorScheme scheme) {
    switch (patient.attentionLevel) {
      case AttentionLevel.critico:
        return scheme.error;
      case AttentionLevel.atencao:
        return const Color(0xFFB45309);
      case AttentionLevel.estavel:
        return const Color(0xFF15803D);
    }
  }

  String _levelLabel() {
    switch (patient.attentionLevel) {
      case AttentionLevel.critico:
        return 'Precisa de atenção agora';
      case AttentionLevel.atencao:
        return 'Atraso recente';
      case AttentionLevel.estavel:
        return 'Em dia';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _levelColor(scheme);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        focusColor: scheme.primary.withValues(alpha: 0.15),
        child: Semantics(
          button: true,
          label:
              '${patient.name}, ${patient.age} anos, ${_levelLabel()}, adesão de ${patient.adherencePercent.round()} por cento',
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 56,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 14),
                CircleAvatar(radius: 24, child: Text(patient.initials)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text('${patient.age} anos · ${patient.conditions}', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: color),
                          const SizedBox(width: 6),
                          Text(_levelLabel(), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${patient.adherencePercent.round()}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text('adesão', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
