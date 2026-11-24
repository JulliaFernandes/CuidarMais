import 'package:flutter/material.dart';
import '../../../data/models/people.dart';
import '../../../data/store/app_scope.dart';
import '../../../shared/widgets/notice_box.dart';
import '../../../shared/widgets/section_heading.dart';

/// Quem acompanha o idoso. O vínculo com um cuidador só vale depois que o
/// idoso digita o código e aceita (consentimento, documento v2 e LGPD).
class IdosoFamilyScreen extends StatefulWidget {
  final Elder elder;
  const IdosoFamilyScreen({super.key, required this.elder});

  @override
  State<IdosoFamilyScreen> createState() => _IdosoFamilyScreenState();
}

class _IdosoFamilyScreenState extends State<IdosoFamilyScreen> {
  final _codeController = TextEditingController();
  Invite? _found;
  String? _error;
  bool _searching = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searching) return;
    setState(() => _searching = true);
    final invite = await AppScope.read(context).lookupInvite(_codeController.text);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _found = invite;
      _error = invite == null
          ? 'Não encontramos esse código, ou ele passou de 24 horas. Confira as letras com quem te enviou.'
          : null;
    });
  }

  String _inviterName(Invite invite) =>
      invite.caregiverName ?? AppScope.read(context).userById(invite.caregiverId)?.name ?? 'A pessoa';

  void _answerDoctor(DoctorRequest request, bool accept) {
    AppScope.read(context).answerDoctorRequest(widget.elder, request, accept: accept);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(accept
          ? '${request.name} agora acompanha seu histórico.'
          : 'Pedido recusado. ${request.name} não vê seus dados.'),
    ));
  }

  void _answer(bool accept) {
    final store = AppScope.read(context);
    final invite = _found!;
    final name = _inviterName(invite).split(RegExp(r'\s+')).first;
    if (accept) {
      store.acceptInvite(invite, widget.elder);
    } else {
      store.declineInvite(invite);
    }
    _codeController.clear();
    setState(() => _found = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(accept ? '$name agora acompanha seus remédios.' : 'Pedido recusado. $name não vê seus dados.'),
    ));
  }

  Future<void> _confirmRemove(AppUser caregiver) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tirar o acesso de ${caregiver.firstName}?'),
        content: Text('${caregiver.firstName} deixa de ver seus remédios e de receber seus alertas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Tirar acesso')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    AppScope.read(context).removeCaregiver(widget.elder, caregiver.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final caregivers = store.caregiversOf(widget.elder);
    final doctors = store.doctorsOf(widget.elder);
    final found = _found;
    final foundName = found == null ? null : _inviterName(found);
    final requests = store.doctorRequestsFor(widget.elder.id);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeading(title: 'Quem me acompanha'),
        const SizedBox(height: 8),
        for (final r in requests) ...[
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 26, child: Text(r.initials)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${r.name}${r.detail == null ? '' : ' (${r.detail})'} quer acompanhar seus remédios.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const NoticeBox(
                    text: 'Se aceitar, o médico vê seus remédios e se você tomou cada dose. Ele não recebe '
                        'notificações. Você pode tirar o acesso quando quiser.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => _answerDoctor(r, false), child: const Text('Recusar'))),
                      const SizedBox(width: 12),
                      Expanded(child: FilledButton(onPressed: () => _answerDoctor(r, true), child: const Text('Aceitar'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Recebeu um código de convite?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Digite o código que seu familiar te passou.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 3),
                  decoration: InputDecoration(labelText: 'Código', hintText: 'Ex.: RUI-482', errorText: _error),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _searching ? null : _search, child: Text(_searching ? 'Procurando…' : 'Procurar')),
              ],
            ),
          ),
        ),
        if (found != null && foundName != null) ...[
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 26, child: Text(initialsOf(foundName))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$foundName (${found.caregiverIs.toLowerCase()}) quer acompanhar seus remédios.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const NoticeBox(
                    text: 'Se aceitar, essa pessoa vê seus remédios e se você tomou, e recebe um aviso quando você não confirma. '
                        'Você pode tirar o acesso quando quiser.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => _answer(false), child: const Text('Recusar'))),
                      const SizedBox(width: 12),
                      Expanded(child: FilledButton(onPressed: () => _answer(true), child: const Text('Aceitar'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const SectionHeading(title: 'Cuidadores', subtitle: 'Recebem um alerta quando você não confirma um remédio.'),
        if (caregivers.isEmpty) const NoticeBox(text: 'Ninguém acompanha você ainda.'),
        for (final c in caregivers)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              minVerticalPadding: 14,
              leading: CircleAvatar(child: Text(c.initials)),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(widget.elder.links[c.id]?.caregiverIs ?? 'Cuidador(a)'),
              trailing: IconButton(
                tooltip: 'Tirar o acesso de ${c.firstName}',
                icon: const Icon(Icons.person_remove_alt_1_rounded),
                onPressed: () => _confirmRemove(c),
              ),
            ),
          ),
        const SizedBox(height: 16),
        const SectionHeading(title: 'Médicos', subtitle: 'Veem seu histórico. Não recebem notificações.'),
        if (doctors.isEmpty) const NoticeBox(text: 'Nenhum médico vinculado ainda.'),
        for (final d in doctors)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              minVerticalPadding: 14,
              leading: CircleAvatar(child: Text(d.initials)),
              title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(d.detail ?? 'Médico(a)'),
            ),
          ),
      ],
    );
  }
}
