import 'package:flutter/material.dart';
import '../../data/models/people.dart';
import '../../data/store/app_scope.dart';
import '../utils/format.dart';
import 'cuidar_logo.dart';
import 'font_size_toggle.dart';

/// Barra do topo das telas principais: nome do app, controle de tamanho
/// do texto (sempre visível, WCAG 1.4.4) e o menu da conta.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: Semantics(
        header: true,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CuidarLogo(size: 32),
            SizedBox(width: 10),
            Flexible(child: Text('Cuidar+', overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      actions: [
        FontSizeToggle(controller: TextScaleScope.of(context)),
        const AccountMenu(),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Barra das telas que abrem por cima: título + controle de texto.
AppBar subPageBar(BuildContext context, String title) {
  return AppBar(
    title: Text(title, overflow: TextOverflow.ellipsis),
    actions: [FontSizeToggle(controller: TextScaleScope.of(context)), const SizedBox(width: 8)],
  );
}

enum _MenuAction { advance, reset, logout }

/// Menu da conta. Também guarda os controles da demonstração (passar o
/// tempo e recomeçar), já que o protótipo ainda não tem relógio real.
class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final user = store.currentUser;
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<_MenuAction>(
      tooltip: 'Sua conta e a demonstração',
      icon: CircleAvatar(radius: 18, child: Text(user.initials, style: const TextStyle(fontWeight: FontWeight.w700))),
      onSelected: (action) {
        final messenger = ScaffoldMessenger.of(context);
        switch (action) {
          case _MenuAction.advance:
            store.advanceClock();
            messenger.showSnackBar(SnackBar(content: Text('Demonstração: agora são ${hhmm(store.now)}.')));
          case _MenuAction.reset:
            store.resetDemo();
            messenger.showSnackBar(const SnackBar(content: Text('Demonstração recomeçada às 08:05.')));
          case _MenuAction.logout:
            Navigator.of(context).popUntil((route) => route.isFirst);
            store.logout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(user.initials)),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${user.role.label} · ${user.email}'),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _MenuAction.advance,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.fast_forward_rounded),
            title: const Text('Demonstração: passar 15 minutos'),
            subtitle: Text('Agora são ${hhmm(store.now)}'),
          ),
        ),
        const PopupMenuItem(
          value: _MenuAction.reset,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.restart_alt_rounded),
            title: Text('Recomeçar demonstração'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _MenuAction.logout,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded),
            title: Text('Sair'),
          ),
        ),
      ],
    );
  }
}
