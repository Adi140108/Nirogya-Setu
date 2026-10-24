import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/screens/role_selection_screen.dart';
import '../widgets/app_brand_logo.dart';
import '../widgets/ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _navigateToRoleSelection(BuildContext context, {required bool isLogin}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoleSelectionScreen(isLogin: isLogin)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppBrandLogo(iconSize: 104, isHorizontal: false),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Check health, keep records and get help from the nearest health centre.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Get started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => _navigateToRoleSelection(context, isLogin: false),
              ),
              const SizedBox(height: AppSpacing.sm),
              _LoginPrompt(onLogin: () => _navigateToRoleSelection(context, isLogin: true)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final VoidCallback onLogin;

  const _LoginPrompt({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        TextButton(onPressed: onLogin, child: const Text('Log in')),
      ],
    );
  }
}
