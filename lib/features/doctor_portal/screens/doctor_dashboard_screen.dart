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
import '../../awareness_hub/screens/citizen_health_hub_screen.dart';
import '../../shared/screens/patient_qr_scanner_screen.dart';
import 'doctor_review_screen.dart';
import '../../../core/services/app_locale.dart';
import '../../shared/widgets/sign_out_dialog.dart';
import '../../shared/widgets/language_selector.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _currentIndex = 0;
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildTriageQueueTab(context, authService, doctor, referrals, redCount, yellowCount, pendingCount, consultedCount),
          _buildConsultedTab(context, authService, doctor, referrals),
          _buildAnalyticsTab(context, authService, doctor, repo),
          const CitizenHealthHubScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.roleDoctor,
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.emergency_outlined),
              activeIcon: const Icon(Icons.emergency_rounded),
              label: context.watch<AppLocale>().t('triageQueue'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.task_alt_outlined),
              activeIcon: const Icon(Icons.task_alt_rounded),
              label: context.watch<AppLocale>().t('consulted'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.analytics_outlined),
              activeIcon: const Icon(Icons.analytics_rounded),
              label: context.watch<AppLocale>().t('analytics'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.ondemand_video_outlined),
              activeIcon: const Icon(Icons.ondemand_video_rounded),
              label: context.watch<AppLocale>().t('healthHub'),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildDoctorAppBar(BuildContext context, AuthService authService, dynamic doctor, String subtitle) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nirogya Setu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '${doctor?.displayName ?? "Medical Officer"} • $subtitle',
            style: const TextStyle(fontSize: 11, color: Color(0xFFBBDEFB)),
          ),
        ],
      ),
      backgroundColor: AppColors.roleDoctor,
      foregroundColor: Colors.white,
      actions: [
        const LanguageSelector(),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.qr_code_scanner_rounded),
          tooltip: 'Scan citizen QR',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatientQrScannerScreen(accentColor: AppColors.roleDoctor)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.volume_up_outlined),
          tooltip: 'Voice Guidance',
          onPressed: () {
            VoiceService().speakPrompt(
              context,
              title: 'Doctor Portal Guidance',
              hindiText: 'Referral triage queue. Review red priority cases with urgency.',
              englishText: 'Referral triage queue. Review red priority cases with urgency.',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Sign Out',
          onPressed: () {
            showSignOutConfirmationDialog(
              context: context,
              authService: authService,
              roleName: 'Medical Officer Portal',
            );
          },
        ),
      ],
    );
  }

  /// Tab 0: Triage Queue
  Widget _buildTriageQueueTab(
    BuildContext context,
    AuthService authService,
    dynamic doctor,
    List<ReferralModel> referrals,
    int redCount,
    int yellowCount,
    int pendingCount,
    int consultedCount,
  ) {
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
      appBar: _buildDoctorAppBar(context, authService, doctor, 'PHC Triage Queue'),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Triage Metrics 2x2 Grid
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildCountCard(context.watch<AppLocale>().t('redUrgent'), '$redCount', AppColors.riskRed, AppColors.riskRedSurface),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildCountCard(context.watch<AppLocale>().t('yellowMod'), '$yellowCount', AppColors.riskYellow, AppColors.riskYellowSurface),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCountCard(context.watch<AppLocale>().t('pendingReview'), '$pendingCount', const Color(0xFFE65100), const Color(0xFFFFF3E0)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildCountCard(context.watch<AppLocale>().t('consulted'), '$consultedCount', AppColors.riskGreen, AppColors.riskGreenSurface),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search referrals by citizen, village, or ASHA...',
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

                  // Filter Chips
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

  /// Tab 1: Consulted List
  Widget _buildConsultedTab(
    BuildContext context,
    AuthService authService,
    dynamic doctor,
    List<ReferralModel> referrals,
  ) {
    final consultedList = referrals.where((r) => r.status == ReferralStatus.consulted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildDoctorAppBar(context, authService, doctor, 'Completed Consultations'),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${consultedList.length} Citizens successfully evaluated and prescribed clinical care.',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (consultedList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No consultations marked as completed yet.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...consultedList.map((ref) => _buildReferralCard(ref)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 2: Analytics & Population Health
  Widget _buildAnalyticsTab(
    BuildContext context,
    AuthService authService,
    dynamic doctor,
    HealthRepository repo,
  ) {
    final patients = repo.patients;
    final screenings = repo.screenings;
    final referrals = repo.referrals;

    final redCases = referrals.where((r) => r.priority == HealthPriority.red).length;
    final yellowCases = referrals.where((r) => r.priority == HealthPriority.yellow).length;
    final pregnantCount = patients.where((p) => p.isPregnant).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildDoctorAppBar(context, authService, doctor, 'Epidemiology & Analytics'),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KPI Overview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sector Epidemiological Overview',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildMetricTile('Registered Citizens', '${patients.length}', Icons.people_rounded, AppColors.primary)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildMetricTile('Screenings Logged', '${screenings.length}', Icons.checklist_rounded, const Color(0xFF0284C7))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildMetricTile('Critical Red Alerts', '$redCases', Icons.emergency_rounded, AppColors.riskRed)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildMetricTile('Moderate Yellow Cases', '$yellowCases', Icons.warning_amber_rounded, AppColors.riskYellow)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildMetricTile('Antenatal Care (ANC)', '$pregnantCount', Icons.pregnant_woman_rounded, const Color(0xFF0D9488))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Village Demographics Breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Village Distribution Matrix',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        ...{'Rampura', 'Khed', 'Shivpur'}.map((vName) {
                          final count = patients.where((p) => p.villageName == vName).length;
                          final fraction = patients.isNotEmpty ? count / patients.length : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(vName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('$count citizens', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: fraction,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.roleDoctor),
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
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
                Flexible(
                  child: ElevatedButton.icon(
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
