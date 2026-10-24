import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../asha_portal/screens/asha_dashboard_screen.dart';
import '../../doctor_portal/screens/doctor_dashboard_screen.dart';
import '../../patient_portal/screens/patient_dashboard_screen.dart';
import '../widgets/app_brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _animController.forward().then((_) {
      // Hold for half a second then transition
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _navigateNext();
      });
    });
  }

  void _navigateNext() {
    final authService = context.read<AuthService>();
    Widget nextScreen;

    if (!authService.isAuthenticated || authService.currentUser == null) {
      nextScreen = const LoginScreen();
    } else {
      switch (authService.currentUser!.role) {
        case UserRole.asha:
          nextScreen = const AshaDashboardScreen();
          break;
        case UserRole.doctor:
          nextScreen = const DoctorDashboardScreen();
          break;
        case UserRole.patient:
          nextScreen = const PatientDashboardScreen();
          break;
      }
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppBrandLogo(iconSize: 112, isHorizontal: false),
                  const SizedBox(height: AppSpacing.xxl),
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text('Loading…', style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
