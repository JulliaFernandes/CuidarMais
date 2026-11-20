import 'package:flutter/material.dart';
import '../../../data/models/patient.dart';
import '../../../data/store/app_scope.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/notice_box.dart';
import '../../../shared/widgets/section_heading.dart';
import '../widgets/attention_list.dart';
import '../widgets/day_timeline.dart';
import '../widgets/patient_tile.dart';
import 'medico_add_patient_screen.dart';
import 'medico_new_medication_screen.dart';
import 'medico_patient_screen.dart';

/// Painel do médico — no produto final é web (Next.js); aqui roda no mesmo
/// app para validar as telas. Lista de pacientes por exceção, sem nenhuma
/// notificação (o médico só vê quando entra).
class MedicoOverviewScreen extends StatefulWidget {
  const MedicoOverviewScreen({super.key});

  @override
  State<MedicoOverviewScreen> createState() => _MedicoOverviewScreenState();
}

class _MedicoOverviewScreenState extends State<MedicoOverviewScreen> {
  int _tab = 0;

  void _openPatient(PatientSummary patient) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MedicoPatientScreen(elderId: patient.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(),
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
            label: 'Pacientes',
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
    final store = AppScope.of(context);
    final me = store.currentUser!;
    final patients = store.doctorPatients()
      ..sort((a, b) => a.attentionLevel.index.compareTo(b.attentionLevel.index));
    final needsAttention = patients.where((p) => p.attentionLevel != AttentionLevel.estavel).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeading(
          title: 'Olá, ${me.firstName}',
          subtitle: '${longDate(store.now)} · ${hhmm(store.now)}. Você não recebe notificações: os casos aparecem aqui.',
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedicoAddPatientScreen())),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Adicionar paciente'),
          ),
        ),
        const SizedBox(height: 16),
        if (patients.isEmpty)
          const NoticeBox(text: 'Você ainda não tem pacientes. Toque em "Adicionar paciente".')
        else ...[
          if (needsAttention.isNotEmpty) ...[
            SectionHeading(title: 'Precisam de atenção (${needsAttention.length})'),
            AttentionList(patients: needsAttention, onTap: _openPatient),
            const SizedBox(height: 24),
          ] else ...[
            const NoticeBox(tone: NoticeTone.success, text: 'Nenhum paciente precisa de atenção agora.'),
            const SizedBox(height: 24),
          ],
          const SectionHeading(title: 'Régua do dia', subtitle: 'Horários de hoje de todos os pacientes, numa linha do tempo'),
          const SizedBox(height: 8),
          DayTimeline(patients: patients, onTap: _openPatient),
          const SizedBox(height: 24),
          const SectionHeading(title: 'Todos os pacientes'),
          ...patients.map((p) => PatientTile(patient: p, onTap: () => _openPatient(p))),
        ],
      ],
    );
  }
}
