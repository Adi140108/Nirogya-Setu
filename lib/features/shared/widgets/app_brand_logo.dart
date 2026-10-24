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

          // Right: "Nirogya Setu" & Bottom Tagline
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
                        text: 'Nirogya ',
                        style: TextStyle(color: Color(0xFF8B3A22)), // Warm Warli Terracotta
                      ),
                      TextSpan(
                        text: 'Setu',
                        style: TextStyle(color: Color(0xFF2E5A36)), // Neem Leaf Green
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // Bottom Tagline
                const Text(
                  'Sehat, Ghar Ke Darwaze Tak',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B3A22), // Terracotta
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
                text: 'Nirogya ',
                style: TextStyle(color: Color(0xFF8B3A22)),
              ),
              TextSpan(
                text: 'Setu',
                style: TextStyle(color: Color(0xFF2E5A36)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sehat, Ghar Ke Darwaze Tak',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B3A22),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
