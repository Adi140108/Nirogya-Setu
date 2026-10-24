import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/admin_models.dart';
import '../../../../core/services/admin_repository.dart';
import '../../../../core/services/health_repository.dart';
import '../../widgets/admin_ui.dart';
import 'hospital_detail_screen.dart';
import 'hospital_form_screen.dart';

class AdminHospitalTab extends StatefulWidget {
  const AdminHospitalTab({super.key});

  @override
  State<AdminHospitalTab> createState() => _AdminHospitalTabState();
}

class _AdminHospitalTabState extends State<AdminHospitalTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AdminRepository>();
    final patients = context.watch<HealthRepository>().patients;
    final all = repo.hospitals;
    final q = _query.trim().toLowerCase();
    final filtered = all.where((h) {
      return q.isEmpty ||
          h.name.toLowerCase().contains(q) ||
          h.villageTown.toLowerCase().contains(q) ||
          h.district.toLowerCase().contains(q) ||
          h.type.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: AdminSearchField(
                  hint: 'Search hospital, town, district',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalFormScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.hospital,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(Icons.add_business_rounded, size: 18),
                  label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: all.isEmpty
              ? AdminEmptyState(
                  icon: Icons.local_hospital_outlined,
                  title: 'No hospitals yet',
                  message: 'Add hospitals and health centres. Doctors and ASHA workers are linked to them.',
                  actionLabel: 'Add Hospital',
                  onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalFormScreen())),
                )
              : filtered.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches',
                      message: 'Try a different hospital name or town.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => repo.syncWithCloud(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final h = filtered[index];
                          return HospitalCard(
                            hospital: h,
                            doctorCount: repo.doctorsForHospital(h.id).length,
                            ashaCount: repo.ashaForHospital(h.id).length,
                            villagerCount: repo.villagersForHospital(h.id, patients).length,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospitalId: h.id)),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class HospitalCard extends StatelessWidget {
  final HospitalModel hospital;
  final int doctorCount;
  final int ashaCount;
  final int villagerCount;
  final VoidCallback? onTap;

  const HospitalCard({
    super.key,
    required this.hospital,
    required this.doctorCount,
    required this.ashaCount,
    required this.villagerCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = hospital.totalBeds > 0 ? (hospital.availableBeds / hospital.totalBeds).clamp(0.0, 1.0) : 0.0;
    final bedColor = ratio < 0.15 ? AppColors.riskRed : (ratio < 0.4 ? AppColors.riskYellow : AppColors.riskGreen);

    return AdminCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminIconBadge(
                icon: Icons.local_hospital_rounded,
                color: AdminColors.hospital,
                surface: AdminColors.hospitalSurface,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hospital.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AdminColors.ink)),
                    const SizedBox(height: 2),
                    Text(hospital.type, style: const TextStyle(fontSize: 12, color: AdminColors.muted)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AdminColors.muted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text('${hospital.villageTown}, ${hospital.district}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AdminColors.ink, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(Icons.medical_services_rounded, '$doctorCount', 'Doctors', AdminColors.doctor, AdminColors.doctorSurface),
              _stat(Icons.health_and_safety_rounded, '$ashaCount', 'ASHA', AdminColors.asha, AdminColors.ashaSurface),
              _stat(Icons.groups_rounded, '$villagerCount', 'Villagers', AdminColors.citizen, AdminColors.citizenSurface),
              _stat(Icons.monitor_heart_rounded, '${hospital.icuBeds}', 'ICU', AppColors.riskRed, AppColors.riskRedSurface),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.bed_rounded, size: 16, color: AdminColors.muted),
              const SizedBox(width: 6),
              Text('Beds: ${hospital.availableBeds} available of ${hospital.totalBeds}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.ink)),
              const Spacer(),
              if (hospital.hasEmergency)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: AdminChip(label: '24×7 Emergency', color: AppColors.riskRed, surface: AppColors.riskRedSurface),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AdminColors.background,
              color: bedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color, Color surface) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontSize: 10.5, color: AdminColors.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
