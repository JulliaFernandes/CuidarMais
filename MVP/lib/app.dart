import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/accessibility/text_scale_controller.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/models/people.dart';
import 'data/remote/local_alarms.dart';
import 'data/store/app_scope.dart';
import 'data/store/app_store.dart';
import 'features/auth/auth_gate.dart';

class CuidarMaisApp extends StatefulWidget {
  /// Liga as contas reais ao Firebase. Nos testes fica desligado e só as
  /// contas de demonstração funcionam.
  final bool useFirebase;

  const CuidarMaisApp({super.key, this.useFirebase = false});

  @override
  State<CuidarMaisApp> createState() => _CuidarMaisAppState();
}

class _CuidarMaisAppState extends State<CuidarMaisApp> {
  final TextScaleController _textScaleController = TextScaleController();
  late final AppStore _store = AppStore(useFirebase: widget.useFirebase);
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Notificação que chega com o app aberto aparece no rodapé da tela.
    _store.onNotification = (title, body) {
      _messengerKey.currentState?.showSnackBar(SnackBar(
        duration: const Duration(seconds: 10),
        content: Text(body.isEmpty ? title : '$title\n$body'),
      ));
    };
    // No navegador, o alarme da página aberta também aparece no rodapé.
    LocalAlarms.onRing = _store.onNotification;
  }

  @override
  void dispose() {
    _textScaleController.dispose();
    _store.dispose();
    super.dispose();
  }

  Color get _accent {
    switch (_store.currentUser?.role) {
      case UserRole.idoso:
        return AppColors.elder;
      case UserRole.cuidador:
        return AppColors.caregiver;
      case UserRole.medico:
        return AppColors.doctor;
      case null:
        return AppColors.brand; // telas de entrada na cor da marca
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
              title: 'CuidarMais',
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: _messengerKey,
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
