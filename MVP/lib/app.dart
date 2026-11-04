import 'package:flutter/material.dart';
import 'core/accessibility/text_scale_controller.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/role_shell.dart';

class CuidarMaisApp extends StatefulWidget {
  const CuidarMaisApp({super.key});

  @override
  State<CuidarMaisApp> createState() => _CuidarMaisAppState();
}

class _CuidarMaisAppState extends State<CuidarMaisApp> {
  final TextScaleController _textScaleController = TextScaleController();

  @override
  void dispose() {
    _textScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _textScaleController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Cuidar+',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(_textScaleController.scale),
              ),
              child: child!,
            );
          },
          home: RoleShell(textScaleController: _textScaleController),
        );
      },
    );
  }
}
