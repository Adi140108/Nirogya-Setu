import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../awareness_hub/screens/awareness_hub_screen.dart';
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

  void _handleSkipForVillager() {
    // As explicitly specified: "skip which then shows only videos for villagers"
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
    final isVillager = widget.selectedRole == UserRole.patient;

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
                      // Header Logo & Title (matching Image 2)
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
                            Text(
                              _isLoginMode ? 'WELCOME BACK' : 'CREATE ACCOUNT',
                              style: const TextStyle(
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

                      const SizedBox(height: 28),

                      // Input Fields (with light tint as in Image 2)
                      if (!_isLoginMode) ...[
                        _buildInputField(
                          label: 'Full Name',
                          hint: 'John Doe',
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildInputField(
                        label: 'Email / Phone',
                        hint: 'name@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      _buildInputField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passwordController,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      const SizedBox(height: 24),

                      // Primary Button (Sign Up or Log In)
                      ElevatedButton(
                        onPressed: authService.isLoading
                            ? null
                            : () => _handlePrimarySubmit(authService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5), // Vibrant blue
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
                            : Text(
                                _isLoginMode ? 'Log In' : 'Sign Up',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),

                      const SizedBox(height: 20),

                      // Divider "OR"
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.black.withOpacity(0.15))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B).withOpacity(0.8),
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.black.withOpacity(0.15))),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Sign in with Google Button (Clean white card matching Image 2)
                      ElevatedButton(
                        onPressed: authService.isLoading
                            ? null
                            : () => _handleGoogleSignIn(authService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.08),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withOpacity(0.9)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Clean Google 'G' icon
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4285F4),
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isLoginMode ? 'Sign In with Google' : 'Sign Up with Google',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // VILLAGER ONLY: Skip to videos button
                      if (isVillager) ...[
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: _handleSkipForVillager,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.4),
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

                      // Toggle between Log In and Sign Up
                      Center(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLoginMode = !_isLoginMode),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                              children: [
                                TextSpan(
                                  text: _isLoginMode
                                      ? "Don't have an account? "
                                      : 'Already have an account? ',
                                ),
                                TextSpan(
                                  text: _isLoginMode ? 'Sign Up' : 'Log In',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
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
            color: const Color(0xFFBCE3F5).withOpacity(0.55), // Light blue tint matching Image 2
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
              hintText: hint,
              hintStyle: TextStyle(
                color: const Color(0xFF64748B).withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
