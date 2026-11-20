import 'package:flutter/material.dart';
import '../../../data/store/app_scope.dart';
import '../../../shared/widgets/app_top_bar.dart';
import 'cuidador_alerts_screen.dart';
import 'cuidador_overview_screen.dart';

/// App do cuidador: Início (alertas e pessoas acompanhadas) e Alertas
/// (histórico). Mesma estrutura de barra inferior do app do idoso.
class CuidadorHomeScreen extends StatefulWidget {
  const CuidadorHomeScreen({super.key});

  @override
  State<CuidadorHomeScreen> createState() => _CuidadorHomeScreenState();
}

class _CuidadorHomeScreenState extends State<CuidadorHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final me = store.currentUser;
    if (me == null) return const Scaffold(body: SizedBox.shrink());
    final ids = store.eldersOfCaregiver(me.id).map((e) => e.id);
    final open = store.openAlertsFor(ids).length;

    return Scaffold(
      appBar: const AppTopBar(),
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: const [CuidadorOverviewScreen(), CuidadorAlertsScreen()],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Badge.count(count: open, isLabelVisible: open > 0, child: const Icon(Icons.notifications_outlined)),
            selectedIcon:
                Badge.count(count: open, isLabelVisible: open > 0, child: const Icon(Icons.notifications_rounded)),
            label: 'Alertas',
            tooltip: open > 0 ? 'Alertas, $open em aberto' : 'Alertas',
          ),
        ],
      ),
    );
  }
}
