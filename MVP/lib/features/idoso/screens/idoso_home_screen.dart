import 'package:flutter/material.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/dose.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../../shared/widgets/status_chip.dart';
import '../widgets/dose_reminder_card.dart';
import 'idoso_medications_screen.dart';
import 'idoso_whatsapp_screen.dart';

/// Aba do idoso — protótipo do que no futuro vira o app. Hoje mostra o
/// lembrete atual e a lista do dia; mais pra frente é aqui que entra o
/// chat de lembretes descrito no documento do projeto.
class IdosoHomeScreen extends StatefulWidget {
  const IdosoHomeScreen({super.key});

  @override
  State<IdosoHomeScreen> createState() => _IdosoHomeScreenState();
}

class _IdosoHomeScreenState extends State<IdosoHomeScreen> {
  int _tab = 0;
  late final List<Dose> _doses;

  @override
  void initState() {
    super.initState();
    _doses = MockData.todayDosesForMaria();
  }

  Dose? get _currentDose {
    for (final d in _doses) {
      if (d.status != DoseStatus.tomada) return d;
    }
    return null;
  }

  void _markTaken(Dose dose) {
    setState(() {
      dose.status = DoseStatus.tomada;
      dose.confirmedAt = DateTime.now();
      dose.confirmedBy = 'idoso';
    });
    _announce('${dose.medicationName} marcado como tomado.');
  }

  void _snooze(Dose dose) {
    setState(() {
      dose.snoozeCount += 1;
      dose.status = dose.snoozeCount >= 2 ? DoseStatus.atrasada : DoseStatus.adiada;
    });
    _announce(
      dose.snoozeCount >= 2
          ? 'Sem problema. A Carla também foi avisada desta vez.'
          : 'Combinado! Chamo de novo em 15 minutos.',
    );
  }

  void _announce(String message) {
    // Confirmação em texto, não só visual (1.4.1), e some sozinha sem
    // bloquear a tela (não é um popup que exige ação).
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            _buildHome(context),
            IdosoMedicationsScreen(doses: _doses),
            const IdosoWhatsAppScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notifications_active_outlined),
            selectedIcon: Icon(Icons.notifications_active),
            label: 'Lembretes',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Meus remédios',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'WhatsApp',
          ),
        ],
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    final dose = _currentDose;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeading(
          title: 'Olá, Dona Maria',
          subtitle: 'Segunda-feira, 19 de outubro',
        ),
        const SizedBox(height: 12),
        if (dose != null)
          DoseReminderCard(
            dose: dose,
            onTake: () => _markTaken(dose),
            onSnooze: dose.snoozeCount >= 2 ? null : () => _snooze(dose),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.celebration_rounded, color: Theme.of(context).colorScheme.tertiary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Você já tomou todos os remédios de hoje!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 28),
        const SectionHeading(title: 'Remédios de hoje'),
        ..._doses.map(
          (d) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(d.medicationName),
              subtitle: Text(
                '${d.scheduledAt.hour.toString().padLeft(2, '0')}:${d.scheduledAt.minute.toString().padLeft(2, '0')}',
              ),
              trailing: StatusChip(status: d.status),
            ),
          ),
        ),
      ],
    );
  }
}
