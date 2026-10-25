import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_repository.dart';
import '../../../core/widgets/craft_background.dart';
import '../widgets/admin_ui.dart';
import 'admin_shell_screen.dart';

/// Entry point of the Admin Portal. There is a single administrator account,
/// so only the password is asked for (default: admin123, changeable inside).
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.trim().isEmpty) {
      setState(() => _error = 'Please enter the admin password.');
      return;
    }
    setState(() {
      _isBusy = true;
      _error = null;
    });
    final ok = await context.read<AdminRepository>().adminLogin(password);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (ok) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminShellScreen()));
    } else {
      setState(() => _error = 'Incorrect password. Please try again.');
    }
  }

  void _bypass() {
    context.read<AdminRepository>().adminBypassLogin();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminShellScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CraftBackground(
        pieces: const [
          CraftPiece(CraftMotif.neem, 0.4, right: -0.3, top: -0.12, turns: 0.12),
          CraftPiece(CraftMotif.kolam, 0.5, left: -0.4, bottom: -0.32),
        ],
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AdminColors.ink),
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
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: AdminColors.accent.withOpacity(0.35), width: 1.5),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded, size: 38, color: AdminColors.accent),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Admin Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AdminColors.ink, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'District Health Administrator access.\nManage ASHA workers, doctors, hospitals and Health Hub videos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: AdminColors.muted, height: 1.4),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Admin password',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.ink)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              autofocus: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: 'Enter admin password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                errorText: _error,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            AdminPrimaryButton(
                              label: 'Sign in as Admin',
                              icon: Icons.login_rounded,
                              isBusy: _isBusy,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: _isBusy ? null : _bypass,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AdminColors.accent,
                                  side: const BorderSide(color: AdminColors.accent, width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.flash_on_rounded, size: 18),
                                label: const Text('Quick Admin Bypass (no password)',
                                    style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: AppColors.textMuted),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Change the default password from Settings after signing in.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ),
                        ],
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
    );
  }
}
