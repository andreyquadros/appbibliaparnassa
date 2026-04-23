import 'package:flutter/material.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';

class PvScaffold extends StatelessWidget {
  const PvScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.all(16),
    this.useSafeArea = true,
    this.showBackButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry padding;
  final bool useSafeArea;
  final bool? showBackButton;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: body);
    final canPop = Navigator.of(context).canPop();
    final resolvedShowBack = showBackButton ?? canPop;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: resolvedShowBack,
        leading: resolvedShowBack ? null : const SizedBox.shrink(),
        actions: actions,
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.secondary, width: 1),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFCFA), AppColors.background],
          ),
        ),
        child: useSafeArea ? SafeArea(child: content) : content,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
