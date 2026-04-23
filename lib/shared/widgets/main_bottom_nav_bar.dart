import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';

enum MainSection { dashboard, bible, study, cards, diary }

class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({super.key, required this.current});

  final MainSection current;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            border: const Border(top: BorderSide(color: AppColors.border)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 74,
              child: Row(
                children: [
                  _Item(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: current == MainSection.dashboard,
                    onTap: () => _go(context, AppRoutes.dashboard),
                  ),
                  _Item(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book_rounded,
                    label: 'Bíblia',
                    isActive: current == MainSection.bible,
                    onTap: () => _go(context, AppRoutes.bible),
                  ),
                  _Item(
                    icon: Icons.auto_stories_outlined,
                    activeIcon: Icons.auto_stories_rounded,
                    label: 'Estudo',
                    isActive: current == MainSection.study,
                    onTap: () => _go(context, AppRoutes.study),
                  ),
                  _Item(
                    icon: Icons.style_outlined,
                    activeIcon: Icons.style_rounded,
                    label: 'Cards',
                    isActive: current == MainSection.cards,
                    onTap: () => _go(context, AppRoutes.flashcards),
                  ),
                  _Item(
                    icon: Icons.edit_note_outlined,
                    activeIcon: Icons.edit_note_rounded,
                    label: 'Diário',
                    isActive: current == MainSection.diary,
                    onTap: () => _go(context, AppRoutes.prayer),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    if (GoRouterState.of(context).uri.path == route) {
      return;
    }
    context.go(route);
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.secondary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
