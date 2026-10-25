import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/app_locale.dart';
import '../../../core/widgets/craft_background.dart';
import '../../shared/widgets/language_selector.dart';
import 'auth_screen.dart';
import '../../admin_portal/screens/admin_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final bool isLogin;

  const RoleSelectionScreen({
    super.key,
    this.isLogin = true,
  });

  void _onRoleSelected(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => AuthScreen(
          selectedRole: role,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppLocale>().t;
    return Scaffold(
      body: CraftBackground(
        pieces: const [
          CraftPiece(CraftMotif.kolam, 0.5, right: -0.42, bottom: -0.3),
          CraftPiece(CraftMotif.paisley, 0.38, left: -0.4, bottom: -0.25, turns: 0.5),
          CraftPiece(CraftMotif.sprig, 0.2, left: 0.3, bottom: 1.6),
        ],
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Nirogya Setu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.terraDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.paint,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.admin_panel_settings_outlined,
                                      size: 16,
                                      color: AppColors.neem,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      t('admin'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const LanguageSelector(dark: true),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Title & Subtitle
                  Text(
                    t('selectRole'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.terraDark,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('chooseRole'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // 2 Top Horizontal Cards + 1 Bottom Wide Card
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildCompactRoleCard(
                                  context: context,
                                  role: UserRole.asha,
                                  title: t('ashaWorker'),
                                  subtitle: t('ashaSub'),
                                  motif: CraftMotif.phulkari,
                                  accent: AppColors.neem,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildCompactRoleCard(
                                  context: context,
                                  role: UserRole.doctor,
                                  title: t('doctor'),
                                  subtitle: t('doctorSub'),
                                  motif: CraftMotif.sun,
                                  accent: AppColors.terra,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          _buildWideRoleCard(
                            context: context,
                            role: UserRole.patient,
                            title: t('citizen'),
                            subtitle: t('citizenSub'),
                            motif: CraftMotif.neem,
                          ),

                          const SizedBox(height: 120),
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

  Widget _arrowDisc(Color color, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.paint),
    );
  }

  Widget _buildCompactRoleCard({
    required BuildContext context,
    required UserRole role,
    required String title,
    required String subtitle,
    required CraftMotif motif,
    required Color accent,
  }) {
    return Material(
      color: AppColors.paint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onRoleSelected(context, role),
        child: Container(
          constraints: const BoxConstraints(minHeight: 210),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Image.asset('assets/images/motif_${motif.name}.png', width: 72, height: 72),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _arrowDisc(accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideRoleCard({
    required BuildContext context,
    required UserRole role,
    required String title,
    required String subtitle,
    required CraftMotif motif,
  }) {
    return Material(
      color: AppColors.neem,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onRoleSelected(context, role),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 66,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.paint, shape: BoxShape.circle),
                child: Image.asset('assets/images/motif_${motif.name}.png'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.paint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.paint.withOpacity(0.86),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _arrowDisc(AppColors.terra),
            ],
          ),
        ),
      ),
    );
  }
}
