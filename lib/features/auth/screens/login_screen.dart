import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/app_brand_logo.dart';
import '../../awareness_hub/screens/awareness_hub_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.asha;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Header & Branding
                  _buildBrandHeader(),
                  const SizedBox(height: 24),

                  // Role Selector
                  _buildRoleSelector(),
                  const SizedBox(height: 20),

                  // Quick Demo Accounts Bar (Crucial for testing all three roles easily!)
                  _buildDemoAccountsCard(authService),
                  const SizedBox(height: 20),

                  // Standard Email/Password Form
                  _buildLoginForm(authService),
                  const SizedBox(height: 20),

                  // Public Awareness Hub Entry (Accessible without login!)
                  _buildPublicAwarenessBanner(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const AppBrandLogo(
            iconSize: 68,
            isHorizontal: true,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.offline_bolt_rounded, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'ग्रामीण स्वास्थ्य सेतु • Offline-First Healthcare Platform',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildRoleTab(UserRole.asha, 'ASHA Worker', Icons.badge_outlined),
          _buildRoleTab(UserRole.doctor, 'Doctor', Icons.medical_services_outlined),
          _buildRoleTab(UserRole.patient, 'Villager', Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildRoleTab(UserRole role, String title, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccountsCard(AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              const Text(
                '1-Click Development & Demo Login',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.volume_up_outlined, size: 18, color: AppColors.primary),
                tooltip: 'Spoken guide for login',
                onPressed: () {
                  VoiceService().speakPrompt(
                    context,
                    title: 'लॉगिन सहायता / Login Help',
                    hindiText: 'डेमो बटन दबाकर तुरंत आशा कार्यकर्ता, डॉक्टर या ग्रामीण के रूप में शुरू करें।',
                    englishText: 'Tap any demo role button to instantly test without typing.',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Test the 3 isolated role-specific portals with pre-populated field records:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.roleAsha,
                    side: const BorderSide(color: AppColors.roleAsha),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: authService.isLoading
                      ? null
                      : () => authService.loginAsDemoAsha(),
                  child: const Column(
                    children: [
                      Text('ASHA Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Shanti Devi', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.roleDoctor,
                    side: const BorderSide(color: AppColors.roleDoctor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: authService.isLoading
                      ? null
                      : () => authService.loginAsDemoDoctor(),
                  child: const Column(
                    children: [
                      Text('Doctor Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Dr. Rajesh (PHC)', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rolePatient,
                    side: const BorderSide(color: AppColors.rolePatient),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: authService.isLoading
                      ? null
                      : () => authService.loginAsDemoPatient(),
                  child: const Column(
                    children: [
                      Text('Villager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Ramesh Kumar', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign in as ${_selectedRole.displayName}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Email Field
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address / मोबाइल नंबर',
              prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Password Field
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password / पिन',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          if (authService.authError != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.riskRedSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                authService.authError!,
                style: const TextStyle(color: AppColors.riskRed, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Submit Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: authService.isLoading
                ? null
                : () {
                    authService.signInWithEmailPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                      selectedRole: _selectedRole,
                    );
                  },
            child: authService.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Login to ${_selectedRole.displayName} Portal',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicAwarenessBanner() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.ondemand_video_rounded, color: Colors.white, size: 20),
        ),
        title: const Text(
          'Public Health Awareness Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
        ),
        subtitle: const Text(
          'Open health videos on Dengue, Summer safety & Nutrition (No Login Required)',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AwarenessHubScreen(isPublicAccess: true),
            ),
          );
        },
      ),
    );
  }
}
