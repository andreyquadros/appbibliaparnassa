import 'package:flutter/material.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/core/services/local_cache_service.dart';
import 'package:palavra_viva/core/services/notifications_service.dart';
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

class NotificationsPage extends StatefulWidget {
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
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late bool _enabled;
  late List<TimeOfDay> _times;

  @override
  void initState() {
    super.initState();
    _enabled = LocalCacheService.notificationRemindersEnabled;
    _times = LocalCacheService.notificationReminderTimes
        .map(_timeOfDayFromLabel)
        .toList(growable: false);
  }

  Future<void> _toggleEnabled(bool value) async {
    setState(() => _enabled = value);
    await LocalCacheService.setNotificationRemindersEnabled(value);
    if (value) {
      await _reschedule();
    } else {
      await NotificationsService().cancelDailyStudyReminders();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Lembretes ativados.' : 'Lembretes pausados.'),
      ),
    );
  }

  Future<void> _pickTime(int index) async {
    final next = await showTimePicker(
      context: context,
      initialTime: _times[index],
      helpText: 'Escolha o horário',
      confirmText: 'Salvar',
      cancelText: 'Cancelar',
    );
    if (next == null) return;

    final updated = [..._times]..[index] = next;
    updated.sort((a, b) => _minutesOf(a).compareTo(_minutesOf(b)));
    setState(() => _times = updated);
    await LocalCacheService.setNotificationReminderTimes(
      updated.map(_labelFromTimeOfDay).toList(growable: false),
    );
    if (_enabled) {
      await _reschedule();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Horário do lembrete atualizado.')),
    );
  }

  Future<void> _reschedule() {
    return NotificationsService().scheduleDailyStudyReminders(
      times: _times
          .map(
            (time) => NotificationReminderTime(
              hour: time.hour,
              minute: time.minute,
            ),
          )
          .toList(growable: false),
    );
  }

  TimeOfDay _timeOfDayFromLabel(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 7,
      minute: int.tryParse(parts.last) ?? 0,
    );
  }

  String _labelFromTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  int _minutesOf(TimeOfDay time) => time.hour * 60 + time.minute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _enabled,
                    onChanged: _toggleEnabled,
                    activeThumbColor: AppColors.secondary,
                    title: Text(
                      'Lembretes da Palavra',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Receba avisos pela manhã, no meio do dia e à noite.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var index = 0; index < _times.length; index++) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      enabled: _enabled,
                      leading: Icon(
                        _iconFor(index),
                        color: _enabled
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                      ),
                      title: Text(_labelFor(index)),
                      subtitle: Text(_subtitleFor(index)),
                      trailing: TextButton.icon(
                        onPressed: _enabled ? () => _pickTime(index) : null,
                        icon: const Icon(Icons.schedule_rounded, size: 18),
                        label: Text(_times[index].format(context)),
                      ),
                    ),
                    if (index < _times.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.items.map(
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

  IconData _iconFor(int index) {
    return switch (index) {
      0 => Icons.wb_sunny_outlined,
      1 => Icons.light_mode_outlined,
      _ => Icons.nights_stay_outlined,
    };
  }

  String _labelFor(int index) {
    return switch (index) {
      0 => 'Manhã',
      1 => 'Meio-dia',
      _ => 'Noite',
    };
  }

  String _subtitleFor(int index) {
    return switch (index) {
      0 => 'Começar o dia estudando',
      1 => 'Pausa breve para leitura',
      _ => 'Encerrar o dia em oração',
    };
  }
}
