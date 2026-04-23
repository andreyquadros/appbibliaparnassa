import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class PalavraVivaLogo extends StatelessWidget {
  const PalavraVivaLogo({
    super.key,
    this.size = 56,
    this.showTitle = true,
    this.compact = false,
    this.titleColor,
    this.subtitleColor,
  });

  final double size;
  final bool showTitle;
  final bool compact;
  final Color? titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (showTitle && !compact) {
      return Image.asset(
        'assets/branding/logo.png',
        width: size * 4.3,
        fit: BoxFit.contain,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoMark(size: size),
        if (showTitle) ...[
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.appName,
                style: textTheme.titleLarge?.copyWith(color: titleColor),
              ),
              if (!compact)
                Text(
                  'providência diária',
                  style: textTheme.bodySmall?.copyWith(
                    color: subtitleColor ?? AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/branding/logoiconefundotransparente.png',
        height: size,
        width: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
