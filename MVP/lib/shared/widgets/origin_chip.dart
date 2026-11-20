import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/medication.dart';
import '../../data/models/people.dart';

/// Mostra quem cadastrou o remédio. Para o idoso, em linguagem pessoal
/// ("Prescrito pela Dra. Helena", "Cadastrado por você"); para cuidador e
/// médico, no termo do documento ("Prescrição validada" etc.).
class OriginChip extends StatelessWidget {
  final Medication medication;
  final UserRole viewer;
  const OriginChip({super.key, required this.medication, required this.viewer});

  @override
  Widget build(BuildContext context) {
    final m = medication;
    final personal = viewer == UserRole.idoso;
    final (label, icon, base) = switch (m.origin) {
      MedicationOrigin.medico => (
          personal ? 'Prescrito por ${m.createdByName}' : 'Prescrição validada',
          Icons.verified_rounded,
          AppColors.violet,
        ),
      MedicationOrigin.familia => (
          personal ? 'Cadastrado por ${m.createdByName}' : 'Cadastrado pela família · ${m.createdByName}',
          Icons.family_restroom_rounded,
          AppColors.caregiver,
        ),
      MedicationOrigin.paciente => (
          personal ? 'Cadastrado por você' : 'Cadastrado pelo paciente',
          Icons.person_rounded,
          AppColors.green,
        ),
    };
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : base;
    return Semantics(
      label: 'Origem: $label',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: base.withValues(alpha: dark ? 0.35 : 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13))),
            ],
          ),
        ),
      ),
    );
  }
}
