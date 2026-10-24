import 'package:flutter/material.dart';
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE5F7EE), // Gentle pastel mint
              Color(0xFFE0F3F8), // Soft transition
              Color(0xFFCCE8FE), // Calming light sky blue
              Color(0xFFBADDF8), // Bottom soft blue
            ],
            stops: [0.0, 0.35, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),

                          // Animated App Emblem & Title
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                children: [
                                  // Logo icon
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0284C7).withOpacity(0.18),
                                          blurRadius: 32,
                                          spreadRadius: 4,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.asset(
                                        'assets/images/logo_icon.png',
                                        width: 110,
                                        height: 110,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Title: Aarogya Setu
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        fontFamily: 'Roboto',
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Aarogya ',
                                          style: TextStyle(color: Color(0xFF0F766E)), // Deep teal
                                        ),
                                        TextSpan(
                                          text: 'Setu',
                                          style: TextStyle(color: Color(0xFFEA580C)), // Orange
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Tagline
                                  const Text(
                                    'Healthy Communities. Brighter Tomorrow.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(flex: 3),

                          // Bottom Action Button & Log In Link
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Log In Button
                                  ElevatedButton(
                                    onPressed: _navigateToRoleSelection,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E88E5), // Vibrant primary blue
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor: const Color(0xFF1E88E5).withOpacity(0.4),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Log In to Continue',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 20),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ],
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
