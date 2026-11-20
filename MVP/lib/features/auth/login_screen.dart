import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/mock_data.dart';
import '../../data/store/app_scope.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/notice_box.dart';
import '../../shared/widgets/section_heading.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final error = AppScope.read(context).login(_emailController.text, _passwordController.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    // Volta para a raiz, onde o AuthGate já mostra a área do perfil.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _useDemo(String email) {
    _emailController.text = email;
    _passwordController.text = MockData.demoPassword;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: subPageBar(context, 'Entrar'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeading(title: 'Que bom ver você', subtitle: 'Entre com o email e a senha da sua conta.'),
                      const SizedBox(height: 16),
                      if (_error != null) ...[
                        NoticeBox(text: _error!, tone: NoticeTone.danger),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Ex.: maria@email.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Digite um email válido, como maria@email.com.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _showPassword ? 'Esconder a senha' : 'Mostrar a senha',
                            icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Digite sua senha.' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
                        child: const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushReplacement(MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: const Text('Ainda não tem conta? Criar conta'),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const SectionHeading(
                        title: 'Contas de demonstração',
                        subtitle: 'Só no protótipo: entre direto com um dos perfis.',
                      ),
                      const SizedBox(height: 8),
                      _DemoButton(
                        icon: Icons.favorite_rounded,
                        color: AppColors.elder,
                        title: 'Dona Maria',
                        subtitle: 'Idosa · usa o app',
                        onTap: () => _useDemo('maria@cuidar.app'),
                      ),
                      _DemoButton(
                        icon: Icons.volunteer_activism_rounded,
                        color: AppColors.caregiver,
                        title: 'Carla',
                        subtitle: 'Cuidadora da Dona Maria e do Seu Antônio (sem app)',
                        onTap: () => _useDemo('carla@cuidar.app'),
                      ),
                      _DemoButton(
                        icon: Icons.medical_services_rounded,
                        color: AppColors.doctor,
                        title: 'Dra. Helena',
                        subtitle: 'Médica · painel de pacientes',
                        onTap: () => _useDemo('helena@cuidar.app'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DemoButton({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        minVerticalPadding: 14,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: dark ? 0.35 : 0.12),
          child: Icon(icon, color: dark ? AppColors.onColor : color),
        ),
        title: Text('Entrar como $title', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
