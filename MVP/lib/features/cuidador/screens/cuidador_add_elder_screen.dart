import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/people.dart';
import '../../../data/store/app_scope.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/notice_box.dart';
import '../../../shared/widgets/section_heading.dart';
import 'cuidador_elder_screen.dart';

/// Adicionar um idoso. A primeira pergunta define o caminho
/// (documento v2): com app, vínculo por código aceito pelo idoso; sem app,
/// cadastro direto e o cuidador recebe os lembretes dele.
class CuidadorAddElderScreen extends StatefulWidget {
  const CuidadorAddElderScreen({super.key});

  @override
  State<CuidadorAddElderScreen> createState() => _CuidadorAddElderScreenState();
}

class _CuidadorAddElderScreenState extends State<CuidadorAddElderScreen> {
  bool _usesApp = true;
  Invite? _invite;
  final _formKey = GlobalKey<FormState>();
  final _relationController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _relationController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _generateCode() {
    if (!_formKey.currentState!.validate()) return;
    final store = AppScope.read(context);
    setState(() => _invite = store.createInvite(caregiver: store.currentUser!, elderIs: _relationController.text.trim()));
  }

  void _addWithoutApp() {
    if (!_formKey.currentState!.validate()) return;
    final store = AppScope.read(context);
    final elder = store.addElderWithoutApp(
      caregiver: store.currentUser!,
      name: _nameController.text,
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      elderIs: _relationController.text.trim(),
      phone: _phoneController.text,
    );
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CuidadorElderScreen(elderId: elder.id)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${elder.nickname} adicionado. Agora cadastre os remédios dele.')),
    );
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    final relationField = TextFormField(
      controller: _relationController,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(labelText: 'Quem é essa pessoa para você?', hintText: 'Ex.: Mãe, Pai, Avó'),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Conte quem é essa pessoa para você.' : null,
    );

    return Scaffold(
      appBar: subPageBar(context, 'Adicionar idoso'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeading(title: 'A pessoa vai usar o app no celular dela?'),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Sim, vai usar'), icon: Icon(Icons.phone_android_rounded)),
                    ButtonSegment(value: false, label: Text('Não vai usar'), icon: Icon(Icons.phonelink_erase_rounded)),
                  ],
                  selected: {_usesApp},
                  onSelectionChanged: (s) => setState(() {
                    _usesApp = s.first;
                    _invite = null;
                  }),
                  style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 56))),
                ),
                const SizedBox(height: 20),
                if (_usesApp) ..._withApp(relationField) else ..._withoutApp(relationField),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _withApp(Widget relationField) {
    final invite = _invite;
    return [
      const NoticeBox(
        text: 'Ela recebe os lembretes no celular dela. Você recebe o status do dia e um alerta quando ela '
            'adiar 2 vezes ou não responder.',
      ),
      const SizedBox(height: 16),
      if (invite == null) ...[
        relationField,
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: _generateCode, icon: const Icon(Icons.key_rounded), label: const Text('Gerar código de convite')),
      ] else ...[
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Passe este código para ela', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SelectableText(
                  invite.formattedCode,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(letterSpacing: 6),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _copy(invite.formattedCode),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copiar código'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const NoticeBox(
          title: 'E agora?',
          text: 'Ela abre o app CuidarMais, vai em "Família" e digita o código. Só depois que ela aceitar você passa '
              'a ver os remédios dela. O código vale por 24 horas.',
        ),
      ],
    ];
  }

  List<Widget> _withoutApp(Widget relationField) {
    return [
      const NoticeBox(
        text: 'Você recebe os lembretes dele, confirma quando ele tomar e recebe um aviso a cada 15 minutos até '
            'confirmar. O médico vê que a confirmação foi feita por você.',
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nome completo'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Digite o nome.' : null,
      ),
      const SizedBox(height: 16),
      relationField,
      const SizedBox(height: 16),
      TextFormField(
        controller: _ageController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Idade'),
        validator: (v) {
          final n = int.tryParse((v ?? '').trim());
          return (n == null || n < 1 || n > 120) ? 'Digite a idade em números, como 84.' : null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Telefone (opcional)', hintText: 'Ex.: (11) 3456-7788'),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: _addWithoutApp, icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Adicionar')),
    ];
  }
}
