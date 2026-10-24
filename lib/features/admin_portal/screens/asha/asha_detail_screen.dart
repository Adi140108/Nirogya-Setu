import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/screening_rules.dart';
import '../../../../core/models/patient_model.dart';
import '../../../../core/services/admin_repository.dart';
import '../../../../core/services/health_repository.dart';
import '../../widgets/admin_ui.dart';
import 'asha_form_screen.dart';

class AshaDetailScreen extends StatelessWidget {
  final String ashaId;

  const AshaDetailScreen({super.key, required this.ashaId});

  Future<void> _resetPassword(BuildContext context, AdminRepository repo) async {
    final worker = repo.ashaById(ashaId);
    if (worker == null) return;
    final confirmed = await showAdminConfirm(
      context,
      title: 'Reset password?',
      message: '${worker.fullName} will no longer be able to sign in with the old password.',
      confirmLabel: 'Reset',
    );
    if (!confirmed || !context.mounted) return;
    final password = await repo.resetAshaPassword(ashaId);
    if (!context.mounted) return;
    await showCredentialsDialog(
      context,
      title: 'New password issued',
      name: worker.fullName,
      mobile: AdminRepository.formatMobile(worker.mobileNumber),
      password: password,
      color: AdminColors.asha,
    );
  }

  Future<void> _toggleActive(BuildContext context, AdminRepository repo, bool active) async {
    final worker = repo.ashaById(ashaId);
    if (worker == null) return;
    final confirmed = await showAdminConfirm(
      context,
      title: active ? 'Deactivate account?' : 'Activate account?',
      message: active
          ? '${worker.fullName} will not be able to sign in until the account is activated again. Their villager records stay intact.'
          : '${worker.fullName} will be able to sign in again.',
      confirmLabel: active ? 'Deactivate' : 'Activate',
      destructive: active,
    );
    if (!confirmed || !context.mounted) return;
    await repo.setAshaActive(ashaId, !active);
    if (context.mounted) showAdminSnack(context, active ? 'Account deactivated' : 'Account activated');
  }

  Future<void> _delete(BuildContext context, AdminRepository repo, int villagerCount) async {
    final worker = repo.ashaById(ashaId);
    if (worker == null) return;
    final confirmed = await showAdminConfirm(
      context,
      title: 'Delete ${worker.fullName}?',
      message: villagerCount > 0
          ? 'This removes the ASHA worker and their login. The $villagerCount villager record(s) they registered are kept and will show as unassigned.'
          : 'This removes the ASHA worker and their login access.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await repo.deleteAshaWorker(ashaId);
    if (!context.mounted) return;
    showAdminSnack(context, 'ASHA worker deleted');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AdminRepository>();
    final health = context.watch<HealthRepository>();
    final worker = repo.ashaById(ashaId);

    if (worker == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, foregroundColor: AdminColors.ink),
        body: const AdminEmptyState(
          icon: Icons.person_off_outlined,
          title: 'ASHA worker not found',
          message: 'This record may have been deleted.',
        ),
      );
    }

    final hospital = repo.hospitalById(worker.hospitalId);
    final villagers = AdminRepository.villagersForAsha(worker.id, health.patients);
    final screenings = health.screenings.where((s) => s.ashaId == worker.id).length;
    final households = villagers.map((v) => v.householdId ?? v.id).toSet().length;

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AdminColors.ink,
        title: const Text('ASHA Worker Profile', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Edit details',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AshaFormScreen(existing: worker)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          AdminCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const AdminIconBadge(
                      icon: Icons.health_and_safety_rounded,
                      color: AdminColors.asha,
                      surface: AdminColors.ashaSurface,
                      size: 56,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(worker.fullName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminColors.ink)),
                          const SizedBox(height: 2),
                          Text('${worker.ashaIdNumber} • ${worker.villageName}',
                              style: const TextStyle(fontSize: 12.5, color: AdminColors.muted)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            AdminActiveChip(isActive: worker.isActive),
                            AdminSyncChip(status: worker.syncStatus),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _miniStat('${villagers.length}', 'Villagers'),
                    _miniStat('$households', 'Households'),
                    _miniStat('$screenings', 'Screenings'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AdminSectionTitle(title: 'Login credentials'),
          AdminCard(
            child: Column(
              children: [
                AdminInfoRow(
                  icon: Icons.call_outlined,
                  label: 'Mobile number',
                  value: AdminRepository.formatMobile(worker.mobileNumber),
                ),
                AdminPasswordRow(password: worker.password),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _resetPassword(context, repo),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.accent,
                      side: const BorderSide(color: AdminColors.accent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.lock_reset_rounded, size: 18),
                    label: const Text('Reset password', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AdminSectionTitle(title: 'Details'),
          AdminCard(
            child: Column(
              children: [
                AdminInfoRow(icon: Icons.cake_outlined, label: 'Age / Gender', value: '${worker.age} yrs • ${worker.gender}'),
                AdminInfoRow(icon: Icons.school_outlined, label: 'Education', value: worker.education),
                AdminInfoRow(icon: Icons.location_on_outlined, label: 'Village', value: worker.villageName),
                AdminInfoRow(icon: Icons.location_city_outlined, label: 'District', value: worker.district),
                AdminInfoRow(icon: Icons.map_outlined, label: 'State', value: worker.state),
                AdminInfoRow(
                  icon: Icons.local_hospital_outlined,
                  label: 'Hospital',
                  value: hospital != null ? '${hospital.name}, ${hospital.villageTown}' : 'Not linked',
                ),
                AdminInfoRow(
                  icon: Icons.event_outlined,
                  label: 'Joined on',
                  value: worker.joiningDate != null ? DateFormat('dd MMM yyyy').format(worker.joiningDate!) : '',
                ),
                AdminInfoRow(icon: Icons.home_outlined, label: 'Address', value: worker.address),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AdminSectionTitle(title: 'Linked villagers (${villagers.length})'),
          if (villagers.isEmpty)
            const AdminCard(
              child: Text(
                'No villagers registered yet. Villagers appear here once this ASHA worker registers them in the field.',
                style: TextStyle(fontSize: 13, color: AdminColors.muted, height: 1.35),
              ),
            )
          else
            AdminCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                children: [
                  for (final v in villagers) _VillagerTile(villager: v, health: health),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleActive(context, repo, worker.isActive),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: worker.isActive ? AppColors.riskYellow : AppColors.riskGreen,
                    side: BorderSide(color: worker.isActive ? AppColors.riskYellow : AppColors.riskGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(worker.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 18),
                  label: Text(worker.isActive ? 'Deactivate' : 'Activate',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _delete(context, repo, villagers.length),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.riskRed,
                    side: const BorderSide(color: AppColors.riskRed),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AdminColors.background, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminColors.ink)),
            Text(label, style: const TextStyle(fontSize: 11, color: AdminColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _VillagerTile extends StatelessWidget {
  final PatientModel villager;
  final HealthRepository health;

  const _VillagerTile({required this.villager, required this.health});

  @override
  Widget build(BuildContext context) {
    final screenings = health.getScreeningsForPatient(villager.id);
    final latest = screenings.isEmpty ? null : (screenings..sort((a, b) => b.createdAt.compareTo(a.createdAt))).first;
    final riskColor = latest == null
        ? AdminColors.muted
        : latest.priority == HealthPriority.red
            ? AppColors.riskRed
            : latest.priority == HealthPriority.yellow
                ? AppColors.riskYellow
                : AppColors.riskGreen;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(
        backgroundColor: AdminColors.citizenSurface,
        child: Text(villager.fullName.isNotEmpty ? villager.fullName[0].toUpperCase() : '?',
            style: const TextStyle(color: AdminColors.citizen, fontWeight: FontWeight.w900)),
      ),
      title: Text(villager.fullName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AdminColors.ink)),
      subtitle: Text(
        '${villager.age} yrs • ${villager.gender} • ${villager.villageName}'
        '${villager.householdId != null ? ' • ${villager.householdId}' : ''}',
        style: const TextStyle(fontSize: 12, color: AdminColors.muted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (villager.isPregnant) const Icon(Icons.pregnant_woman_rounded, size: 18, color: AdminColors.doctor),
          const SizedBox(width: 4),
          Container(width: 10, height: 10, decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle)),
        ],
      ),
      onTap: () => _showVillager(context, latest?.categoryTitle, screenings.length),
    );
  }

  void _showVillager(BuildContext context, String? latestRisk, int screeningCount) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AdminColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(villager.fullName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminColors.ink)),
              const SizedBox(height: 10),
              AdminInfoRow(icon: Icons.cake_outlined, label: 'Age / Gender', value: '${villager.age} yrs • ${villager.gender}'),
              AdminInfoRow(icon: Icons.call_outlined, label: 'Contact', value: villager.contactNumber),
              AdminInfoRow(icon: Icons.location_on_outlined, label: 'Village', value: villager.villageName),
              AdminInfoRow(icon: Icons.house_outlined, label: 'Household', value: villager.householdId ?? ''),
              AdminInfoRow(icon: Icons.family_restroom_rounded, label: 'Guardian', value: villager.guardianName ?? ''),
              AdminInfoRow(
                icon: Icons.medical_information_outlined,
                label: 'Conditions',
                value: villager.chronicConditions.join(', '),
              ),
              AdminInfoRow(icon: Icons.pregnant_woman_rounded, label: 'Pregnant', value: villager.isPregnant ? 'Yes (ANC)' : 'No'),
              AdminInfoRow(
                icon: Icons.monitor_heart_outlined,
                label: 'Screenings',
                value: '$screeningCount${latestRisk != null ? ' • Latest: $latestRisk' : ''}',
              ),
              AdminInfoRow(
                icon: Icons.event_outlined,
                label: 'Registered on',
                value: DateFormat('dd MMM yyyy').format(villager.createdAt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
