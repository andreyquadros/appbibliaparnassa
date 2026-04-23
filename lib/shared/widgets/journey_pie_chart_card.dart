import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class JourneyPieChartCard extends StatelessWidget {
  const JourneyPieChartCard({
    super.key,
    required this.studyDays,
    required this.prayerDays,
    required this.fastingDays,
  });

  final int studyDays;
  final int prayerDays;
  final int fastingDays;

  @override
  Widget build(BuildContext context) {
    final total = studyDays + prayerDays + fastingDays;
    final hasData = total > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição da jornada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              hasData
                  ? 'Como você tem investido seu tempo espiritual.'
                  : 'Complete atividades para visualizar seu gráfico.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: Row(
                children: [
                  Expanded(
                    child: hasData
                        ? PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 28,
                              sections: [
                                _section(studyDays, total, AppColors.primary),
                                _section(
                                  prayerDays,
                                  total,
                                  AppColors.secondary,
                                ),
                                _section(fastingDays, total, AppColors.accent),
                              ],
                            ),
                          )
                        : const Center(child: Icon(Icons.insights_outlined)),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legend(
                          context,
                          color: AppColors.primary,
                          label: 'Palavra',
                          value: studyDays,
                        ),
                        const SizedBox(height: 8),
                        _legend(
                          context,
                          color: AppColors.secondary,
                          label: 'Oração',
                          value: prayerDays,
                        ),
                        const SizedBox(height: 8),
                        _legend(
                          context,
                          color: AppColors.accent,
                          label: 'Jejum',
                          value: fastingDays,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _section(int value, int total, Color color) {
    final percent = total == 0 ? 0 : ((value / total) * 100).round();
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      radius: 34,
      title: '$percent%',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    );
  }

  Widget _legend(
    BuildContext context, {
    required Color color,
    required String label,
    required int value,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ${value}d',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
