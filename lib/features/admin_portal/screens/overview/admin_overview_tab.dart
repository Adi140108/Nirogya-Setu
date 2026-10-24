import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/screening_rules.dart';
import '../../../../core/models/referral_model.dart';
import '../../../../core/services/admin_repository.dart';
import '../../../../core/services/health_repository.dart';
import '../../widgets/admin_ui.dart';
import '../videos/manage_videos_screen.dart';

class AdminOverviewTab extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const AdminOverviewTab({super.key, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminRepository>();
    final health = context.watch<HealthRepository>();

    final asha = admin.ashaWorkers;
    final doctors = admin.doctors;
    final hospitals = admin.hospitals;
    final videos = admin.videos;

    final activeAsha = asha.where((a) => a.isActive).length;
    final activeDoctors = doctors.where((d) => d.isActive).length;
    final totalBeds = hospitals.fold<int>(0, (sum, h) => sum + h.totalBeds);
    final availableBeds = hospitals.fold<int>(0, (sum, h) => sum + h.availableBeds);
    final icuBeds = hospitals.fold<int>(0, (sum, h) => sum + h.icuBeds);
    final languages = admin.availableVideoLanguages.length;

    final screenings = health.screenings;
    final red = screenings.where((s) => s.priority == HealthPriority.red).length;
    final yellow = screenings.where((s) => s.priority == HealthPriority.yellow).length;
    final green = screenings.where((s) => s.priority == HealthPriority.green).length;
    final openReferrals = health.referrals
        .where((r) => r.status == ReferralStatus.pending || r.status == ReferralStatus.underReview)
        .length;
    final pregnant = health.patients.where((p) => p.isPregnant).length;
    final villages = health.patients.map((p) => p.villageId).toSet().length;
    final unassignedVillagers =
        health.patients.where((p) => admin.ashaById(p.ashaId) == null).length;

    return RefreshIndicator(
      onRefresh: () => admin.syncWithCloud(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _WelcomeCard(admin: admin),
          const SizedBox(height: 16),
          const AdminSectionTitle(title: 'System at a glance'),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 146,
            ),
            children: [
              _tap(
                () => onOpenTab(1),
                AdminStatTile(
                  label: 'ASHA Workers',
                  value: '${asha.length}',
                  caption: '$activeAsha active',
                  icon: Icons.health_and_safety_rounded,
                  color: AdminColors.asha,
                  surface: AdminColors.ashaSurface,
                ),
              ),
              _tap(
                () => onOpenTab(2),
                AdminStatTile(
                  label: 'Doctors',
                  value: '${doctors.length}',
                  caption: '$activeDoctors active',
                  icon: Icons.medical_services_rounded,
                  color: AdminColors.doctor,
                  surface: AdminColors.doctorSurface,
                ),
              ),
              _tap(
                () => onOpenTab(3),
                AdminStatTile(
                  label: 'Hospitals',
                  value: '${hospitals.length}',
                  caption: '$availableBeds of $totalBeds beds free',
                  icon: Icons.local_hospital_rounded,
                  color: AdminColors.hospital,
                  surface: AdminColors.hospitalSurface,
                ),
              ),
              AdminStatTile(
                label: 'Villagers Registered',
                value: '${health.patients.length}',
                caption: 'across $villages village(s)',
                icon: Icons.groups_rounded,
                color: AdminColors.citizen,
                surface: AdminColors.citizenSurface,
              ),
              AdminStatTile(
                label: 'Health Screenings',
                value: '${screenings.length}',
                caption: '$red high-risk',
                icon: Icons.monitor_heart_rounded,
                color: AppColors.riskRed,
                surface: AppColors.riskRedSurface,
              ),
              AdminStatTile(
                label: 'Open Referrals',
                value: '$openReferrals',
                caption: '${health.referrals.length} total referrals',
                icon: Icons.assignment_late_rounded,
                color: AppColors.riskYellow,
                surface: AppColors.riskYellowSurface,
              ),
              AdminStatTile(
                label: 'ICU Beds',
                value: '$icuBeds',
                caption: 'across all hospitals',
                icon: Icons.bed_rounded,
                color: AdminColors.accent,
                surface: AdminColors.accentSurface,
              ),
              _tap(
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageVideosScreen())),
                AdminStatTile(
                  label: 'Health Hub Videos',
                  value: '${videos.length}',
                  caption: '$languages language(s)',
                  icon: Icons.video_library_rounded,
                  color: AdminColors.video,
                  surface: AdminColors.videoSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const AdminSectionTitle(title: 'Community health risk'),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RiskBar(red: red, yellow: yellow, green: green),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _legend(AppColors.riskRed, 'High risk', red),
                    _legend(AppColors.riskYellow, 'Moderate', yellow),
                    _legend(AppColors.riskGreen, 'Low risk', green),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.pregnant_woman_rounded, size: 18, color: AdminColors.doctor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('$pregnant pregnant women under ANC tracking',
                          style: const TextStyle(fontSize: 12.5, color: AdminColors.ink, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                if (unassignedVillagers > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_off_outlined, size: 18, color: AppColors.riskYellow),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('$unassignedVillagers villager(s) not linked to an active ASHA record',
                            style: const TextStyle(fontSize: 12.5, color: AdminColors.ink, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          AdminSectionTitle(title: 'Hospital bed availability', trailing: 'View all', onTrailingTap: () => onOpenTab(3)),
          if (hospitals.isEmpty)
            const AdminCard(
              child: Text('No hospitals added yet. Add one from the Hospital tab.',
                  style: TextStyle(fontSize: 13, color: AdminColors.muted)),
            )
          else
            AdminCard(
              child: Column(
                children: [
                  for (final h in hospitals.take(5)) _BedRow(name: h.name, available: h.availableBeds, total: h.totalBeds),
                ],
              ),
            ),
          const SizedBox(height: 18),
          const AdminSectionTitle(title: 'Recently added'),
          _RecentActivity(admin: admin),
        ],
      ),
    );
  }

  Widget _tap(VoidCallback onTap, Widget child) => GestureDetector(onTap: onTap, child: child);

  Widget _legend(Color color, String label, int count) {
    return Expanded(
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
            child: Text('$label ($count)',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: AdminColors.muted, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final AdminRepository admin;

  const _WelcomeCard({required this.admin});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final lastSync = admin.lastSyncTimestamp;
    final pending = admin.pendingSyncCount;
    final String syncLine;
    if (admin.isSyncing) {
      syncLine = 'Syncing with cloud database…';
    } else if (admin.lastSyncError != null) {
      syncLine = admin.lastSyncError!;
    } else if (lastSync != null) {
      syncLine = 'Cloud synced at ${DateFormat('hh:mm a').format(lastSync)}'
          '${pending > 0 ? ' • $pending pending' : ''}';
    } else {
      syncLine = pending > 0 ? '$pending change(s) waiting to sync' : 'Saved on this device';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_greeting, Administrator',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(fontSize: 12.5, color: Color(0xFFB2DFDB))),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  admin.lastSyncError != null ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(syncLine,
                      style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskBar extends StatelessWidget {
  final int red;
  final int yellow;
  final int green;

  const _RiskBar({required this.red, required this.yellow, required this.green});

  @override
  Widget build(BuildContext context) {
    final total = red + yellow + green;
    if (total == 0) {
      return const Text('No screenings recorded yet.', style: TextStyle(fontSize: 13, color: AdminColors.muted));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            if (red > 0) Expanded(flex: red, child: Container(color: AppColors.riskRed)),
            if (yellow > 0) Expanded(flex: yellow, child: Container(color: AppColors.riskYellow)),
            if (green > 0) Expanded(flex: green, child: Container(color: AppColors.riskGreen)),
          ],
        ),
      ),
    );
  }
}

class _BedRow extends StatelessWidget {
  final String name;
  final int available;
  final int total;

  const _BedRow({required this.name, required this.available, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (available / total).clamp(0.0, 1.0) : 0.0;
    final color = ratio < 0.15 ? AppColors.riskRed : (ratio < 0.4 ? AppColors.riskYellow : AppColors.riskGreen);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.ink)),
              ),
              Text('$available / $total free',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: AdminColors.background,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final AdminRepository admin;

  const _RecentActivity({required this.admin});

  @override
  Widget build(BuildContext context) {
    final items = <_ActivityItem>[
      for (final a in admin.ashaWorkers)
        _ActivityItem('ASHA worker • ${a.villageName}', a.fullName, a.createdAt, Icons.health_and_safety_rounded,
            AdminColors.asha, AdminColors.ashaSurface),
      for (final d in admin.doctors)
        _ActivityItem('Doctor • ${d.specialization}', d.fullName, d.createdAt, Icons.medical_services_rounded,
            AdminColors.doctor, AdminColors.doctorSurface),
      for (final h in admin.hospitals)
        _ActivityItem('Hospital • ${h.villageTown}', h.name, h.createdAt, Icons.local_hospital_rounded,
            AdminColors.hospital, AdminColors.hospitalSurface),
      for (final v in admin.videos)
        _ActivityItem('Video • ${v.languages.join(', ')}', v.variants.first.title, v.createdAt,
            Icons.video_library_rounded, AdminColors.video, AdminColors.videoSurface),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (items.isEmpty) {
      return const AdminCard(
        child: Text('Nothing added yet.', style: TextStyle(fontSize: 13, color: AdminColors.muted)),
      );
    }

    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          for (final item in items.take(6))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  AdminIconBadge(icon: item.icon, color: item.color, surface: item.surface, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.ink)),
                        Text(item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: AdminColors.muted)),
                      ],
                    ),
                  ),
                  Text(DateFormat('dd MMM').format(item.date),
                      style: const TextStyle(fontSize: 11, color: AdminColors.muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String subtitle;
  final String title;
  final DateTime date;
  final IconData icon;
  final Color color;
  final Color surface;

  _ActivityItem(this.subtitle, this.title, this.date, this.icon, this.color, this.surface);
}
