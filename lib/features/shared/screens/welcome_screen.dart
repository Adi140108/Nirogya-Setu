import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_locale.dart';
import '../../../core/widgets/craft_background.dart';
import '../../auth/screens/role_selection_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.8, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToRoleSelection() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CraftBackground(
        pieces: const [
          CraftPiece(CraftMotif.paisley, 0.52, left: -0.34, top: -0.22, turns: 0.06),
          CraftPiece(CraftMotif.phulkari, 0.36, right: -0.3, top: 0.12),
          CraftPiece(CraftMotif.neem, 0.42, left: -0.36, bottom: 0.9, turns: -0.05),
          CraftPiece(CraftMotif.sprig, 0.22, right: -0.12, bottom: 2.3),
          CraftPiece(CraftMotif.sun, 0.4, left: -0.3, bottom: -0.28),
          CraftPiece(CraftMotif.kolam, 0.6, right: -0.4, bottom: -0.42),
        ],
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            children: [
                              const Spacer(flex: 3),

                              // Animated App Emblem & Title
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        'assets/images/logo_icon.png',
                                        width: 132,
                                        height: 132,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(height: 22),
                                      const NirogyaWordmark(size: 44),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'निरोग्य सेतु',
                                        style: TextStyle(
                                          fontFamily: 'TiroDevanagari',
                                          fontSize: 24,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Tagline
                                      Builder(
                                        builder: (context) => Text(
                                          context.watch<AppLocale>().t('tagline'),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const Spacer(flex: 4),

                              // Bottom Action Button
                              SlideTransition(
                                position: _slideAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      CraftPillButton(
                                        label: context.watch<AppLocale>().t('loginToContinue'),
                                        onPressed: _navigateToRoleSelection,
                                      ),
                                      const SizedBox(height: 28),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
