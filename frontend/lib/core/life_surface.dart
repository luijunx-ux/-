import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tianrenlu/core/life_theme.dart';

class LifeBackground extends StatelessWidget {
  const LifeBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[t.backgroundTop, t.backgroundBottom],
        ),
      ),
      child: child,
    );
  }
}

class LifePanel extends StatelessWidget {
  const LifePanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: t.outline),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class LifeEmptyState extends StatelessWidget {
  const LifeEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return LifePanel(
      padding: const EdgeInsets.all(28),
      child: Column(children: <Widget>[
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.surfaceStrong,
            border: Border.all(color: t.outline),
          ),
          child: Icon(icon, size: 32, color: t.accent),
        ),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textSecondary, height: 1.45)),
        if (action != null) ...<Widget>[
          const SizedBox(height: 18),
          action!,
        ],
      ]),
    );
  }
}
