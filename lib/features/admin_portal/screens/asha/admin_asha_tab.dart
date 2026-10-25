import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/admin_models.dart';
import '../../../../core/services/admin_repository.dart';
import '../../../../core/services/health_repository.dart';
import '../../widgets/admin_ui.dart';
import 'asha_detail_screen.dart';
import 'asha_form_screen.dart';

class AdminAshaTab extends StatefulWidget {
  const AdminAshaTab({super.key});

  @override
  State<AdminAshaTab> createState() => _AdminAshaTabState();
}

class _AdminAshaTabState extends State<AdminAshaTab> {
  String _query = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminRepository>();
    final patients = context.watch<HealthRepository>().patients;
    final all = admin.ashaWorkers;

    final q = _query.trim().toLowerCase();
    final qDigits = q.replaceAll(RegExp(r'[^0-9]'), '');
    final filtered = all.where((a) {
      final matchesFilter = _filter == 'All' || (_filter == 'Active' ? a.isActive : !a.isActive);
      final matchesQuery = q.isEmpty ||
          a.fullName.toLowerCase().contains(q) ||
          a.villageName.toLowerCase().contains(q) ||
          a.district.toLowerCase().contains(q) ||
          a.ashaIdNumber.toLowerCase().contains(q) ||
          (qDigits.isNotEmpty && a.mobileNumber.contains(qDigits));
      return matchesFilter && matchesQuery;
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
                      hint: 'Search name, village, district, mobile',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AshaFormScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.asha,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final f in const ['All', 'Active', 'Inactive'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          f == 'All' ? 'All (${all.length})' : f,
                          style: TextStyle(fontSize: 12, fontWeight: _filter == f ? FontWeight.bold : FontWeight.w500),
                        ),
                        selected: _filter == f,
                        selectedColor: AdminColors.ashaSurface,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: all.isEmpty
              ? AdminEmptyState(
                  icon: Icons.health_and_safety_outlined,
                  title: 'No ASHA workers yet',
                  message: 'Add ASHA workers to give them login access and link the villagers they serve.',
                  actionLabel: 'Add ASHA Worker',
                  onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AshaFormScreen())),
                )
              : filtered.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches',
                      message: 'Try a different name, village or mobile number.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => admin.syncWithCloud(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final worker = filtered[index];
                          return _AshaCard(
                            worker: worker,
                            hospitalName: admin.hospitalById(worker.hospitalId)?.name,
                            villagerCount: AdminRepository.villagersForAsha(worker.id, patients).length,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _AshaCard extends StatelessWidget {
  final AshaWorkerModel worker;
  final String? hospitalName;
  final int villagerCount;

  const _AshaCard({required this.worker, required this.hospitalName, required this.villagerCount});

  @override
  Widget build(BuildContext context) {
    final initials = worker.fullName.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0].toUpperCase()).join();
    return AdminCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AshaDetailScreen(ashaId: worker.id)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: worker.isActive ? AdminColors.ashaSurface : AdminColors.background,
            child: Text(initials,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: worker.isActive ? AdminColors.asha : AdminColors.muted,
                )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(worker.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AdminColors.ink)),
                    ),
                    AdminActiveChip(isActive: worker.isActive),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${worker.ashaIdNumber} • ${worker.age} yrs • ${worker.gender}',
                    style: const TextStyle(fontSize: 12, color: AdminColors.muted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: AdminColors.muted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(worker.district.isNotEmpty ? '${worker.villageName}, ${worker.district}' : worker.villageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, color: AdminColors.ink, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.call_outlined, size: 15, color: AdminColors.muted),
                    const SizedBox(width: 4),
                    Text(AdminRepository.formatMobile(worker.mobileNumber),
                        style: const TextStyle(fontSize: 12.5, color: AdminColors.ink, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AdminChip(
                      label: '$villagerCount villager${villagerCount == 1 ? '' : 's'}',
                      icon: Icons.groups_rounded,
                      color: AdminColors.citizen,
                      surface: AdminColors.citizenSurface,
                    ),
                    AdminChip(
                      label: hospitalName ?? 'No hospital linked',
                      icon: Icons.local_hospital_outlined,
                      color: AdminColors.hospital,
                      surface: AdminColors.hospitalSurface,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
