import 'package:flutter/material.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/patient.dart';
import '../../../shared/widgets/section_heading.dart';
import '../widgets/attention_list.dart';
import '../widgets/day_timeline.dart';
import '../widgets/patient_tile.dart';
import 'medico_new_medication_screen.dart';
import 'medico_patient_screen.dart';

/// Aba do médico — painel web com os resultados, como descrito no
/// documento do projeto: lista de pacientes por exceção, sem nenhuma
/// notificação (o médico só vê quando entra).
class MedicoOverviewScreen extends StatefulWidget {
  const MedicoOverviewScreen({super.key});

  @override
  State<MedicoOverviewScreen> createState() => _MedicoOverviewScreenState();
}

class _MedicoOverviewScreenState extends State<MedicoOverviewScreen> {
  int _tab = 0;
  late final List<PatientSummary> _patients;

  @override
  void initState() {
    super.initState();
    _patients = MockData.patients();
  }

  void _openPatient(PatientSummary patient) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MedicoPatientScreen(patient: patient)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            _buildOverview(context),
            const MedicoNewMedicationScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Visão geral',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Cadastrar',
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    final needsAttention = _patients.where((p) => p.attentionLevel != AttentionLevel.estavel).toList()
      ..sort((a, b) => a.attentionLevel.index.compareTo(b.attentionLevel.index));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeading(title: 'Olá, Dra. Helena', subtitle: 'Visão geral dos seus pacientes hoje'),
        const SizedBox(height: 16),
        if (needsAttention.isNotEmpty) ...[
          SectionHeading(title: 'Precisam de atenção (${needsAttention.length})'),
          AttentionList(patients: needsAttention, onTap: _openPatient),
          const SizedBox(height: 24),
        ],
        const SectionHeading(title: 'Régua do dia', subtitle: 'Horários de hoje de todos os pacientes, numa linha do tempo'),
        const SizedBox(height: 8),
        DayTimeline(patients: _patients, onTap: _openPatient),
        const SizedBox(height: 24),
        const SectionHeading(title: 'Todos os pacientes'),
        ..._patients.map((p) => PatientTile(patient: p, onTap: () => _openPatient(p))),
      ],
    );
  }
}
