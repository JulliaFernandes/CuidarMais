import 'package:flutter/material.dart';
import '../../../data/models/care_alert.dart';
import '../../../data/store/app_scope.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/notice_box.dart';
import '../../../shared/widgets/section_heading.dart';
import 'cuidador_elder_screen.dart';

/// Histórico de alertas do cuidador. Cada linha diz o que aconteceu em
/// texto, com ícone de aberto ou resolvido.
class CuidadorAlertsScreen extends StatelessWidget {
  const CuidadorAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final me = store.currentUser!;
    final alerts = store.alertsFor(store.eldersOfCaregiver(me.id).map((e) => e.id));
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeading(
          title: 'Alertas',
          subtitle: 'O alerta chega quando a pessoa adia o lembrete 2 vezes ou não responde.',
        ),
        const SizedBox(height: 12),
        if (alerts.isEmpty) const NoticeBox(tone: NoticeTone.success, text: 'Nenhum alerta hoje.'),
        for (final a in alerts)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              minVerticalPadding: 14,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => CuidadorElderScreen(elderId: a.elderId))),
              leading: Icon(
                a.isOpen ? Icons.notifications_active_rounded : Icons.check_circle_rounded,
                color: a.isOpen ? scheme.error : scheme.tertiary,
                size: 30,
              ),
              title: Text(
                '${store.elderById(a.elderId).nickname} · ${a.medicationName}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${a.reason == AlertReason.adiouDuasVezes ? 'Adiou 2 vezes' : 'Não respondeu'} · alerta às ${hhmm(a.createdAt)}\n'
                '${a.isOpen ? 'Ainda sem confirmação' : 'Tomou às ${hhmm(a.resolvedAt!)}'}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
      ],
    );
  }
}
