import 'package:flutter/material.dart';
import '../../core/accessibility/text_scale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../features/idoso/idoso_theme_scope.dart';
import '../../features/idoso/screens/idoso_home_screen.dart';
import '../../features/medico/screens/medico_overview_screen.dart';
import 'font_size_toggle.dart';

enum AppRole { idoso, medico }

/// Casca do app: duas abas fixas — idoso (futuro app) e médico (painel
/// com resultados) — com o controle de texto sempre visível no topo.
///
/// Optamos por dois botões grandes em vez de uma TabBar deslizante:
/// gestos de arrastar (swipe) são mais difíceis para quem tem tremor ou
/// pouca destreza, então preferimos um alvo de toque único e explícito.
class RoleShell extends StatefulWidget {
  final TextScaleController textScaleController;
  const RoleShell({super.key, required this.textScaleController});

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  AppRole _role = AppRole.idoso;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: const Text('Cuidar+')),
        actions: [
          FontSizeToggle(controller: widget.textScaleController),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _RoleSwitcher(role: _role, onChanged: (r) => setState(() => _role = r)),
          const Divider(height: 1),
          Expanded(
            // A troca só acontece por ação explícita do usuário (clique),
            // nunca sozinha — WCAG 3.2.1/3.2.5 (sem mudança de contexto
            // automática ou por só receber foco).
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _role == AppRole.idoso
                  ? const IdosoThemeScope(key: ValueKey('idoso'), child: IdosoHomeScreen())
                  : const MedicoOverviewScreen(key: ValueKey('medico')),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSwitcher extends StatelessWidget {
  final AppRole role;
  final ValueChanged<AppRole> onChanged;
  const _RoleSwitcher({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Semantics(
        container: true,
        label: 'Alternar entre a visão do idoso e o painel do médico',
        child: Row(
          children: [
            Expanded(
              child: _RoleButton(
                label: 'Idoso',
                subtitle: 'protótipo do futuro app',
                icon: Icons.favorite_rounded,
                accentColor: AppColors.green,
                selected: role == AppRole.idoso,
                onTap: () => onChanged(AppRole.idoso),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleButton(
                label: 'Médico',
                subtitle: 'painel com os resultados',
                icon: Icons.insights_rounded,
                accentColor: AppColors.violet,
                selected: role == AppRole.medico,
                onTap: () => onChanged(AppRole.medico),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $subtitle',
      child: Material(
        color: selected ? accentColor : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          focusColor: accentColor.withValues(alpha: 0.25), // indicador de foco (2.4.7)
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Icon(icon, size: 28, color: selected ? Colors.white : scheme.onSurfaceVariant),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected ? Colors.white : scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected ? Colors.white.withValues(alpha: 0.9) : scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
