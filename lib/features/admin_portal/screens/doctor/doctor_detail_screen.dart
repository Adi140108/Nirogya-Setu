import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/referral_model.dart';
import '../../../../core/services/admin_repository.dart';
import '../../../../core/services/health_repository.dart';
import '../../widgets/admin_ui.dart';
import 'doctor_form_screen.dart';

class DoctorDetailScreen extends StatelessWidget {
  final String doctorId;

  const DoctorDetailScreen({super.key, required this.doctorId});

  Future<void> _resetPassword(BuildContext context, AdminRepository repo) async {
    final doctor = repo.doctors.where((d) => d.id == doctorId).firstOrNull;
    if (doctor == null) return;
    final confirmed = await showAdminConfirm(
      context,
      title: 'Reset password?',
      message: '${doctor.fullName} will no longer be able to sign in with the old password.',
      confirmLabel: 'Reset',
    );
    if (!confirmed || !context.mounted) return;
    final password = await repo.resetDoctorPassword(doctorId);
    if (!context.mounted) return;
    await showCredentialsDialog(
      context,
      title: 'New password issued',
      name: doctor.fullName,
      mobile: AdminRepository.formatMobile(doctor.mobileNumber),
      password: password,
      color: AdminColors.doctor,
    );
  }

  Future<void> _toggleActive(BuildContext context, AdminRepository repo, String name, bool active) async {
    final confirmed = await showAdminConfirm(
      context,
      title: active ? 'Deactivate account?' : 'Activate account?',
      message: active
          ? '$name will not be able to sign in until the account is activated again.'
          : '$name will be able to sign in again.',
      confirmLabel: active ? 'Deactivate' : 'Activate',
      destructive: active,
    );
    if (!confirmed || !context.mounted) return;
    await repo.setDoctorActive(doctorId, !active);
    if (context.mounted) showAdminSnack(context, active ? 'Account deactivated' : 'Account activated');
  }

  Future<void> _delete(BuildContext context, AdminRepository repo, String name) async {
    final confirmed = await showAdminConfirm(
      context,
      title: 'Delete $name?',
      message: 'This removes the doctor and their login access. Past referral notes stay in patient records.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await repo.deleteDoctor(doctorId);
    if (!context.mounted) return;
    showAdminSnack(context, 'Doctor deleted');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AdminRepository>();
    final health = context.watch<HealthRepository>();
    final doctor = repo.doctors.where((d) => d.id == doctorId).firstOrNull;

    if (doctor == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, foregroundColor: AdminColors.ink),
        body: const AdminEmptyState(
          icon: Icons.person_off_outlined,
          title: 'Doctor not found',
          message: 'This record may have been deleted.',
        ),
      );
    }

    final hospital = repo.hospitalById(doctor.hospitalId);
    final referrals = health.referrals.where((r) => r.assignedDoctorId == doctor.id).toList();
    final openReferrals = referrals
        .where((r) => r.status == ReferralStatus.pending || r.status == ReferralStatus.underReview)
        .length;
    final consulted = referrals.length - openReferrals;

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AdminColors.ink,
        title: const Text('Doctor Profile', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Edit details',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DoctorFormScreen(existing: doctor)),
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
                      icon: Icons.medical_services_rounded,
                      color: AdminColors.doctor,
                      surface: AdminColors.doctorSurface,
                      size: 56,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctor.fullName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminColors.ink)),
                          const SizedBox(height: 2),
                          Text(doctor.specialization, style: const TextStyle(fontSize: 12.5, color: AdminColors.muted)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            AdminActiveChip(isActive: doctor.isActive),
                            AdminSyncChip(status: doctor.syncStatus),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _miniStat('${referrals.length}', 'Referrals'),
                    _miniStat('$openReferrals', 'Open'),
                    _miniStat('$consulted', 'Reviewed'),
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
                  value: AdminRepository.formatMobile(doctor.mobileNumber),
                ),
                AdminPasswordRow(password: doctor.password),
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
                AdminInfoRow(icon: Icons.cake_outlined, label: 'Age / Gender', value: '${doctor.age} yrs • ${doctor.gender}'),
                AdminInfoRow(icon: Icons.school_outlined, label: 'Qualification', value: doctor.qualification),
                AdminInfoRow(icon: Icons.verified_outlined, label: 'Registration no.', value: doctor.registrationNumber),
                AdminInfoRow(icon: Icons.timeline_rounded, label: 'Experience', value: '${doctor.experienceYears} years'),
                AdminInfoRow(icon: Icons.mail_outline_rounded, label: 'Email', value: doctor.email),
                AdminInfoRow(
                  icon: Icons.local_hospital_outlined,
                  label: 'Hospital',
                  value: hospital != null ? '${hospital.name}, ${hospital.villageTown}' : 'Not found',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleActive(context, repo, doctor.fullName, doctor.isActive),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: doctor.isActive ? AppColors.riskYellow : AppColors.riskGreen,
                    side: BorderSide(color: doctor.isActive ? AppColors.riskYellow : AppColors.riskGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(doctor.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 18),
                  label: Text(doctor.isActive ? 'Deactivate' : 'Activate',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _delete(context, repo, doctor.fullName),
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
