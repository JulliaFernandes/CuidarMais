import 'package:flutter/material.dart';

/// Paleta pensada para contraste mínimo 4,5:1 em texto (WCAG 1.4.3) e,
/// quando dá, 7:1 (1.4.6, AAA) — e com tons mais suaves que preto puro
/// sobre branco puro, para reduzir o ofuscamento de quem tem baixa
/// sensibilidade a contraste (comum com a idade).
class AppColors {
  AppColors._();

  static const violet = Color(0xFF3730A3); // médico — ~8.6:1 sobre branco
  static const green = Color(0xFF15803D); // idoso / confirmação — ~5.3:1
  static const coral = Color(0xFFB91C1C); // alerta — ~6.4:1
  static const amber = Color(0xFFB45309); // atenção intermediária — ~5.4:1

  static const background = Color(0xFFFAF8F5); // off-white, reduz ofuscamento
  static const surface = Color(0xFFFFFFFF);

  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);
}
