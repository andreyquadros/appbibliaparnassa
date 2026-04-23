import 'dart:math' as math;

import 'package:flutter/material.dart';

class ThreeDBanner extends StatefulWidget {
  const ThreeDBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.assetPath,
    this.height = 190,
    this.icon = Icons.auto_awesome,
  });

  final String title;
  final String subtitle;
  final String? assetPath;
  final double height;
  final IconData icon;

  @override
  State<ThreeDBanner> createState() => _ThreeDBannerState();
}

class _ThreeDBannerState extends State<ThreeDBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final wave = math.sin(_controller.value * math.pi * 2);
        final tiltX = wave * 0.015;
        final tiltY = wave * 0.025;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(tiltX)
            ..rotateY(tiltY),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  colorScheme.primary.withValues(alpha: 0.86),
                  colorScheme.secondary.withValues(alpha: 0.74),
                  colorScheme.primaryContainer.withValues(alpha: 0.76),
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.34),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (widget.assetPath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Opacity(
                      opacity: 0.28,
                      child: Image.asset(
                        widget.assetPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Positioned(
                  top: -28,
                  right: -24,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -26,
                  left: -18,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(widget.icon, color: Colors.white, size: 26),
                      const Spacer(),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.94),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
