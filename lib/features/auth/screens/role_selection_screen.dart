import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../shared/widgets/app_brand_logo.dart';
import '../../shared/widgets/ui.dart';
import 'auth_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final bool isLogin;

  const RoleSelectionScreen({
    super.key,
    required this.isLogin,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  static const List<_RoleOption> _options = [
    _RoleOption(
      role: UserRole.asha,
      title: 'ASHA worker',
      description: 'Visit homes, check health and refer citizens to a doctor.',
      icon: Icons.health_and_safety_rounded,
    ),
    _RoleOption(
      role: UserRole.doctor,
      title: 'Doctor',
      description: 'Review referred cases and decide next steps.',
      icon: Icons.medical_services_rounded,
    ),
    _RoleOption(
      role: UserRole.patient,
      title: 'Citizen',
      description: 'See your health records and watch health videos.',
      icon: Icons.groups_rounded,
    ),
  ];

  void _onRoleSelected(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          selectedRole: role,
          isLogin: widget.isLogin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selected = _selectedRole;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your role')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const SizedBox(height: AppSpacing.sm),
          const Center(child: AppBrandLogo(iconSize: 64, isHorizontal: false)),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Pick the one that fits you, then tap Continue.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final option in _options) ...[
            _RoleCard(
              option: option,
              selected: selected == option.role,
              onTap: () => setState(() => _selectedRole = option.role),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppSpacing.screen,
          child: AppButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: selected == null ? null : () => _onRoleSelected(context, selected),
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  final UserRole role;
  final String title;
  final String description;
  final IconData icon;

  const _RoleOption({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Large selectable role card: icon chip + role name + one-line description + radio mark.
class _RoleCard extends StatelessWidget {
  final _RoleOption option;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // MergeSemantics folds the InkWell's button node and this selected state
    // into one announcement ("ASHA worker, ..., selected, button").
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: InfoCard(
          onTap: onTap,
          selected: selected,
          child: Row(
            children: [
              Container(
                width: AppSizes.minTouch,
                height: AppSizes.minTouch,
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(option.icon, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.title, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(option.description, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
