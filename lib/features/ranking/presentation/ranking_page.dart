import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/shared/widgets/pv_scaffold.dart';

import '../application/ranking_controller.dart';
import '../domain/ranking_period.dart';

class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(rankingPeriodProvider);
    final entriesAsync = ref.watch(rankingEntriesProvider);

    return PvScaffold(
      title: 'Ranking',
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
                  'Constância em destaque',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'O ranking celebra perseverança, não pressa. Compare seu ritmo, aprenda com a comunidade e continue avançando.',
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
              child: SegmentedButton<RankingPeriod>(
                segments: const [
                  ButtonSegment(
                    value: RankingPeriod.weekly,
                    label: Text('Semanal'),
                  ),
                  ButtonSegment(
                    value: RankingPeriod.monthly,
                    label: Text('Mensal'),
                  ),
                  ButtonSegment(
                    value: RankingPeriod.allTime,
                    label: Text('Geral'),
                  ),
                  ButtonSegment(
                    value: RankingPeriod.friends,
                    label: Text('Amigos'),
                  ),
                ],
                selected: <RankingPeriod>{period},
                onSelectionChanged: (selection) {
                  ref
                      .read(rankingPeriodProvider.notifier)
                      .updatePeriod(selection.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          entriesAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return const Card(
                  child: ListTile(
                    title: Text('Sem ranking disponível'),
                    subtitle: Text(
                      'Quando houver atividade, o ranking aparece aqui.',
                    ),
                  ),
                );
              }

              final podium = entries.take(3).toList(growable: false);
              final others = entries.skip(3).toList(growable: false);

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      podium.length,
                      (index) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : 6,
                            right: index == podium.length - 1 ? 0 : 6,
                          ),
                          child: _PodiumCard(entry: podium[index]),
                        ),
                      ),
                    ),
                  ),
                  if (others.isNotEmpty) const SizedBox(height: 16),
                  ...others.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.surfaceTint,
                            child: Text('${entry.position}'),
                          ),
                          title: Text(entry.name),
                          subtitle: Text(
                            'Nível ${entry.level} • Streak ${entry.streak} • ${entry.weekXp} XP',
                          ),
                          trailing: entry.delta == 0
                              ? const Icon(
                                  Icons.horizontal_rule_rounded,
                                  color: AppColors.textSecondary,
                                )
                              : Icon(
                                  entry.delta > 0
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: entry.delta > 0
                                      ? const Color(0xFF4D8D56)
                                      : const Color(0xFFB04B43),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                child: Text('Falha ao carregar ranking: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.entry});

  final dynamic entry;

  @override
  Widget build(BuildContext context) {
    final isChampion = entry.position == 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isChampion ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isChampion ? AppColors.secondary : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isChampion
                ? Colors.white.withValues(alpha: 0.12)
                : AppColors.surfaceTint,
            child: Text(
              '${entry.position}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isChampion ? Colors.white : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            entry.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isChampion ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${entry.weekXp} XP',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isChampion ? AppColors.accent : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
