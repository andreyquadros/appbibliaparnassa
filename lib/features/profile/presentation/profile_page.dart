import 'package:flutter/material.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/shared/branding/palavra_viva_logo.dart';
import 'package:palavra_viva/shared/widgets/journey_pie_chart_card.dart';
import 'package:palavra_viva/shared/widgets/manadas_balance_chip.dart';
import 'package:palavra_viva/shared/widgets/pv_scaffold.dart';
import 'package:palavra_viva/shared/widgets/xp_progress_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.name = 'Discípulo',
    this.email = 'discipulo@email.com',
    this.balance = 120,
    this.level = 1,
    this.currentXp = 0,
    this.nextLevelXp = 500,
    this.studyStreak = 0,
    this.prayerStreak = 0,
    this.fastingStreak = 0,
    this.onLogout,
  });

  final String name;
  final String email;
  final int balance;
  final int level;
  final int currentXp;
  final int nextLevelXp;
  final int studyStreak;
  final int prayerStreak;
  final int fastingStreak;
  final VoidCallback? onLogout;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final totalStreak =
        widget.studyStreak + widget.prayerStreak + widget.fastingStreak;

    return PvScaffold(
      title: 'Perfil',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(child: ManadasBalanceChip(balance: widget.balance)),
        ),
      ],
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
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white12,
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.email,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const PalavraVivaLogo(
                  size: 34,
                  compact: true,
                  titleColor: Colors.white,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileMetricCard(
                        title: 'Nível',
                        value: '${widget.level}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProfileMetricCard(
                        title: 'Consistência',
                        value: '$totalStreak d',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProfileMetricCard(
                        title: 'Pilares',
                        value:
                            '${widget.studyStreak}/${widget.prayerStreak}/${widget.fastingStreak}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          XpProgressCard(
            level: widget.level,
            currentXp: widget.currentXp,
            nextLevelXp: widget.nextLevelXp,
          ),
          const SizedBox(height: 14),
          JourneyPieChartCard(
            studyDays: widget.studyStreak,
            prayerDays: widget.prayerStreak,
            fastingDays: widget.fastingStreak,
          ),
          const SizedBox(height: 14),
          Card(
            child: SwitchListTile.adaptive(
              value: _notifications,
              onChanged: (value) => setState(() => _notifications = value),
              title: const Text('Notificações'),
              subtitle: const Text(
                'Lembretes de estudo, oração, revisão e continuidade diária',
              ),
            ),
          ),
          const SizedBox(height: 10),
          const _ProfileActionTile(
            icon: Icons.edit_outlined,
            title: 'Editar perfil',
            subtitle: 'Nome, foto, preferências e organização da jornada',
          ),
          const SizedBox(height: 10),
          const _ProfileActionTile(
            icon: Icons.palette_outlined,
            title: 'Aparência',
            subtitle: 'Tema claro editorial com leitura confortável',
          ),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.logout_rounded,
            title: 'Sair da conta',
            subtitle: 'Encerrar a sessão neste dispositivo',
            onTap: widget.onLogout,
            danger: true,
          ),
        ],
      ),
    );
  }
}

class _ProfileMetricCard extends StatelessWidget {
  const _ProfileMetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: danger ? const Color(0xFFFBE7E4) : AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: danger ? const Color(0xFF9C3D31) : AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: danger
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF9C3D31),
                )
              : null,
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
