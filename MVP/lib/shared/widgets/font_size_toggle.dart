import 'package:flutter/material.dart';
import '../../core/accessibility/text_scale_controller.dart';

/// Controle de tamanho de texto sempre visível no topo das duas abas
/// (WCAG 1.4.4, técnica G178). O percentual também aparece em texto,
/// não só no ícone, para quem não usa leitor de tela.
class FontSizeToggle extends StatelessWidget {
  final TextScaleController controller;
  const FontSizeToggle({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Semantics(
          container: true,
          label: 'Tamanho do texto, ${(controller.scale * 100).round()} por cento',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleButton(
                icon: Icons.text_decrease_rounded,
                tooltip: 'Diminuir o texto',
                onPressed: controller.canDecrease ? controller.decrease : null,
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${(controller.scale * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              _ToggleButton(
                icon: Icons.text_increase_rounded,
                tooltip: 'Aumentar o texto',
                onPressed: controller.canIncrease ? controller.increase : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _ToggleButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        iconSize: 24,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48), // alvo mínimo de toque
      ),
    );
  }
}
