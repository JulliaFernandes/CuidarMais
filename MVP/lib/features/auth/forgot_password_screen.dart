import 'package:flutter/material.dart';
import '../../data/store/app_scope.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/notice_box.dart';
import '../../shared/widgets/section_heading.dart';

/// Recuperar senha. A mensagem de sucesso não confirma se o email existe,
/// para não expor quem tem conta.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    await AppScope.read(context).sendPasswordReset(_emailController.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: subPageBar(context, 'Recuperar senha'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _sent
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NoticeBox(
                          tone: NoticeTone.success,
                          title: 'Confira seu email',
                          text: 'Se existir uma conta com ${_emailController.text.trim()}, enviamos um link para criar uma senha nova. '
                              'Se não chegar em alguns minutos, olhe também a caixa de spam.',
                        ),
                        const SizedBox(height: 24),
                        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Voltar para o login')),
                      ],
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionHeading(
                            title: 'Esqueceu a senha?',
                            subtitle: 'Digite o email da sua conta. Vamos mandar um link para você criar uma senha nova.',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                            validator: (v) =>
                                (v == null || !v.contains('@')) ? 'Digite um email válido, como maria@email.com.' : null,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _busy ? null : _send,
                            child: Text(_busy ? 'Enviando…' : 'Enviar link'),
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
