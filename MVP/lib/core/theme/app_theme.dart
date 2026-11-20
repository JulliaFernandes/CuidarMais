import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// Cada perfil tem sua cor de destaque (idoso na cor da marca, cuidador
  /// vermelho-tijolo, médico violeta), aplicada no app inteiro — inclusive nas telas que
  /// abrem por cima — para a pessoa saber de relance em qual visão está.
  static ThemeData light([Color accent = AppColors.brand]) => _build(Brightness.light, accent);
  static ThemeData dark([Color accent = AppColors.brand]) => _build(Brightness.dark, accent);

  static ThemeData _build(Brightness brightness, Color accent) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: accent,
      onPrimary: AppColors.onColor,
      secondary: AppColors.attention,
      onSecondary: AppColors.onColor,
      tertiary: AppColors.confirm,
      onTertiary: AppColors.onColor,
      error: AppColors.alert,
      onError: AppColors.onColor,
      surface: isDark ? AppColors.surfaceDark : AppColors.surface,
      // No modo claro: texto principal, e "já tomou" no fundo suave da marca.
      onSurface: isDark ? null : AppColors.ink,
      tertiaryContainer: isDark ? null : AppColors.brandSoft,
      onTertiaryContainer: isDark ? null : AppColors.brandDark,
    );
    // Títulos na marca escura (no modo escuro ficam claros, para dar contraste).
    final titleColor = isDark ? null : AppColors.brandDark;
    final bodyColor = isDark ? null : AppColors.ink;
    final selectedColor = isDark ? null : AppColors.brandSoft;

    final baseTextTheme = (isDark ? ThemeData.dark() : ThemeData.light())
        .textTheme
        .apply(bodyColor: bodyColor, displayColor: bodyColor);

    // WCAG 1.4.8: nunca justificar texto, espaçamento de linha generoso
    // (height >= 1.3) e fontes de tamanho grande por padrão, mesmo antes
    // de o usuário tocar no controle de "aumentar texto".
    //
    // Números e títulos grandes usam uma fonte de destaque (Bricolage
    // Grotesque) pra criar contraste visual imediato com o corpo do texto;
    // o corpo continua na fonte padrão do sistema, mais neutra pra leitura
    // longa.
    final textTheme = baseTextTheme.copyWith(
      displaySmall: GoogleFonts.bricolageGrotesque(
        textStyle: baseTextTheme.displaySmall?.copyWith(height: 1.2, fontWeight: FontWeight.w800, color: titleColor),
      ),
      headlineSmall: GoogleFonts.bricolageGrotesque(
        textStyle: baseTextTheme.headlineSmall?.copyWith(height: 1.3, fontWeight: FontWeight.w700, color: titleColor),
      ),
      titleLarge: GoogleFonts.bricolageGrotesque(
        textStyle: baseTextTheme.titleLarge?.copyWith(height: 1.3, fontWeight: FontWeight.w700, color: titleColor),
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(height: 1.35),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 1.5, fontSize: 18),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 1.5, fontSize: 16),
      bodySmall: baseTextTheme.bodySmall?.copyWith(height: 1.4, fontSize: 14),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard, // evita alvos de toque pequenos demais
      focusColor: colorScheme.primary.withValues(alpha: 0.25), // indicador de foco visível (2.4.7)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 56), // alvo de toque grande (destreza/tremor)
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 56)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 56)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // Barra do topo com título e ícones na marca escura.
      appBarTheme: AppBarTheme(foregroundColor: titleColor),
      // Itens selecionados no fundo suave da marca.
      navigationBarTheme: NavigationBarThemeData(height: 72, indicatorColor: selectedColor),
      chipTheme: ChipThemeData(selectedColor: selectedColor),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? selectedColor : null,
          ),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        textStyle: TextStyle(fontSize: 14, color: AppColors.onColor),
      ),
    );
  }
}
