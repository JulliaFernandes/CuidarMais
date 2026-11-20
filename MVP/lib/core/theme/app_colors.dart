import 'package:flutter/material.dart';

/// Todas as cores do app, alinhadas à identidade visual do CuidarMais.
/// Nenhuma tela usa código de cor direto: tudo passa por aqui ou pelo
/// tema (`app_theme.dart`).
///
/// Contraste (WCAG 1.4.3, mínimo 4,5:1 para texto) medido com texto branco
/// e sobre o fundo #FFF8EF. Texto branco só pode ir sobre as cores marcadas
/// com "branco ok".
class AppColors {
  AppColors._();

  // Marca
  static const brand = Color(0xFF0E6B66); // cor principal — branco 6,3:1 (branco ok)
  static const brandDark = Color(0xFF0B4F4B); // títulos, cabeçalho e barra do topo — branco 9,4:1 (branco ok)
  static const brandSoft = Color(0xFFE6F2F1); // fundo de itens selecionados e de "já tomou"

  /// Coral da logo: só em logo e ilustrações grandes. Nunca em texto
  /// pequeno nem com texto branco pequeno por cima (branco 3,7:1).
  static const logoCoral = Color(0xFFE4533F);

  // Perfis (sempre com ícone e texto junto da cor — WCAG 1.4.1)
  static const elder = brand; // idoso
  static const caregiver = Color(0xFFC23B28); // cuidador — branco 5,3:1 (branco ok)
  static const doctor = Color(0xFF3730A3); // médico — branco 9,9:1 (branco ok)

  // Estados (sempre com ícone e texto junto da cor — WCAG 1.4.1)
  static const confirm = brand; // "Tomei", dose tomada
  static const attention = Color(0xFFB45309); // "Atraso recente" — branco 5,0:1 (branco ok)
  static const alert = Color(0xFFB91C1C); // alerta — branco 6,5:1 (branco ok)

  // Texto e fundos
  static const ink = Color(0xFF1C2B29); // texto principal — 14:1 sobre o fundo
  static const onColor = Color(0xFFFFFFFF); // texto e ícone sobre as cores "branco ok"
  static const background = Color(0xFFFFF8EF); // fundo das telas
  static const surface = Color(0xFFFFFFFF); // cartões

  // Modo escuro
  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);
}
