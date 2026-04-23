import 'package:flutter/material.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/shared/widgets/pv_scaffold.dart';

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    this.read = false,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final bool read;
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    this.items = const [
      NotificationItem(
        title: 'Lembrete de oração',
        subtitle: 'Seu horário diário começou agora.',
        timeLabel: 'Agora',
      ),
      NotificationItem(
        title: 'Novo quiz disponível',
        subtitle: 'Ganhe XP extra ao concluir hoje.',
        timeLabel: '1h',
      ),
      NotificationItem(
        title: 'Pedido respondido',
        subtitle: 'Um pedido em sua lista foi marcado como respondido.',
        timeLabel: 'Ontem',
        read: true,
      ),
    ],
  });

  final List<NotificationItem> items;

  @override
  Widget build(BuildContext context) {
    return PvScaffold(
      title: 'Notificações',
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.secondary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu ritmo em lembretes',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Estudo, oração, revisão e respostas importantes aparecem aqui para você não perder o fio da jornada.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.read
                          ? AppColors.surfaceTint
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.read
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_outlined,
                      color: item.read
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                  ),
                  title: Text(item.title),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(item.subtitle),
                  ),
                  trailing: Text(
                    item.timeLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
