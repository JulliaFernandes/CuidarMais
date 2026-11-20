import 'package:flutter/material.dart';
import '../../../data/store/app_scope.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/notice_box.dart';
import '../../../shared/widgets/section_heading.dart';

/// Adicionar paciente pelo email da conta dele no app. É uma proposta: a
/// forma definitiva do vínculo médico–paciente ainda está em aberto
/// (AUTH-7 no backlog).
class MedicoAddPatientScreen extends StatefulWidget {
  const MedicoAddPatientScreen({super.key});

  @override
  State<MedicoAddPatientScreen> createState() => _MedicoAddPatientScreenState();
}

class _MedicoAddPatientScreenState extends State<MedicoAddPatientScreen> {
  final _emailController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final error = AppScope.read(context).linkPatientByEmail(_emailController.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Paciente adicionado à sua lista.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: subPageBar(context, 'Adicionar paciente'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeading(
              title: 'Email do paciente',
              subtitle: 'O paciente precisa ter conta no app Cuidar+. Use o email que ele usa para entrar.',
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              NoticeBox(tone: NoticeTone.danger, text: _error!),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', hintText: 'Ex.: paciente@email.com'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            const NoticeBox(
              text: 'Proposta para o protótipo. Ainda vamos decidir se o vínculo será pelo email do paciente '
                  'ou por um código do médico.',
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _submit, child: const Text('Adicionar')),
          ],
        ),
      ),
    );
  }
}
