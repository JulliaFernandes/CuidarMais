import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/store/app_scope.dart';
import '../../shared/widgets/cuidar_logo.dart';
import '../../shared/widgets/font_size_toggle.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Primeira tela do app. Duas ações grandes e claras (entrar ou criar
/// conta) e o controle de texto já disponível antes do login.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: FontSizeToggle(controller: TextScaleScope.of(context)),
                  ),
                  const SizedBox(height: 12),
                  const Center(child: CuidarLogo(size: 88)),
                  const SizedBox(height: 20),
                  Semantics(
                    header: true,
                    child: Text('CuidarMais', textAlign: TextAlign.center, style: textTheme.displaySmall),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cada remédio no horário certo, e a família por perto quando não for.',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                    icon: const Icon(Icons.login_rounded, size: 26),
                    label: const Text('Entrar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen())),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 26),
                    label: const Text('Criar conta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(60)),
                  ),
                  const SizedBox(height: 32),
                  const _ProfileLine(
                    icon: Icons.favorite_rounded,
                    color: AppColors.elder,
                    title: 'Idoso',
                    text: 'Recebe o lembrete no celular e confirma com um toque.',
                  ),
                  const _ProfileLine(
                    icon: Icons.volunteer_activism_rounded,
                    color: AppColors.caregiver,
                    title: 'Cuidador',
                    text: 'Acompanha o dia e é avisado quando um remédio não é confirmado.',
                  ),
                  const _ProfileLine(
                    icon: Icons.medical_services_rounded,
                    color: AppColors.doctor,
                    title: 'Médico',
                    text: 'Vê a adesão dos pacientes no painel, sem receber notificações.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  const _ProfileLine({required this.icon, required this.color, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: dark ? 0.35 : 0.12),
            child: Icon(icon, color: dark ? AppColors.onColor : color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(text, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
