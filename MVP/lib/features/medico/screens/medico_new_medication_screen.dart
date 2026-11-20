import 'package:flutter/material.dart';
import '../../../data/models/medication.dart';
import '../../../data/store/app_scope.dart';
import '../../../shared/screens/medication_form_screen.dart';
import '../../../shared/widgets/notice_box.dart';
import '../../../shared/widgets/section_heading.dart';

/// Aba "Cadastrar" do médico: escolhe o paciente e abre o formulário de
/// remédio (o mesmo de cuidador e idoso, com origem "prescrição validada").
class MedicoNewMedicationScreen extends StatelessWidget {
  const MedicoNewMedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final me = store.currentUser!;
    final patients = store.patientsOfDoctor(me.id);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeading(
          title: 'Cadastrar medicamento',
          subtitle: 'Escolha o paciente. O cadastro vale como prescrição de referência.',
        ),
        const SizedBox(height: 12),
        if (patients.isEmpty) const NoticeBox(text: 'Adicione um paciente primeiro, na aba "Pacientes".'),
        for (final p in patients)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              minVerticalPadding: 14,
              leading: CircleAvatar(child: Text(p.initials)),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${store.medicationsOf(p.id).length} remédios em uso'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MedicationFormScreen(
                  elder: p,
                  origin: MedicationOrigin.medico,
                  authorName: me.name,
                ),
              )),
            ),
          ),
      ],
    );
  }
}
