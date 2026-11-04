import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reforça a identidade visual do idoso (verde) só dentro desta aba —
/// o médico continua violeta, sem mexer em cores de status (erro, âmbar
/// etc.), que precisam ficar iguais no app inteiro.
class IdosoThemeScope extends StatelessWidget {
  final Widget child;
  const IdosoThemeScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scheme = base.colorScheme.copyWith(
      primary: AppColors.green,
      onPrimary: Colors.white,
      primaryContainer: base.brightness == Brightness.dark
          ? const Color(0xFF17432A)
          : const Color(0xFFDCF3E3),
      onPrimaryContainer: base.brightness == Brightness.dark ? const Color(0xFFBFE8CD) : const Color(0xFF0B3B1E),
    );
    return Theme(data: base.copyWith(colorScheme: scheme), child: child);
  }
}
