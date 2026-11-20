import 'package:flutter/material.dart';
import '../../../data/models/people.dart';
import '../../../data/store/app_scope.dart';
import '../../../data/store/app_store.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/notice_box.dart';
import '../../../shared/widgets/section_heading.dart';
import '../widgets/alert_banner.dart';
import 'cuidador_add_elder_screen.dart';
import 'cuidador_elder_screen.dart';

/// Início do cuidador: primeiro os alertas abertos, depois cada pessoa
/// acompanhada com o status do dia.
class CuidadorOverviewScreen extends StatelessWidget {
  const CuidadorOverviewScreen({super.key});

  void _openElder(BuildContext context, Elder elder) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CuidadorElderScreen(elderId: elder.id)));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final me = store.currentUser!;
    final elders = store.eldersOfCaregiver(me.id);
    final alerts = store.openAlertsFor(elders.map((e) => e.id));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeading(
          title: 'Olá, ${me.firstName}',
          subtitle: elders.isEmpty
              ? 'Adicione a primeira pessoa que você acompanha.'
              : 'Você acompanha ${elders.length} ${plural(elders.length, 'pessoa', 'pessoas')} · ${hhmm(store.now)}',
        ),
        const SizedBox(height: 12),
        for (final a in alerts)
          AlertBanner(
            alert: a,
            elder: store.elderById(a.elderId),
            onOpen: () => _openElder(context, store.elderById(a.elderId)),
          ),
        if (alerts.isEmpty && elders.isNotEmpty)
          const NoticeBox(
            tone: NoticeTone.success,
            title: 'Nenhum alerta agora',
            text: 'Avisamos você se alguém adiar um remédio 2 vezes ou não responder ao lembrete.',
          ),
        const SizedBox(height: 24),
        if (elders.isNotEmpty) const SectionHeading(title: 'Pessoas que você acompanha'),
        for (final e in elders) _ElderCard(elder: e, store: store, onTap: () => _openElder(context, e)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CuidadorAddElderScreen())),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Adicionar idoso'),
        ),
      ],
    );
  }
}

class _ElderCard extends StatelessWidget {
  final Elder elder;
  final AppStore store;
  final VoidCallback onTap;
  const _ElderCard({required this.elder, required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final me = store.currentUser!;
    final doses = store.dosesOf(elder.id);
    final taken = doses.where((d) => d.isTaken).length;
    final hasAlert = store.openAlertsFor([elder.id]).isNotEmpty;
    final waitingForMe = !elder.usesApp && store.currentDose(elder.id) != null;
    final relation = elder.links[me.id]?.elderIs ?? '';

    final pill = hasAlert
        ? const InfoPill(label: 'Precisa de atenção', icon: Icons.warning_amber_rounded, tone: NoticeTone.danger)
        : waitingForMe
            ? const InfoPill(label: 'Confirmar agora', icon: Icons.touch_app_rounded, tone: NoticeTone.warning)
            : const InfoPill(label: 'Em dia', icon: Icons.check_circle_rounded, tone: NoticeTone.success);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Semantics(
          button: true,
          hint: 'Toque para ver os remédios de ${elder.nickname}',
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(radius: 28, child: Text(elder.initials, style: const TextStyle(fontWeight: FontWeight.w700))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [relation, elder.usesApp ? 'usa o app' : 'sem app'].where((s) => s.isNotEmpty).join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(elder.nickname, style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        doses.isEmpty ? 'Nenhum remédio hoje' : '$taken de ${doses.length} remédios hoje',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      pill,
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
