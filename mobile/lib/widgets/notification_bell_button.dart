import 'package:flutter/material.dart';

import '../app/session_scope.dart';

class NotificationBellButton extends StatelessWidget {
  final Color? iconColor;

  const NotificationBellButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    final unread = session.unreadNotificationCount;

    return IconButton(
      tooltip: 'Notificações',
      onPressed: () async {
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (ctx) {
            final s = SessionScope.of(ctx);
            final items = s.notifications;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Notificações',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (items.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text('Sem notificações.'),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final n = items[index];
                              return Card(
                                elevation: 0,
                                color: n.read
                                    ? const Color(0xFFF6F6F6)
                                    : const Color(0xFFFFF8E6),
                                child: ListTile(
                                  title: Text(
                                    n.title.isEmpty ? 'Notificação' : n.title,
                                    style: TextStyle(
                                      fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (n.body.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(n.body),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatDate(n.createdAt),
                                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    tooltip: n.read ? 'Lida' : 'Marcar como lida',
                                    icon: Icon(
                                      n.read ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: n.read ? Colors.green : Colors.black45,
                                    ),
                                    onPressed: () {
                                      s.markNotificationRead(n.id);
                                    },
                                  ),
                                  onTap: () {
                                    s.markNotificationRead(n.id);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: items.isEmpty
                                ? null
                                : () {
                                    s.clearNotifications();
                                    Navigator.pop(ctx);
                                  },
                            child: const Text('Limpar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none, color: iconColor),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  unread > 99 ? '99+' : unread.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
