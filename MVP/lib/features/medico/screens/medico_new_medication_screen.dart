import 'package:flutter/material.dart';
import '../../../shared/widgets/section_heading.dart';

/// Cadastro de medicamento. Segue as recomendações de formulário do WAI:
/// instrução no início (G184), label + dica em todo campo (3.3.2), erro
/// descrito em texto (3.3.1) e uma etapa de revisão antes de salvar, para
/// que o envio seja reversível e conferível (3.3.4).
class MedicoNewMedicationScreen extends StatefulWidget {
  const MedicoNewMedicationScreen({super.key});

  @override
  State<MedicoNewMedicationScreen> createState() => _MedicoNewMedicationScreenState();
}

class _MedicoNewMedicationScreenState extends State<MedicoNewMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _timeController = TextEditingController(text: '08:00');
  int _alertMinutes = 30;
  bool _reviewing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _goToReview() {
    if (_formKey.currentState!.validate()) {
      setState(() => _reviewing = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tem campo faltando. Confira os avisos em vermelho abaixo.')),
      );
    }
  }

  void _confirmSave() {
    final name = _nameController.text;
    setState(() => _reviewing = false);
    _formKey.currentState!.reset();
    _nameController.clear();
    _dosageController.clear();
    _timeController.text = '08:00';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name cadastrado e lembretes agendados.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewing) return _buildReview(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(
              title: 'Cadastrar medicamento',
              subtitle: 'Preencha os campos abaixo. Os campos com * são obrigatórios.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do remédio *',
                hintText: 'Ex.: Losartana 50 mg',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome do remédio.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dose *',
                hintText: 'Ex.: 1 comprimido',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a dose.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Horário *',
                hintText: 'Ex.: 08:00',
                helperText: 'Use o formato 24 horas, como 08:00 ou 20:30.',
              ),
              validator: (v) {
                final regex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
                if (v == null || !regex.hasMatch(v.trim())) {
                  return 'Use o formato HH:MM, por exemplo 08:00.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _alertMinutes,
              decoration: const InputDecoration(labelText: 'Avisar o cuidador se não confirmar em'),
              items: const [
                DropdownMenuItem(value: 15, child: Text('15 minutos')),
                DropdownMenuItem(value: 30, child: Text('30 minutos')),
                DropdownMenuItem(value: 60, child: Text('60 minutos')),
              ],
              onChanged: (v) => setState(() => _alertMinutes = v ?? 30),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _goToReview,
                child: const Text('Revisar antes de salvar'),
              ),
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
                  _ReviewRow(label: 'Remédio', value: _nameController.text),
                  _ReviewRow(label: 'Dose', value: _dosageController.text),
                  _ReviewRow(label: 'Horário', value: _timeController.text),
                  _ReviewRow(label: 'Alerta ao cuidador', value: 'Após $_alertMinutes minutos sem confirmar'),
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
              Expanded(
                child: FilledButton(
                  onPressed: _confirmSave,
                  child: const Text('Confirmar e salvar'),
                ),
              ),
            ],
          ),
        ],
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
