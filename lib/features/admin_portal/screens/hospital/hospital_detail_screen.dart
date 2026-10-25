import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/admin_repository.dart';
import '../../../../core/services/health_repository.dart';
import '../../widgets/admin_ui.dart';
import '../asha/asha_detail_screen.dart';
import '../doctor/doctor_detail_screen.dart';
import 'admin_hospital_tab.dart';
import 'hospital_form_screen.dart';

class HospitalDetailScreen extends StatelessWidget {
  final String hospitalId;

  const HospitalDetailScreen({super.key, required this.hospitalId});

  Future<void> _delete(BuildContext context, AdminRepository repo, String name) async {
    final confirmed = await showAdminConfirm(
      context,
      title: 'Delete $name?',
      message: 'This removes the hospital from the hospital list.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final error = await repo.deleteHospital(hospitalId);
    if (!context.mounted) return;
    if (error != null) {
      showAdminSnack(context, error, isError: true);
      return;
    }
    showAdminSnack(context, 'Hospital deleted');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AdminRepository>();
    final patients = context.watch<HealthRepository>().patients;
    final hospital = repo.hospitalById(hospitalId);

    if (hospital == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF3B6634), foregroundColor: const Color(0xFFFBF4E8)),
        body: const AdminEmptyState(
          icon: Icons.domain_disabled_outlined,
          title: 'Hospital not found',
          message: 'This record may have been deleted.',
        ),
      );
    }

    final doctors = repo.doctorsForHospital(hospital.id);
    final asha = repo.ashaForHospital(hospital.id);
    final villagers = repo.villagersForHospital(hospital.id, patients);

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B6634),
        foregroundColor: const Color(0xFFFBF4E8),
        title: const Text('Hospital Details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Edit hospital',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HospitalFormScreen(existing: hospital)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          HospitalCard(
            hospital: hospital,
            doctorCount: doctors.length,
            ashaCount: asha.length,
            villagerCount: villagers.length,
          ),
          const SizedBox(height: 14),
          const AdminSectionTitle(title: 'Information'),
          AdminCard(
            child: Column(
              children: [
                AdminInfoRow(icon: Icons.category_outlined, label: 'Type', value: hospital.type),
                AdminInfoRow(icon: Icons.call_outlined, label: 'Contact', value: hospital.contactNumber),
                AdminInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: '${hospital.address}, ${hospital.villageTown}, ${hospital.district}, '
                      '${hospital.state}${hospital.pincode.isNotEmpty ? ' - ${hospital.pincode}' : ''}',
                ),
                AdminInfoRow(icon: Icons.bed_outlined, label: 'Beds', value: '${hospital.availableBeds} available / ${hospital.totalBeds} total'),
                AdminInfoRow(icon: Icons.monitor_heart_outlined, label: 'ICU beds', value: '${hospital.icuBeds}'),
                AdminInfoRow(icon: Icons.emergency_outlined, label: 'Emergency', value: hospital.hasEmergency ? '24×7 available' : 'Not available'),
                AdminInfoRow(icon: Icons.pregnant_woman_rounded, label: 'Maternity ward', value: hospital.hasMaternityWard ? 'Available' : 'Not available'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AdminSectionTitle(title: 'Doctors (${doctors.length})'),
          AdminCard(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: doctors.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('No doctors linked yet.', style: TextStyle(fontSize: 13, color: AdminColors.muted)),
                  )
                : Column(
                    children: [
                      for (final d in doctors)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: const AdminIconBadge(
                            icon: Icons.medical_services_rounded,
                            color: AdminColors.doctor,
                            surface: AdminColors.doctorSurface,
                            size: 38,
                          ),
                          title: Text(d.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          subtitle: Text(d.specialization, style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctorId: d.id)),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          AdminSectionTitle(title: 'ASHA workers (${asha.length})'),
          AdminCard(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: asha.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('No ASHA workers linked yet.', style: TextStyle(fontSize: 13, color: AdminColors.muted)),
                  )
                : Column(
                    children: [
                      for (final a in asha)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: const AdminIconBadge(
                            icon: Icons.health_and_safety_rounded,
                            color: AdminColors.asha,
                            surface: AdminColors.ashaSurface,
                            size: 38,
                          ),
                          title: Text(a.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '${a.villageName} • ${AdminRepository.villagersForAsha(a.id, patients).length} villagers',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AshaDetailScreen(ashaId: a.id)),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _delete(context, repo, hospital.name),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB23A22),
              side: const BorderSide(color: Color(0xFFB23A22)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete Hospital', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
