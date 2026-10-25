import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/craft_background.dart';
import '../../../core/services/admin_repository.dart';
import '../widgets/admin_ui.dart';
import 'admin_change_password_screen.dart';
import 'asha/admin_asha_tab.dart';
import 'asha/asha_form_screen.dart';
import 'doctor/admin_doctor_tab.dart';
import 'doctor/doctor_form_screen.dart';
import 'hospital/admin_hospital_tab.dart';
import 'overview/admin_overview_tab.dart';
import 'videos/manage_videos_screen.dart';

/// Admin Portal home: Overview, ASHA Worker, [+], Doctor, Hospital.
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _tabIndex = 0;
  bool _quickMenuOpen = false;

  static const _tabTitles = ['Overview', 'ASHA Workers', 'Doctors', 'Hospitals'];

  void _selectTab(int index) {
    setState(() {
      _tabIndex = index;
      _quickMenuOpen = false;
    });
  }

  Future<void> _signOut() async {
    final confirmed = await showAdminConfirm(
      context,
      title: 'Sign out of Admin Portal?',
      message: 'You will need the admin password to sign in again.',
      confirmLabel: 'Sign Out',
    );
    if (!confirmed || !mounted) return;
    context.read<AdminRepository>().adminLogout();
    Navigator.pop(context);
  }

  Future<void> _openQuickAction(_QuickAction action) async {
    setState(() => _quickMenuOpen = false);
    final repo = context.read<AdminRepository>();
    switch (action) {
      case _QuickAction.addAsha:
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AshaFormScreen()));
        break;
      case _QuickAction.addDoctor:
        if (repo.hospitals.isEmpty) {
          showAdminSnack(context, 'Add a hospital first. Every doctor must be linked to a hospital.', isError: true);
          _selectTab(3);
          return;
        }
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorFormScreen()));
        break;
      case _QuickAction.manageVideos:
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageVideosScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AdminRepository>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_quickMenuOpen) {
          setState(() => _quickMenuOpen = false);
        } else {
          _signOut();
        }
      },
      child: Scaffold(
        backgroundColor: AdminColors.background,
        appBar: _buildAppBar(repo),
        body: Stack(
          children: [
            IndexedStack(
              index: _tabIndex,
              children: [
                AdminOverviewTab(onOpenTab: _selectTab),
                const AdminAshaTab(),
                AdminDoctorTab(onOpenHospitals: () => _selectTab(3)),
                const AdminHospitalTab(),
              ],
            ),
            if (_quickMenuOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _quickMenuOpen = false),
                  child: Container(color: const Color(0xFF33200F).withOpacity(0.35)),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(child: _QuickActionMenu(onSelect: _openQuickAction)),
              ),
            ],
          ],
        ),
        bottomNavigationBar: _AdminBottomBar(
          currentIndex: _tabIndex,
          quickMenuOpen: _quickMenuOpen,
          onSelect: _selectTab,
          onPlus: () => setState(() => _quickMenuOpen = !_quickMenuOpen),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AdminRepository repo) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.neem,
      foregroundColor: AppColors.paint,
      flexibleSpace: const CraftHeaderStitch(),
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          AdminIconBadge(
            icon: Icons.admin_panel_settings_rounded,
            color: AppColors.haldi,
            surface: AppColors.paint.withOpacity(0.16),
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin Portal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.paint)),
                Text(_tabTitles[_tabIndex],
                    style: const TextStyle(fontSize: 11, color: Color(0xFFE4E6CC), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: repo.isSyncing ? 'Syncing…' : 'Sync with cloud',
          onPressed: repo.isSyncing ? null : () => repo.syncWithCloud(),
          icon: repo.isSyncing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Badge(
                  isLabelVisible: repo.pendingSyncCount > 0,
                  label: Text('${repo.pendingSyncCount}'),
                  child: const Icon(Icons.cloud_sync_outlined, color: AppColors.paint),
                ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined, color: AppColors.paint),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: AppColors.paint,
          onSelected: (value) {
            if (value == 'password') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminChangePasswordScreen()));
            } else if (value == 'signout') {
              _signOut();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'password',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.lock_reset_rounded, color: AdminColors.accent),
                title: Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
            PopupMenuItem(
              value: 'signout',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout_rounded, color: Color(0xFFB23A22)),
                title: Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

enum _QuickAction { addAsha, addDoctor, manageVideos }

class _QuickActionMenu extends StatelessWidget {
  final ValueChanged<_QuickAction> onSelect;

  const _QuickActionMenu({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: Container(
        width: 290,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFFFBF4E8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QuickActionTile(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Add ASHA Worker',
              subtitle: 'Register a new field health worker',
              color: AdminColors.asha,
              surface: AdminColors.ashaSurface,
              onTap: () => onSelect(_QuickAction.addAsha),
            ),
            _QuickActionTile(
              icon: Icons.medical_services_rounded,
              title: 'Add Doctor',
              subtitle: 'Register a doctor at a hospital',
              color: AdminColors.doctor,
              surface: AdminColors.doctorSurface,
              onTap: () => onSelect(_QuickAction.addDoctor),
            ),
            _QuickActionTile(
              icon: Icons.video_library_rounded,
              title: 'Manage Videos',
              subtitle: 'Health Hub videos & languages',
              color: AdminColors.video,
              surface: AdminColors.videoSurface,
              onTap: () => onSelect(_QuickAction.manageVideos),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            AdminIconBadge(icon: icon, color: color, surface: surface, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AdminColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AdminColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AdminColors.muted),
          ],
        ),
      ),
    );
  }
}

class _AdminBottomBar extends StatelessWidget {
  final int currentIndex;
  final bool quickMenuOpen;
  final ValueChanged<int> onSelect;
  final VoidCallback onPlus;

  const _AdminBottomBar({
    required this.currentIndex,
    required this.quickMenuOpen,
    required this.onSelect,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CraftNavTheme.background,
        border: Border(top: BorderSide(color: AppColors.neemDark, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Overview',
                selected: currentIndex == 0,
                onTap: () => onSelect(0),
              ),
              _NavItem(
                icon: Icons.health_and_safety_outlined,
                activeIcon: Icons.health_and_safety_rounded,
                label: 'ASHA Worker',
                selected: currentIndex == 1,
                onTap: () => onSelect(1),
              ),
              Expanded(
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Quick actions',
                    child: GestureDetector(
                      onTap: onPlus,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: quickMenuOpen
                                ? const [Color(0xFF4A3626), Color(0xFF33200F)]
                                : const [AppColors.terra, AppColors.terraDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.terraDark.withOpacity(0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AnimatedRotation(
                          turns: quickMenuOpen ? 0.125 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.medical_services_outlined,
                activeIcon: Icons.medical_services_rounded,
                label: 'Doctor',
                selected: currentIndex == 2,
                onTap: () => onSelect(2),
              ),
              _NavItem(
                icon: Icons.local_hospital_outlined,
                activeIcon: Icons.local_hospital_rounded,
                label: 'Hospital',
                selected: currentIndex == 3,
                onTap: () => onSelect(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? CraftNavTheme.selected : CraftNavTheme.unselected;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: selected ? 11 : 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
