import 'package:flutter/material.dart';
import '../../../data/models/dose.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../../shared/widgets/status_chip.dart';

/// Lista dos medicamentos do dia, em letras grandes (como pedido no
/// documento do projeto). Tela só de leitura, sem ações.
class IdosoMedicationsScreen extends StatelessWidget {
  final List<Dose> doses;
  const IdosoMedicationsScreen({super.key, required this.doses});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeading(
          title: 'Meus remédios de hoje',
          subtitle: 'Cada cartão mostra o horário, o remédio e se já foi tomado.',
        ),
        const SizedBox(height: 12),
        ...doses.map(
          (d) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              minVerticalPadding: 16,
              leading: CircleAvatar(
                radius: 28,
                child: Text(
                  '${d.scheduledAt.hour.toString().padLeft(2, '0')}h',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(d.medicationName, style: Theme.of(context).textTheme.titleLarge),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(d.dosageText, style: Theme.of(context).textTheme.bodyLarge),
              ),
              trailing: StatusChip(status: d.status),
            ),
          ),
        ),
      ],
    );
  }
}
