import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../awareness_hub/screens/awareness_hub_screen.dart';
import '../../shared/widgets/app_brand_logo.dart';
import '../../shared/widgets/ui.dart';
import '../../../main.dart';

class AuthScreen extends StatefulWidget {
  final UserRole selectedRole;
  final bool isLogin;

  const AuthScreen({
    super.key,
    required this.selectedRole,
    this.isLogin = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isLoginMode;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isLoginMode = widget.isLogin;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _routeToDashboard() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootGateScreen()),
      (route) => false,
    );
  }

  Future<void> _handlePrimarySubmit(AuthService authService) async {
    // Direct bypass/authentication as requested for fast testing & seamless role entry
    await authService.bypassLoginAsRole(
      widget.selectedRole,
      displayName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
    );
    if (mounted) {
      _routeToDashboard();
    }
  }

  Future<void> _handleGoogleSignIn(AuthService authService) async {
    // Direct bypass with Google account simulation
    await authService.bypassLoginAsRole(
      widget.selectedRole,
      displayName: 'Google User',
      email: 'user@gmail.com',
    );
    if (mounted) {
      _routeToDashboard();
    }
  }

  void _handleSkipForCitizen() {
    // As explicitly specified: "skip which then shows only videos for citizens"
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AwarenessHubScreen(isPublicAccess: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isCitizen = widget.selectedRole == UserRole.patient;
    final isLoading = authService.isLoading;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            const SizedBox(height: AppSpacing.sm),
            const Center(child: AppBrandLogo(iconSize: 64, isHorizontal: false)),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _isLoginMode ? 'Welcome back' : 'Create your account',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            _RoleLine(roleName: widget.selectedRole.displayName),
            const SizedBox(height: AppSpacing.xl),

            if (!_isLoginMode) ...[
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  hintText: 'For example, Shanti Devi',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                labelText: 'Email or phone number',
                hintText: 'name@example.com',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) {
                if (!isLoading) _handlePrimarySubmit(authService);
              },
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            AppButton(
              label: _isLoginMode ? 'Log in' : 'Sign up',
              icon: _isLoginMode ? Icons.login_rounded : Icons.person_add_alt_1_rounded,
              loading: isLoading,
              loadingLabel: _isLoginMode ? 'Logging in…' : 'Signing up…',
              onPressed: () => _handlePrimarySubmit(authService),
            ),

            const SizedBox(height: AppSpacing.lg),
            const _OrDivider(),
            const SizedBox(height: AppSpacing.lg),

            AppButton(
              secondary: true,
              label: _isLoginMode ? 'Log in with Google' : 'Sign up with Google',
              icon: Icons.account_circle_outlined,
              onPressed: isLoading ? null : () => _handleGoogleSignIn(authService),
            ),

            // Citizen only: skip sign-in and go straight to public health videos
            if (isCitizen) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                secondary: true,
                label: 'Skip and watch health videos',
                icon: Icons.ondemand_video_rounded,
                onPressed: isLoading ? null : _handleSkipForCitizen,
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            _ModeToggle(
              isLoginMode: _isLoginMode,
              onToggle: () => setState(() => _isLoginMode = !_isLoginMode),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Shows which role was chosen, as icon + words.
class _RoleLine extends StatelessWidget {
  final String roleName;

  const _RoleLine({required this.roleName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.badge_outlined, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Continuing as $roleName',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('or', style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isLoginMode;
  final VoidCallback onToggle;

  const _ModeToggle({required this.isLoginMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isLoginMode ? "Don't have an account?" : 'Already have an account?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: onToggle,
          child: Text(isLoginMode ? 'Sign up' : 'Log in'),
        ),
      ],
    );
  }
}
