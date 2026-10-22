import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/screening_rules.dart';
import '../../../core/models/referral_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/network_banner.dart';
import '../../shared/widgets/priority_badge.dart';
import '../../shared/widgets/sync_status_badge.dart';
import '../../awareness_hub/screens/awareness_hub_screen.dart';
import 'doctor_review_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final repo = context.watch<HealthRepository>();
    final doctor = authService.currentUser;
    final referrals = repo.referrals;

    final redCount = referrals.where((r) => r.priority == HealthPriority.red).length;
    final yellowCount = referrals.where((r) => r.priority == HealthPriority.yellow).length;
    final pendingCount = referrals.where((r) => r.status == ReferralStatus.pending || r.status == ReferralStatus.underReview).length;
    final consultedCount = referrals.where((r) => r.status == ReferralStatus.consulted).length;

    final filteredList = referrals.where((r) {
      final matchesSearch = r.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.villageName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.originatingAshaName.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = true;
      if (_selectedFilter == 'Red') {
        matchesFilter = r.priority == HealthPriority.red;
      } else if (_selectedFilter == 'Yellow') {
        matchesFilter = r.priority == HealthPriority.yellow;
      } else if (_selectedFilter == 'Pending') {
        matchesFilter = r.status == ReferralStatus.pending || r.status == ReferralStatus.underReview;
      } else if (_selectedFilter == 'Consulted') {
        matchesFilter = r.status == ReferralStatus.consulted;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doctor?.displayName ?? 'Medical Officer Portal',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'PHC Khed Sector • Referral & Tele-Consultation Queue',
              style: TextStyle(fontSize: 11, color: Color(0xFFBBDEFB)),
            ),
          ],
        ),
        backgroundColor: AppColors.roleDoctor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.ondemand_video_rounded),
            tooltip: 'Awareness Hub',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AwarenessHubScreen(isPublicAccess: false)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: 'Voice Guidance',
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: 'डॉक्टर पोर्टल सहायता / Doctor Portal Help',
                hindiText: 'प्राथमिक स्वास्थ्य केंद्र के लिए रेफरल कतार। लाल प्राथमिकता वाले गंभीर मरीजों को तुरंत देखें।',
                englishText: 'Referral triage queue. Review red priority cases with urgency.',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Triage Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildCountCard('Red Urgent', '$redCount', AppColors.riskRed, AppColors.riskRedSurface),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCountCard('Yellow Mod.', '$yellowCount', AppColors.riskYellow, AppColors.riskYellowSurface),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCountCard('Pending', '$pendingCount', const Color(0xFFE65100), const Color(0xFFFFF3E0)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCountCard('Consulted', '$consultedCount', AppColors.riskGreen, AppColors.riskGreenSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Search & Filter Tabs
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search referrals by patient, village, or ASHA...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'All Referrals (${referrals.length})'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Red', 'Red Urgent ($redCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Yellow', 'Yellow Moderate ($yellowCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pending', 'Pending ($pendingCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Consulted', 'Consulted ($consultedCount)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Referral Cards
                  if (filteredList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No referrals found in this category.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...filteredList.map((ref) => _buildReferralCard(ref)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard(String title, String count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      selected: isSelected,
      selectedColor: AppColors.roleDoctor.withOpacity(0.15),
      labelStyle: TextStyle(color: isSelected ? AppColors.roleDoctor : AppColors.textPrimary),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildReferralCard(ReferralModel ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ref.priority == HealthPriority.red ? AppColors.riskRed.withOpacity(0.5) : AppColors.border,
          width: ref.priority == HealthPriority.red ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PriorityBadge(priority: ref.priority),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ref.status.displayName,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                const Spacer(),
                SyncStatusBadge(status: ref.syncStatus, compact: true),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${ref.patientName} (${ref.patientAge}y, ${ref.patientGender})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Village: ${ref.villageName} • Originating ASHA: ${ref.originatingAshaName}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Triage Trigger: ${ref.triageReason}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            if (ref.doctorClinicalNotes != null && ref.doctorClinicalNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Clinical Notes: ${ref.doctorClinicalNotes}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.roleDoctor),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roleDoctor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.rate_review_rounded, size: 16),
                  label: Text(
                    ref.status == ReferralStatus.consulted ? 'Review / Update Notes' : 'Clinical Consultation',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorReviewScreen(referralId: ref.id),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
