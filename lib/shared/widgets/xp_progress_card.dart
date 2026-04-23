import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class XpProgressCard extends StatelessWidget {
  const XpProgressCard({
    super.key,
    this.level = 3,
    this.currentXp = 240,
    this.nextLevelXp = 400,
  });

  final int level;
  final int currentXp;
  final int nextLevelXp;

  @override
  Widget build(BuildContext context) {
    final safeNextLevelXp = nextLevelXp <= 0 ? 1 : nextLevelXp;
    final progress = (currentXp / safeNextLevelXp).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Nível $level',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 16,
                backgroundColor: AppColors.surfaceTint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$currentXp / $safeNextLevelXp XP',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
