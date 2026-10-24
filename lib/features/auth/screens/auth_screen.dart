import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';
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
          backgroundColor: Color(0xFFDC2626),
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
          backgroundColor: const Color(0xFFDC2626),
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

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE5F7EE),
              Color(0xFFE0F3F8),
              Color(0xFFCCE8FE),
              Color(0xFFBADDF8),
            ],
            stops: [0.0, 0.35, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Back Arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo & Title
                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/logo_icon.png',
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 10),
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Roboto',
                                      letterSpacing: -0.4,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Aarogya ',
                                        style: TextStyle(color: Color(0xFF0F766E)),
                                      ),
                                      TextSpan(
                                        text: 'Setu',
                                        style: TextStyle(color: Color(0xFFEA580C)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'PORTAL LOGIN',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF475569),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white),
                              ),
                              child: Text(
                                'Role: ${widget.selectedRole.displayName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
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
                          color: Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.selectedRole == UserRole.patient
                                ? const Color(0xFF0F766E).withOpacity(0.25)
                                : const Color(0xFF0284C7).withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              widget.selectedRole == UserRole.patient
                                  ? Icons.key_rounded
                                  : Icons.admin_panel_settings_outlined,
                              size: 20,
                              color: widget.selectedRole == UserRole.patient
                                  ? const Color(0xFF0F766E)
                                  : const Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.selectedRole == UserRole.patient
                                    ? 'Log in using your registered mobile number and password assigned by your ASHA worker during registration.'
                                    : 'Account credentials are created and managed by the District Health Administrator. Passwords will be provisioned by Admin in the admin portal.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF334155),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Input Fields
                      _buildInputField(
                        label: 'Mobile Number',
                        hint: 'e.g. +91 98765 43210',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_rounded,
                      ),
                      const SizedBox(height: 16),

                      _buildInputField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passwordController,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      const SizedBox(height: 24),

                      // Primary Button (Log In)
                      ElevatedButton(
                        onPressed: authService.isLoading
                            ? null
                            : () => _handlePrimarySubmit(authService, healthRepo),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFF1E88E5).withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: authService.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),

                      const SizedBox(height: 14),

                      // Quick Bypass Button for Testing
                      OutlinedButton.icon(
                        onPressed: authService.isLoading ? null : () => _handleBypass(authService),
                        icon: const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFEA580C)),
                        label: Text(
                          '⚡ Quick Bypass Login (${widget.selectedRole.displayName})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.85),
                          side: const BorderSide(color: Color(0xFFEA580C), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),

                      // CITIZEN ONLY: Skip to videos button
                      if (isCitizen) ...[
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: _handleSkipForCitizen,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.5),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.ondemand_video_rounded, size: 20, color: Color(0xFF0F766E)),
                              SizedBox(width: 8),
                              Text(
                                'Skip → Watch Health Videos',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFBCE3F5).withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword ? obscureText : false,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: const Color(0xFF475569), size: 20)
                  : null,
              hintText: hint,
              hintStyle: TextStyle(
                color: const Color(0xFF64748B).withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: onTogglePassword,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
