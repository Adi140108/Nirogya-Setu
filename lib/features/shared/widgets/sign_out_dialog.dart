import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../main.dart';

Future<void> showSignOutConfirmationDialog({
  required BuildContext context,
  required AuthService authService,
  String roleName = 'Account',
}) async {
  final shouldSignOut = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 32),
        title: const Text('Sign out?'),
        content: const Text(
          'Your saved records stay on this phone.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.riskRed),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  if (shouldSignOut == true && context.mounted) {
    await authService.signOut();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootGateScreen()),
        (route) => false,
      );
    }
  }
}
