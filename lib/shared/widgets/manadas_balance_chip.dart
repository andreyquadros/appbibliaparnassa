import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class ManadasBalanceChip extends StatelessWidget {
  const ManadasBalanceChip({
    super.key,
    this.balance = 120,
    this.label = AppStrings.currencySymbol,
  });

  final int balance;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: const Color(0xFF173764),
      side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
      avatar: const Icon(Icons.auto_awesome, size: 18, color: AppColors.accent),
      label: Text(
        '$balance $label',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
