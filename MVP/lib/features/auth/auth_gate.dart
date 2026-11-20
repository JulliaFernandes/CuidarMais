import 'package:flutter/material.dart';
import '../../data/models/people.dart';
import '../../data/store/app_scope.dart';
import '../cuidador/screens/cuidador_home_screen.dart';
import '../idoso/screens/idoso_home_screen.dart';
import '../medico/screens/medico_overview_screen.dart';
import 'welcome_screen.dart';

/// Decide a primeira tela: boas-vindas para quem não entrou, e a área de
/// cada perfil para quem entrou. A troca só acontece por ação da pessoa
/// (entrar ou sair), nunca sozinha (WCAG 3.2.1/3.2.5).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).currentUser;
    final Widget child = switch (user?.role) {
      null => const WelcomeScreen(),
      UserRole.idoso => const IdosoHomeScreen(),
      UserRole.cuidador => const CuidadorHomeScreen(),
      UserRole.medico => const MedicoOverviewScreen(),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(key: ValueKey(user?.id ?? 'sem-login'), child: child),
    );
  }
}
