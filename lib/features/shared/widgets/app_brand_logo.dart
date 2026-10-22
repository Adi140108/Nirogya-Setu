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
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Cropped Emblem Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(iconSize * 0.22),
            child: Image.asset(
              'assets/images/logo_icon.png',
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: iconSize,
                height: iconSize,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.health_and_safety_rounded, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Right: "Aarogya Setu" & Bottom Tagline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stylized Title
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: (iconSize * 0.44).clamp(18.0, 28.0),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      fontFamily: 'Roboto',
                    ),
                    children: const [
                      TextSpan(
                        text: 'Aarogya',
                        style: TextStyle(color: Color(0xFF00695C)), // Deep Forest Teal
                      ),
                      TextSpan(
                        text: 'Setu',
                        style: TextStyle(color: Color(0xFFE65100)), // Warm Vibrant Orange
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // Bottom Tagline
                const Text(
                  'Healthy Communities. Brighter Tomorrow.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20), // Forest Green
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Stacked Layout (for Splash & Full Display)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(iconSize * 0.2),
          child: Image.asset(
            'assets/images/logo_icon.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              fontFamily: 'Roboto',
            ),
            children: [
              TextSpan(
                text: 'Aarogya',
                style: TextStyle(color: Color(0xFF00695C)),
              ),
              TextSpan(
                text: 'Setu',
                style: TextStyle(color: Color(0xFFE65100)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Healthy Communities. Brighter Tomorrow.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
