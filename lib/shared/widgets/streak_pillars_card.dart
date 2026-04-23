import 'package:flutter/material.dart';

class PillarStreak {
  const PillarStreak({
    required this.name,
    required this.days,
    this.icon = Icons.local_fire_department_outlined,
  });

  final String name;
  final int days;
  final IconData icon;
}

class StreakPillarsCard extends StatelessWidget {
  const StreakPillarsCard({
    super.key,
    this.title = 'Sequência dos Pilares',
    this.pillars = const [
      PillarStreak(
        name: 'Oração',
        days: 4,
        icon: Icons.self_improvement_outlined,
      ),
      PillarStreak(name: 'Palavra', days: 7, icon: Icons.menu_book_outlined),
      PillarStreak(name: 'Jejum', days: 2, icon: Icons.restaurant_outlined),
    ],
  });

  final String title;
  final List<PillarStreak> pillars;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...pillars.map(
              (pillar) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(pillar.icon, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(pillar.name)),
                    Text('${pillar.days}d'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
