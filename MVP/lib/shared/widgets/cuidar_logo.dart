import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Marca do Cuidar+: as cores dos três perfis girando em volta do "C+".
/// É decorativa — o nome do app sempre aparece em texto ao lado.
class CuidarLogo extends StatelessWidget {
  final double size;
  const CuidarLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.3),
          gradient: const SweepGradient(
            colors: [AppColors.violet, AppColors.caregiver, AppColors.amber, AppColors.green, AppColors.violet],
          ),
        ),
        child: Container(
          width: size * 0.68,
          height: size * 0.68,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(size * 0.22)),
          child: Text(
            'C+',
            textScaler: TextScaler.noScaling,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  height: 1,
                ),
          ),
        ),
      ),
    );
  }
}
