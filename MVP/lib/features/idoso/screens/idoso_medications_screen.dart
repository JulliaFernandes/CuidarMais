import 'package:flutter/material.dart';
import '../../../data/models/medication.dart';
import '../../../data/models/people.dart';
import '../../../data/store/app_scope.dart';
import '../../../shared/screens/medication_form_screen.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/notice_box.dart';
import '../../../shared/widgets/origin_chip.dart';
import '../../../shared/widgets/section_heading.dart';

/// Todos os remédios em uso, com quem cadastrou cada um. O idoso também
/// pode cadastrar (documento do projeto v2).
class IdosoMedicationsScreen extends StatelessWidget {
  final Elder elder;
  const IdosoMedicationsScreen({super.key, required this.elder});

  void _openForm(BuildContext context, {Medication? initial}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MedicationFormScreen(
        elder: elder,
        origin: MedicationOrigin.paciente,
        authorName: elder.nickname,
        showAlertDelay: false,
        initial: initial,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final meds = AppScope.of(context).medicationsOf(elder.id);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeading(title: 'Meus remédios', subtitle: 'Toque em um remédio para mudar o horário ou a dose.'),
        const SizedBox(height: 12),
        if (meds.isEmpty) const NoticeBox(text: 'Você ainda não tem remédios cadastrados.'),
        for (final m in meds)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openForm(context, initial: m),
              child: Semantics(
                button: true,
                hint: 'Toque para editar',
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('${m.dosage} · ${timesLabel(m.times)}', style: Theme.of(context).textTheme.bodyLarge),
                      Text(daysLabel(m.weekdays), style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 10),
                      OriginChip(medication: m, viewer: UserRole.idoso),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Cadastrar remédio'),
        ),
      ],
    );
  }
}
