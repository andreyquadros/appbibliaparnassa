import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/core/constants/app_strings.dart';
import 'package:palavra_viva/features/rewards/application/rewards_controller.dart';
import 'package:palavra_viva/shared/widgets/manadas_balance_chip.dart';
import 'package:palavra_viva/shared/widgets/pv_scaffold.dart';

class RewardsPage extends ConsumerStatefulWidget {
  const RewardsPage({super.key, this.balance = 0});

  final int balance;

  @override
  ConsumerState<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends ConsumerState<RewardsPage> {
  bool _unlocking = false;

  Future<void> _unlock(String rewardId) async {
    final rewards = ref.read(filteredRewardsProvider).asData?.value ?? const [];
    final reward = rewards.firstWhere((item) => item.id == rewardId);

    setState(() => _unlocking = true);
    try {
      final ok = await ref.read(rewardsActionsProvider).unlock(reward);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Recompensa desbloqueada com sucesso.'
                : 'Saldo insuficiente para desbloquear.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _unlocking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(rewardsFilterProvider);
    final rewardsAsync = ref.watch(filteredRewardsProvider);

    return PvScaffold(
      title: 'Recompensas',
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
                Text(
                  'Loja sagrada',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Troque suas ${AppStrings.currencyName} por conteúdo, benefícios e itens que fortalecem sua jornada.',
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
              padding: const EdgeInsets.all(8),
              child: SegmentedButton<RewardFilter>(
                segments: const [
                  ButtonSegment(value: RewardFilter.all, label: Text('Todos')),
                  ButtonSegment(
                    value: RewardFilter.tier1,
                    label: Text('Tier 1'),
                  ),
                  ButtonSegment(
                    value: RewardFilter.tier2,
                    label: Text('Tier 2'),
                  ),
                  ButtonSegment(
                    value: RewardFilter.tier3,
                    label: Text('Tier 3'),
                  ),
                  ButtonSegment(
                    value: RewardFilter.tier4,
                    label: Text('Tier 4'),
                  ),
                ],
                selected: <RewardFilter>{filter},
                onSelectionChanged: (selection) {
                  ref
                      .read(rewardsFilterProvider.notifier)
                      .setFilter(selection.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          rewardsAsync.when(
            data: (rewards) {
              if (rewards.isEmpty) {
                return const Card(
                  child: ListTile(
                    title: Text('Nenhuma recompensa disponível'),
                    subtitle: Text(
                      'O catálogo será exibido assim que for publicado.',
                    ),
                  ),
                );
              }
              return Column(
                children: rewards
                    .map(
                      (reward) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceTint,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium_outlined,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reward.title,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${reward.category} • Tier ${reward.tier}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${reward.manadasCost} ${AppStrings.currencySymbol}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: AppColors.secondary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  reward.description,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(height: 1.7),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  reward.preview,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonal(
                                    onPressed: reward.unlocked || _unlocking
                                        ? null
                                        : () => _unlock(reward.id),
                                    child: Text(
                                      reward.unlocked
                                          ? 'Resgatado'
                                          : 'Resgatar',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Falha ao carregar recompensas: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
