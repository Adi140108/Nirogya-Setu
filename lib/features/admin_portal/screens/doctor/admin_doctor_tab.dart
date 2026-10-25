import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/admin_models.dart';
import '../../../../core/services/admin_repository.dart';
import '../../widgets/admin_ui.dart';
import 'doctor_detail_screen.dart';
import 'doctor_form_screen.dart';

class AdminDoctorTab extends StatefulWidget {
  final VoidCallback onOpenHospitals;

  const AdminDoctorTab({super.key, required this.onOpenHospitals});

  @override
  State<AdminDoctorTab> createState() => _AdminDoctorTabState();
}

class _AdminDoctorTabState extends State<AdminDoctorTab> {
  String _query = '';
  String? _hospitalFilter;

  void _add(AdminRepository repo) {
    if (repo.hospitals.isEmpty) {
      showAdminSnack(context, 'Add a hospital first. Every doctor must be linked to a hospital.', isError: true);
      widget.onOpenHospitals();
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AdminRepository>();
    final all = repo.doctors;
    final hospitals = repo.hospitals;
    final hospitalFilter = hospitals.any((h) => h.id == _hospitalFilter) ? _hospitalFilter : null;

    final q = _query.trim().toLowerCase();
    final qDigits = q.replaceAll(RegExp(r'[^0-9]'), '');
    final filtered = all.where((d) {
      final matchesHospital = hospitalFilter == null || d.hospitalId == hospitalFilter;
      final matchesQuery = q.isEmpty ||
          d.fullName.toLowerCase().contains(q) ||
          d.specialization.toLowerCase().contains(q) ||
          d.registrationNumber.toLowerCase().contains(q) ||
          (qDigits.isNotEmpty && d.mobileNumber.contains(qDigits));
      return matchesHospital && matchesQuery;
    }).toList();

    return Column(
      children: [
        Container(
          color: const Color(0xFFFBF4E8),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AdminSearchField(
                      hint: 'Search name, specialization, mobile',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => _add(repo),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.doctor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              if (hospitals.length > 1) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('All (${all.length})', style: const TextStyle(fontSize: 12)),
                          selected: hospitalFilter == null,
                          selectedColor: AdminColors.doctorSurface,
                          onSelected: (_) => setState(() => _hospitalFilter = null),
                        ),
                      ),
                      for (final h in hospitals)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(h.name, style: const TextStyle(fontSize: 12)),
                            selected: hospitalFilter == h.id,
                            selectedColor: AdminColors.doctorSurface,
                            onSelected: (_) => setState(() => _hospitalFilter = h.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: all.isEmpty
              ? AdminEmptyState(
                  icon: Icons.medical_services_outlined,
                  title: 'No doctors yet',
                  message: hospitals.isEmpty
                      ? 'Add a hospital first, then add doctors and link them to it.'
                      : 'Add doctors to give them login access and link them to a hospital.',
                  actionLabel: hospitals.isEmpty ? 'Go to Hospitals' : 'Add Doctor',
                  onAction: () => _add(repo),
                )
              : filtered.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches',
                      message: 'Try a different name, specialization or hospital.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => repo.syncWithCloud(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doctor = filtered[index];
                          return _DoctorCard(doctor: doctor, hospitalName: repo.hospitalById(doctor.hospitalId)?.name);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final String? hospitalName;

  const _DoctorCard({required this.doctor, required this.hospitalName});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctorId: doctor.id)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminIconBadge(
            icon: Icons.medical_services_rounded,
            color: doctor.isActive ? AdminColors.doctor : AdminColors.muted,
            surface: doctor.isActive ? AdminColors.doctorSurface : AdminColors.background,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(doctor.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AdminColors.ink)),
                    ),
                    AdminActiveChip(isActive: doctor.isActive),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${doctor.specialization} • ${doctor.qualification}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AdminColors.muted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.call_outlined, size: 15, color: AdminColors.muted),
                    const SizedBox(width: 4),
                    Text(AdminRepository.formatMobile(doctor.mobileNumber),
                        style: const TextStyle(fontSize: 12.5, color: AdminColors.ink, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    const Icon(Icons.workspace_premium_outlined, size: 15, color: AdminColors.muted),
                    const SizedBox(width: 4),
                    Text('${doctor.experienceYears} yrs exp',
                        style: const TextStyle(fontSize: 12.5, color: AdminColors.ink, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                AdminChip(
                  label: hospitalName ?? 'Hospital not found',
                  icon: Icons.local_hospital_outlined,
                  color: AdminColors.hospital,
                  surface: AdminColors.hospitalSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
