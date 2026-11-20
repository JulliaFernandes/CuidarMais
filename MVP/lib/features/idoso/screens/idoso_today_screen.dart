import 'package:flutter/material.dart';
import '../../../data/models/people.dart';
import '../../../data/store/app_scope.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/notice_box.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../../shared/widgets/status_chip.dart';

/// Lista dos remédios do dia, em letras grandes (como pedido no documento
/// do projeto). Tela só de leitura, sem ações.
class IdosoTodayScreen extends StatelessWidget {
  final Elder elder;
  const IdosoTodayScreen({super.key, required this.elder});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final doses = store.dosesOf(elder.id);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeading(
          title: 'Hoje',
          subtitle: '${longDate(store.now)}. Cada cartão mostra o horário, o remédio e se já foi tomado.',
        ),
        const SizedBox(height: 12),
        if (doses.isEmpty)
          const NoticeBox(text: 'Nenhum remédio para hoje.')
        else
          ...doses.map(
            (d) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                minVerticalPadding: 16,
                leading: CircleAvatar(
                  radius: 30,
                  child: Text(hhmm(d.scheduledAt), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                title: Text(d.medicationName, style: Theme.of(context).textTheme.titleLarge),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(d.dosageText, style: Theme.of(context).textTheme.bodyLarge),
                ),
                trailing: StatusChip(status: d.status),
              ),
            ),
          ),
      ],
    );
  }
}
