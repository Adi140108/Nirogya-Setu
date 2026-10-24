import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AppBrandLogo extends StatelessWidget {
  final double iconSize;
  final bool isHorizontal;
  final bool animate;

  const AppBrandLogo({
    super.key,
    this.iconSize = 56,
    this.isHorizontal = true,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Aarogya Setu, health care for every village',
        image: true,
        excludeSemantics: true,
        child: _content(context),
      );

  Widget _emblem(double radius) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/logo_icon.png',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: iconSize,
            height: iconSize,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Icon(Icons.health_and_safety_rounded, color: Colors.white, size: iconSize * 0.55),
          ),
        ),
      );

  Widget _content(BuildContext context) {
    const tagline = 'Health care for every village';

    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _emblem(iconSize * 0.22),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Aarogya Setu',
                  style: TextStyle(
                    fontSize: (iconSize * 0.4).clamp(18.0, 26.0),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(tagline, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _emblem(iconSize * 0.2),
        const SizedBox(height: AppSpacing.lg),
        Text('Aarogya Setu', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          tagline,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
