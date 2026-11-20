import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/accessibility/text_scale_controller.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/models/people.dart';
import 'data/store/app_scope.dart';
import 'data/store/app_store.dart';
import 'features/auth/auth_gate.dart';

class CuidarMaisApp extends StatefulWidget {
  const CuidarMaisApp({super.key});

  @override
  State<CuidarMaisApp> createState() => _CuidarMaisAppState();
}

class _CuidarMaisAppState extends State<CuidarMaisApp> {
  final TextScaleController _textScaleController = TextScaleController();
  final AppStore _store = AppStore();

  @override
  void dispose() {
    _textScaleController.dispose();
    _store.dispose();
    super.dispose();
  }

  Color get _accent {
    switch (_store.currentUser?.role) {
      case UserRole.idoso:
        return AppColors.green;
      case UserRole.cuidador:
        return AppColors.caregiver;
      case UserRole.medico:
      case null:
        return AppColors.violet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: _store,
      child: TextScaleScope(
        controller: _textScaleController,
        child: AnimatedBuilder(
          animation: Listenable.merge([_textScaleController, _store]),
          builder: (context, _) {
            return MaterialApp(
              title: 'Cuidar+',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(_accent),
              darkTheme: AppTheme.dark(_accent),
              themeMode: ThemeMode.system,
              // Calendário, relógio e botões do sistema em português.
              locale: const Locale('pt', 'BR'),
              supportedLocales: const [Locale('pt', 'BR')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(_textScaleController.scale),
                  ),
                  child: child!,
                );
              },
              home: const AuthGate(),
            );
          },
        ),
      ),
    );
  }
}
