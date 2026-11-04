import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: brightness,
      primary: AppColors.violet,
      secondary: AppColors.amber,
      tertiary: AppColors.green,
      error: AppColors.coral,
      surface: isDark ? AppColors.surfaceDark : AppColors.surface,
    );

    final baseTextTheme = (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;

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
        textStyle: baseTextTheme.displaySmall?.copyWith(height: 1.2, fontWeight: FontWeight.w800),
      ),
      headlineSmall: GoogleFonts.bricolageGrotesque(
        textStyle: baseTextTheme.headlineSmall?.copyWith(height: 1.3, fontWeight: FontWeight.w700),
      ),
      titleLarge: GoogleFonts.bricolageGrotesque(
        textStyle: baseTextTheme.titleLarge?.copyWith(height: 1.3, fontWeight: FontWeight.w700),
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
      navigationBarTheme: const NavigationBarThemeData(height: 72),
      tooltipTheme: const TooltipThemeData(
        textStyle: TextStyle(fontSize: 14, color: Colors.white),
      ),
    );
  }
}
