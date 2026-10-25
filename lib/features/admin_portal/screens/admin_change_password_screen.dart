import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/admin_repository.dart';
import '../widgets/admin_ui.dart';

class AdminChangePasswordScreen extends StatefulWidget {
  const AdminChangePasswordScreen({super.key});

  @override
  State<AdminChangePasswordScreen> createState() => _AdminChangePasswordScreenState();
}

class _AdminChangePasswordScreenState extends State<AdminChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _newController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isBusy = true;
      _error = null;
    });
    final error = await context.read<AdminRepository>().changeAdminPassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
          confirmPassword: _confirmController.text,
        );
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    showAdminSnack(context, 'Admin password updated. Use the new password next time you sign in.');
    Navigator.pop(context);
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return AdminField(
      child: TextField(
        controller: controller,
        obscureText: !visible,
        decoration: adminInput(label, icon: Icons.lock_outline_rounded).copyWith(
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Widget _rule(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 16, color: met ? const Color(0xFF3B6634) : AdminColors.muted),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12.5, color: met ? AdminColors.ink : AdminColors.muted)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final next = _newController.text.trim();
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B6634),
        foregroundColor: const Color(0xFFFBF4E8),
        title: const Text('Change Admin Password', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminFormSection(
              title: 'Verify it\'s you',
              icon: Icons.verified_user_outlined,
              children: [
                _passwordField(
                  controller: _currentController,
                  label: 'Current password',
                  visible: _showCurrent,
                  onToggle: () => setState(() => _showCurrent = !_showCurrent),
                ),
              ],
            ),
            AdminFormSection(
              title: 'New password',
              icon: Icons.password_rounded,
              children: [
                _passwordField(
                  controller: _newController,
                  label: 'New password',
                  visible: _showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                ),
                _passwordField(
                  controller: _confirmController,
                  label: 'Confirm new password',
                  visible: _showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                ),
                _rule('At least 6 characters', next.length >= 6),
                _rule('Contains letters and numbers',
                    RegExp(r'[A-Za-z]').hasMatch(next) && RegExp(r'[0-9]').hasMatch(next)),
                const SizedBox(height: 8),
              ],
            ),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4D6C8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF4D6C8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFB23A22), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFF8A2B18))),
                    ),
                  ],
                ),
              ),
            AdminPrimaryButton(label: 'Update Password', icon: Icons.check_rounded, isBusy: _isBusy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
