import 'package:flutter/material.dart';
import '../../data/models/medication.dart';
import '../../data/models/people.dart';
import '../../data/store/app_scope.dart';
import '../utils/format.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/notice_box.dart';
import '../widgets/section_heading.dart';

/// Cadastro e edição de remédio — o mesmo formulário para idoso, cuidador
/// e médico (documento do projeto v2). Muda só a origem registrada e, para
/// o idoso, o campo de prazo do alerta fica escondido.
///
/// Segue as recomendações de formulário do WAI: instrução no início
/// (G184), label + dica em todo campo (3.3.2), erro descrito em texto
/// (3.3.1) e uma etapa de revisão antes de salvar (3.3.4).
class MedicationFormScreen extends StatefulWidget {
  final Elder elder;
  final MedicationOrigin origin;
  final String authorName;
  final bool showAlertDelay;
  final Medication? initial;

  const MedicationFormScreen({
    super.key,
    required this.elder,
    required this.origin,
    required this.authorName,
    this.showAlertDelay = true,
    this.initial,
  });

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late List<TimeOfDay> _times;
  late Set<int> _days;
  late DateTime _start;
  DateTime? _end;
  late int _alertMinutes;
  bool _reviewing = false;
  String? _timesError;
  String? _daysError;
  String? _endError;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _nameController = TextEditingController(text: m?.name ?? '');
    _dosageController = TextEditingController(text: m?.dosage ?? '');
    _times = m == null ? [const TimeOfDay(hour: 8, minute: 0)] : List.of(m.times);
    _days = m == null ? {1, 2, 3, 4, 5, 6, 7} : Set.of(m.weekdays);
    _start = m?.start ?? dateOnly(DateTime.now());
    _end = m?.end;
    _alertMinutes = m?.alertMinutes ?? 30;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  String get _originText {
    switch (widget.origin) {
      case MedicationOrigin.medico:
        return 'Fica registrado como prescrição validada e vale como versão de referência.';
      case MedicationOrigin.familia:
        return 'Vai aparecer para o médico como cadastrado pela família. Os lembretes começam no próximo horário.';
      case MedicationOrigin.paciente:
        return 'Vai aparecer como cadastrado por você. Seu cuidador e seu médico ficam sabendo.';
    }
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      // Digitar o horário é mais fácil do que arrastar o ponteiro para
      // quem tem tremor ou pouca destreza.
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'Horário do remédio',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || _times.contains(picked)) return;
    setState(() {
      _times = [..._times, picked]..sort(compareTimeOfDay);
      _timesError = null;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : (_end ?? _start),
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365 * 3)),
      helpText: isStart ? 'Quando começa' : 'Quando termina',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
      _endError = null;
    });
  }

  void _goToReview() {
    final fieldsOk = _formKey.currentState!.validate();
    setState(() {
      _timesError = _times.isEmpty ? 'Adicione pelo menos um horário.' : null;
      _daysError = _days.isEmpty ? 'Escolha pelo menos um dia da semana.' : null;
      _endError = (_end != null && _end!.isBefore(_start)) ? 'A data de fim precisa ser depois do início.' : null;
    });
    if (fieldsOk && _timesError == null && _daysError == null && _endError == null) {
      setState(() => _reviewing = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tem algo para corrigir. Confira os avisos em vermelho.')),
      );
    }
  }

  void _confirmSave() {
    final store = AppScope.read(context);
    final name = _nameController.text.trim();
    if (_editing) {
      store.updateMedication(
        widget.initial!,
        name: name,
        dosage: _dosageController.text,
        times: _times,
        weekdays: _days,
        start: _start,
        end: _end,
        alertMinutes: _alertMinutes,
        editorName: widget.authorName,
      );
    } else {
      store.addMedication(
        elder: widget.elder,
        name: name,
        dosage: _dosageController.text,
        times: _times,
        weekdays: _days,
        start: _start,
        end: _end,
        alertMinutes: _alertMinutes,
        origin: widget.origin,
        authorName: widget.authorName,
      );
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: Text(_editing ? '$name atualizado. Os próximos lembretes já seguem a mudança.' : '$name cadastrado e lembretes agendados.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: subPageBar(context, _editing ? 'Editar remédio' : 'Cadastrar remédio'),
      body: SafeArea(child: _reviewing ? _buildReview(context) : _buildForm(context)),
    );
  }

  Widget _buildForm(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(
              title: _editing ? widget.initial!.name : 'Novo remédio',
              subtitle: 'Para ${widget.elder.name}. Os campos com * são obrigatórios.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome do remédio *', hintText: 'Ex.: Losartana 50 mg'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome do remédio.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Dose *', hintText: 'Ex.: 1 comprimido'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a dose.' : null,
            ),
            const SizedBox(height: 24),
            Semantics(header: true, child: Text('Horários *', style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final t in _times)
                  InputChip(
                    label: Text(hhmmOf(t), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    onDeleted: () => setState(() => _times = _times.where((x) => x != t).toList()),
                    deleteButtonTooltipMessage: 'Remover o horário ${hhmmOf(t)}',
                  ),
                OutlinedButton.icon(
                  onPressed: _addTime,
                  icon: const Icon(Icons.add_alarm_rounded),
                  label: const Text('Adicionar horário'),
                ),
              ],
            ),
            if (_timesError != null) _ErrorText(_timesError!, color: error),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Semantics(
                  header: true,
                  child: Text('Dias da semana *', style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _days = {1, 2, 3, 4, 5, 6, 7};
                    _daysError = null;
                  }),
                  child: const Text('Todos os dias'),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var d = 1; d <= 7; d++)
                  FilterChip(
                    label: Text(weekdayShort[d - 1]),
                    selected: _days.contains(d),
                    onSelected: (on) => setState(() {
                      _days = on ? {..._days, d} : (Set.of(_days)..remove(d));
                      _daysError = null;
                    }),
                  ),
              ],
            ),
            if (_daysError != null) _ErrorText(_daysError!, color: error),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.event_rounded),
                    title: const Text('Começa em'),
                    subtitle: Text(shortDate(_start)),
                    trailing: TextButton(onPressed: () => _pickDate(isStart: true), child: const Text('Mudar')),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.event_available_rounded),
                    title: const Text('Tem data para terminar'),
                    subtitle: Text(_end == null ? 'Uso contínuo' : 'Termina em ${shortDate(_end!)}'),
                    value: _end != null,
                    onChanged: (on) => setState(() {
                      _end = on ? _start.add(const Duration(days: 7)) : null;
                      _endError = null;
                    }),
                  ),
                  if (_end != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: TextButton(
                          onPressed: () => _pickDate(isStart: false),
                          child: const Text('Mudar a data de fim'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_endError != null) _ErrorText(_endError!, color: error),
            if (widget.showAlertDelay) ...[
              const SizedBox(height: 24),
              DropdownButtonFormField<int>(
                value: _alertMinutes,
                isExpanded: true, // ocupa a largura toda e quebra o texto com a letra grande
                decoration: const InputDecoration(
                  labelText: 'Avisar o cuidador se não houver resposta em',
                  helperText: 'Depois de 2 adiamentos o cuidador é avisado na hora.',
                  helperMaxLines: 3,
                  labelStyle: TextStyle(overflow: TextOverflow.visible),
                ),
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15 minutos')),
                  DropdownMenuItem(value: 30, child: Text('30 minutos')),
                  DropdownMenuItem(value: 60, child: Text('60 minutos')),
                ],
                onChanged: (v) => setState(() => _alertMinutes = v ?? 30),
              ),
            ],
            const SizedBox(height: 24),
            NoticeBox(text: _originText, icon: Icons.history_edu_rounded),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _goToReview, child: const Text('Revisar antes de salvar')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            title: 'Confirme antes de salvar',
            subtitle: 'Revise os dados. Você pode voltar e corrigir antes de confirmar.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReviewRow(label: 'Para', value: widget.elder.name),
                  _ReviewRow(label: 'Remédio', value: _nameController.text),
                  _ReviewRow(label: 'Dose', value: _dosageController.text),
                  _ReviewRow(label: 'Horários', value: timesLabel(_times)),
                  _ReviewRow(label: 'Dias', value: daysLabel(_days)),
                  _ReviewRow(label: 'Início', value: shortDate(_start)),
                  _ReviewRow(label: 'Fim', value: _end == null ? 'Uso contínuo' : shortDate(_end!)),
                  if (widget.showAlertDelay)
                    _ReviewRow(label: 'Alerta ao cuidador', value: 'Após $_alertMinutes minutos sem resposta'),
                  _ReviewRow(label: 'Origem', value: widget.origin.label),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _reviewing = false),
                  child: const Text('Voltar e corrigir'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: _confirmSave, child: const Text('Confirmar e salvar'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  final Color color;
  const _ErrorText(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
