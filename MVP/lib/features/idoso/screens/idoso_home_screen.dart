import 'package:flutter/material.dart';
import '../../../data/store/app_scope.dart';
import '../../../shared/widgets/app_top_bar.dart';
import 'idoso_chat_screen.dart';
import 'idoso_family_screen.dart';
import 'idoso_medications_screen.dart';
import 'idoso_today_screen.dart';

/// App do idoso. Quatro destinos fixos na barra de baixo, sempre na mesma
/// ordem (WCAG 3.2.3), trocados por toque e não por gesto de arrastar.
class IdosoHomeScreen extends StatefulWidget {
  const IdosoHomeScreen({super.key});

  @override
  State<IdosoHomeScreen> createState() => _IdosoHomeScreenState();
}

class _IdosoHomeScreenState extends State<IdosoHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final elder = store.myElder;
    if (elder == null) return const Scaffold(body: SizedBox.shrink());
    final waiting = store.currentDose(elder.id) != null;

    return Scaffold(
      appBar: const AppTopBar(),
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            IdosoChatScreen(elder: elder),
            IdosoTodayScreen(elder: elder),
            IdosoMedicationsScreen(elder: elder),
            IdosoFamilyScreen(elder: elder),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: Badge(isLabelVisible: waiting, child: const Icon(Icons.chat_bubble_outline_rounded)),
            selectedIcon: Badge(isLabelVisible: waiting, child: const Icon(Icons.chat_bubble_rounded)),
            label: 'Lembretes',
            tooltip: waiting ? 'Lembretes, tem remédio esperando' : 'Lembretes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny_rounded),
            label: 'Hoje',
          ),
          const NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Remédios',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt_rounded),
            label: 'Família',
          ),
        ],
      ),
    );
  }
}
