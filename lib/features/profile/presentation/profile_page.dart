import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/shared/branding/palavra_viva_logo.dart';
import 'package:palavra_viva/shared/widgets/journey_pie_chart_card.dart';
import 'package:palavra_viva/shared/widgets/manadas_balance_chip.dart';
import 'package:palavra_viva/shared/widgets/pv_scaffold.dart';
import 'package:palavra_viva/shared/widgets/xp_progress_card.dart';

import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
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
    this.onOpenSavedItems,
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
  final VoidCallback? onOpenSavedItems;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _notifications = true;

  Future<void> _openEditProfile() async {
    final authState = ref.read(authControllerProvider);
    final currentUser = authState.user;
    if (currentUser == null) {
      return;
    }

    final nameController = TextEditingController(text: currentUser.name);
    final denominationController = TextEditingController(
      text: currentUser.denomination,
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: denominationController,
              decoration: const InputDecoration(labelText: 'Denominação'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final nextName = nameController.text.trim();
              final nextDenomination = denominationController.text.trim();
              if (nextName.isEmpty) {
                return;
              }
              ref
                  .read(authControllerProvider.notifier)
                  .updateUser(
                    currentUser.copyWith(
                      name: nextName,
                      denomination: nextDenomination.isEmpty
                          ? currentUser.denomination
                          : nextDenomination,
                    ),
                  );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perfil atualizado com sucesso.')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    nameController.dispose();
    denominationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalStreak =
        widget.studyStreak + widget.prayerStreak + widget.fastingStreak;
    final savedItemsAsync = ref.watch(savedItemsProvider);

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
          savedItemsAsync.when(
            data: (items) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Itens salvos',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onOpenSavedItems,
                          child: const Text('Ver todos'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Text(
                        'Suas palavras e estudos salvos vão aparecer aqui.',
                      )
                    else
                      ...items.take(2).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceTint,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                if (item.reference.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.reference,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(color: AppColors.secondary),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  item.excerpt,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Não foi possível carregar seus salvos: $error'),
              ),
            ),
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
          _ProfileActionTile(
            icon: Icons.edit_outlined,
            title: 'Editar perfil',
            subtitle: 'Atualize nome e informações básicas da sua jornada',
            onTap: _openEditProfile,
          ),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.bookmark_outline_rounded,
            title: 'Itens salvos',
            subtitle: 'Veja palavras, versículos e estudos que você guardou',
            onTap: widget.onOpenSavedItems,
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
