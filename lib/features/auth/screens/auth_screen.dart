import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/app_locale.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/widgets/craft_background.dart';
import '../../awareness_hub/screens/citizen_health_hub_screen.dart';
import '../../../main.dart';

class AuthScreen extends StatefulWidget {
  final UserRole selectedRole;
  final bool isLogin;

  const AuthScreen({
    super.key,
    required this.selectedRole,
    this.isLogin = true,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _routeToDashboard() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootGateScreen()),
      (route) => false,
    );
  }

  Future<void> _handlePrimarySubmit(AuthService authService, HealthRepository healthRepo) async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.riskRed,
          content: Text('Please enter both phone number and password, or use Quick Bypass below.'),
        ),
      );
      return;
    }

    final success = await authService.signInWithPhonePassword(
      phoneNumber: phone,
      password: password,
      selectedRole: widget.selectedRole,
      registeredPatients: healthRepo.patients,
    );

    if (success && mounted) {
      _routeToDashboard();
    } else if (mounted && authService.authError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.riskRed,
          content: Text(authService.authError!),
        ),
      );
    }
  }

  Future<void> _handleBypass(AuthService authService) async {
    // Direct bypass for fast testing and evaluation
    await authService.bypassLoginAsRole(
      widget.selectedRole,
      phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    );
    if (mounted) {
      _routeToDashboard();
    }
  }

  void _handleSkipForCitizen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CitizenHealthHubScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final healthRepo = context.watch<HealthRepository>();
    final isCitizen = widget.selectedRole == UserRole.patient;
    final accent = isCitizen ? AppColors.neem : AppColors.terra;

    return Scaffold(
      body: CraftBackground(
        pieces: const [
          CraftPiece(CraftMotif.phulkari, 0.34, right: -0.32, top: -0.2),
          CraftPiece(CraftMotif.sprig, 0.2, left: -0.1, bottom: 0.2),
        ],
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  // Top Bar with Back Arrow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Logo & Title
                          Center(
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/logo_icon.png',
                                  width: 76,
                                  height: 76,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 12),
                                const NirogyaWordmark(size: 32),
                                const SizedBox(height: 12),
                                Text(
                                  context.watch<AppLocale>().t('portalLogin').toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 2.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Role Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Role: ${widget.selectedRole.displayName}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.paint,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Role Information Notice Box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.paint,
                              borderRadius: BorderRadius.circular(16),
                              border: Border(left: BorderSide(color: accent, width: 4)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isCitizen ? Icons.key_rounded : Icons.admin_panel_settings_outlined,
                                  size: 20,
                                  color: accent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isCitizen
                                        ? 'Log in using your registered mobile number and password assigned by your ASHA worker during registration.'
                                        : 'Account credentials are created and managed by the District Health Administrator. Passwords will be provisioned by Admin in the admin portal.',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Input Fields
                          _buildInputField(
                            label: context.watch<AppLocale>().t('mobileNumber'),
                            hint: 'e.g. +91 98765 43210',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_android_rounded,
                          ),
                          const SizedBox(height: 16),

                          _buildInputField(
                            label: context.watch<AppLocale>().t('password'),
                            hint: '••••••••',
                            controller: _passwordController,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            prefixIcon: Icons.lock_outline_rounded,
                            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(height: 26),

                          // Primary Button (Log In)
                          CraftPillButton(
                            label: context.watch<AppLocale>().t('login'),
                            busy: authService.isLoading,
                            onPressed: authService.isLoading
                                ? null
                                : () => _handlePrimarySubmit(authService, healthRepo),
                          ),

                          const SizedBox(height: 14),

                          // Quick Bypass Button for Testing
                          OutlinedButton.icon(
                            onPressed: authService.isLoading ? null : () => _handleBypass(authService),
                            icon: const Icon(Icons.bolt_rounded, size: 20, color: AppColors.terra),
                            label: Text(
                              'Quick Bypass Login (${widget.selectedRole.displayName})',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.paint,
                              side: const BorderSide(color: AppColors.terra, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const StadiumBorder(),
                            ),
                          ),

                          // CITIZEN ONLY: Skip to videos button
                          if (isCitizen) ...[
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: _handleSkipForCitizen,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.neem,
                                side: const BorderSide(color: AppColors.neem, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: const StadiumBorder(),
                                backgroundColor: AppColors.paint,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.ondemand_video_rounded, size: 20, color: AppColors.neem),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.watch<AppLocale>().t('skipWatch'),
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),
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
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword ? obscureText : false,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.paint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20) : null,
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.neem, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
