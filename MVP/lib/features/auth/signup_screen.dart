import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/people.dart';
import '../../data/store/app_scope.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/notice_box.dart';
import '../../shared/widgets/section_heading.dart';

/// Cadastro em 3 passos curtos (perfil, dados, consentimento), um de cada
/// vez, para não sobrecarregar (WAI, usuários mais velhos). O passo atual
/// aparece em texto e na barra de progresso.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _step = 0;
  UserRole? _role;
  bool _consent = false;
  bool _showPassword = false;
  bool _busy = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  static const _titles = ['Quem vai usar?', 'Seus dados', 'Seus dados de saúde'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_busy) return;
    setState(() => _error = null);
    if (_step == 0) {
      if (_role == null) {
        setState(() => _error = 'Escolha uma das opções para continuar.');
        return;
      }
    } else if (_step == 1) {
      if (!_formKey.currentState!.validate()) return;
      if (AppScope.read(context).emailInUse(_emailController.text)) {
        setState(() => _error = 'Já existe uma conta com esse email. Volte e toque em "Entrar".');
        return;
      }
    } else {
      if (!_consent) {
        setState(() => _error = 'Para criar a conta, marque que você concorda com o uso dos dados.');
        return;
      }
      setState(() => _busy = true);
      final error = await AppScope.read(context).signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _role!,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _step--;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: subPageBar(context, 'Criar conta'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Passo ${_step + 1} de 3', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_step + 1) / 3,
                          minHeight: 8,
                          semanticsLabel: 'Progresso do cadastro',
                          semanticsValue: 'Passo ${_step + 1} de 3',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionHeading(title: _titles[_step]),
                        const SizedBox(height: 8),
                        if (_error != null) ...[
                          NoticeBox(text: _error!, tone: NoticeTone.danger),
                          const SizedBox(height: 16),
                        ],
                        if (_step == 0) _buildRoleStep(),
                        if (_step == 1) _buildDataStep(),
                        if (_step == 2) _buildConsentStep(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: _back, child: Text(_step == 0 ? 'Cancelar' : 'Voltar')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy ? null : _next,
                          child: Text(_busy ? 'Criando…' : (_step == 2 ? 'Criar conta' : 'Continuar')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RoleOption(
          icon: Icons.favorite_rounded,
          color: AppColors.elder,
          title: 'Sou idoso',
          text: 'Quero receber os lembretes dos meus remédios.',
          selected: _role == UserRole.idoso,
          onTap: () => setState(() => _role = UserRole.idoso),
        ),
        _RoleOption(
          icon: Icons.volunteer_activism_rounded,
          color: AppColors.caregiver,
          title: 'Sou cuidador ou familiar',
          text: 'Quero acompanhar os remédios de alguém, com ou sem o app no celular dele.',
          selected: _role == UserRole.cuidador,
          onTap: () => setState(() => _role = UserRole.cuidador),
        ),
        _RoleOption(
          icon: Icons.medical_services_rounded,
          color: AppColors.doctor,
          title: 'Sou médico',
          text: 'Quero acompanhar a adesão dos meus pacientes. No produto final, é um painel web.',
          selected: _role == UserRole.medico,
          onTap: () => setState(() => _role = UserRole.medico),
        ),
      ],
    );
  }

  Widget _buildDataStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline_rounded)),
            validator: (v) => (v == null || v.trim().split(RegExp(r'\s+')).length < 2)
                ? 'Digite nome e sobrenome.'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
            validator: (v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()))
                ? 'Digite um email válido, como maria@email.com.'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Senha',
              helperText: 'Pelo menos 6 caracteres.',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Esconder a senha' : 'Mostrar a senha',
                icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'A senha precisa ter pelo menos 6 caracteres.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            obscureText: !_showPassword,
            decoration: const InputDecoration(labelText: 'Repita a senha', prefixIcon: Icon(Icons.lock_outline_rounded)),
            validator: (v) => v != _passwordController.text ? 'As duas senhas estão diferentes.' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildConsentStep() {
    final textTheme = Theme.of(context).textTheme;
    final who = switch (_role) {
      UserRole.idoso => 'Seus remédios e se você tomou cada dose ficam visíveis só para quem você aceitar: '
          'seus cuidadores e seus médicos.',
      UserRole.cuidador => 'Você só vê os dados de quem aceitar o seu convite, ou de quem você cadastrar '
          'por não usar o app.',
      _ => 'Você só vê os dados dos pacientes vinculados a você.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'O CuidarMais guarda informações de saúde, que a LGPD trata como dados sensíveis. Por isso pedimos o seu consentimento.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        NoticeBox(icon: Icons.lock_person_rounded, title: 'Quem vê os dados', text: who),
        const SizedBox(height: 12),
        const NoticeBox(
          icon: Icons.block_rounded,
          title: 'O que nunca fazemos',
          text: 'Não vendemos nem compartilhamos dados de saúde para propaganda. Você pode tirar acessos e apagar a conta quando quiser.',
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: CheckboxListTile(
            value: _consent,
            onChanged: (v) => setState(() {
              _consent = v ?? false;
              _error = null;
            }),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Li e concordo com o uso dos meus dados de saúde como descrito acima.'),
          ),
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$title. $text',
        child: ExcludeSemantics(
          child: Material(
            color: selected ? color.withValues(alpha: dark ? 0.35 : 0.1) : scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: selected ? color : scheme.outlineVariant, width: selected ? 2.5 : 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: color.withValues(alpha: dark ? 0.4 : 0.14),
                      child: Icon(icon, color: dark ? AppColors.onColor : color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(text, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Icon(
                      selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: selected ? color : scheme.outline,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
