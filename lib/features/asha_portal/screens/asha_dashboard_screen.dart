import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/craft_background.dart';
import '../../../core/models/referral_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';
import '../../shared/widgets/network_banner.dart';
import '../../shared/widgets/sync_status_badge.dart';
import '../../awareness_hub/screens/citizen_health_hub_screen.dart';
import '../../shared/screens/patient_qr_scanner_screen.dart';
import 'register_villager_screen.dart';
import 'screening_form_screen.dart';
import 'patient_detail_screen.dart';
import 'asha_households_screen.dart';
import 'asha_chatbot_screen.dart';
import 'asha_issues_inbox_screen.dart';
import '../../../core/services/app_locale.dart';
import '../../shared/widgets/sign_out_dialog.dart';
import '../../shared/widgets/language_selector.dart';

class AshaDashboardScreen extends StatefulWidget {
  const AshaDashboardScreen({super.key});

  @override
  State<AshaDashboardScreen> createState() => _AshaDashboardScreenState();
}

class _AshaDashboardScreenState extends State<AshaDashboardScreen> {
  int _currentNavIndex = 0;
  String _searchQuery = '';
  String _selectedVillageFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildOverviewTab(context),
          const AshaHouseholdsScreen(isEmbedded: false),
          const AshaChatbotScreen(isEmbedded: false),
          const CitizenHealthHubScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.neemDark, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) => setState(() => _currentNavIndex = index),
          backgroundColor: CraftNavTheme.background,
          selectedItemColor: CraftNavTheme.selected,
          unselectedItemColor: CraftNavTheme.unselected,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard_rounded),
              label: context.watch<AppLocale>().t('overview'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.family_restroom_outlined),
              activeIcon: const Icon(Icons.family_restroom_rounded),
              label: context.watch<AppLocale>().t('households'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.smart_toy_outlined),
              activeIcon: const Icon(Icons.smart_toy_rounded),
              label: context.watch<AppLocale>().t('assistant'),
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

  Widget _buildOverviewTab(BuildContext context) {
    final authService = context.watch<AuthService>();
    final repo = context.watch<HealthRepository>();
    final ashaUser = authService.currentUser;

    final myPatients = repo.getPatientsForAsha(ashaUser);
    final myPatientIds = myPatients.map((p) => p.id).toSet();

    final myScreenings = repo.screenings.where((s) => myPatientIds.contains(s.patientId)).toList();
    final myReferrals = repo.referrals.where((r) => myPatientIds.contains(r.patientId)).toList();
    final myIssues = repo.getIssuesForAsha(ashaUser);
    final pendingIssuesCount = myIssues.where((i) => !i.isResolved).length;

    final filteredPatients = myPatients.where((p) {
      final matchesSearch = p.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.contactNumber.contains(_searchQuery) ||
          p.villageName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesVillage = _selectedVillageFilter == 'All' || p.villageName == _selectedVillageFilter;
      return matchesSearch && matchesVillage;
    }).toList();

    final pendingFollowUpsCount = myReferrals.where((r) => r.status != ReferralStatus.closed).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: const CraftHeaderStitch(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nirogya Setu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${ashaUser?.displayName ?? "ASHA Field Worker"} • ${(ashaUser?.villageName ?? "").isNotEmpty ? "${ashaUser!.villageName} • " : ""}Badge: ${ashaUser?.badgeNumber ?? "ASHA"}',
              style: const TextStyle(fontSize: 11, color: Color(0xFFE4E6CC)),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          const LanguageSelector(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan citizen QR',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PatientQrScannerScreen(accentColor: AppColors.primary)),
            ),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.inbox_rounded, size: 26),
                if (pendingIssuesCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFB23A22),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$pendingIssuesCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Citizen Issues Inbox',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const AshaIssuesInboxScreen(),
                ),
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
                roleName: 'ASHA Field Worker Portal',
              );
            },
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
                  // KPI Overview Stats
                  _buildSummaryMetrics(
                    citizenCount: myPatients.length,
                    screeningCount: myScreenings.length,
                    activeReferralCount: myReferrals.length,
                    pendingFollowUps: pendingFollowUpsCount,
                  ),
                  const SizedBox(height: 18),

                  // Quick Action Buttons
                  _buildQuickActionButtons(context),
                  const SizedBox(height: 20),

                  // Assigned Citizens Header with Search & Filter
                  _buildCitizensHeader(myPatients),
                  const SizedBox(height: 10),

                  // Citizens List
                  _buildCitizensList(filteredPatients, ashaUser),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_chart_rounded),
        label: Text(context.watch<AppLocale>().t('newScreening'), style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreeningFormScreen()),
          );
        },
      ),
    );
  }

  Widget _buildSummaryMetrics({
    required int citizenCount,
    required int screeningCount,
    required int activeReferralCount,
    required int pendingFollowUps,
  }) {
    final locale = context.watch<AppLocale>();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                locale.t('assignedCitizens'),
                '$citizenCount',
                Icons.people_alt_outlined,
                AppColors.primary,
                AppColors.primarySurface,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                locale.t('screeningsDone'),
                '$screeningCount',
                Icons.checklist_rounded,
                const Color(0xFF3B6634),
                const Color(0xFFE4E6CC),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                locale.t('activeReferrals'),
                '$activeReferralCount',
                Icons.outgoing_mail,
                AppColors.secondary,
                AppColors.secondarySurface,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                locale.t('followUpsDue'),
                '$pendingFollowUps',
                Icons.schedule_rounded,
                AppColors.riskYellow,
                AppColors.riskYellowSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, Color bg) {
    // The headline count (assigned citizens) is a solid neem block; the rest are tinted.
    final solid = color == AppColors.primary;
    final fg = solid ? AppColors.paint : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: solid ? AppColors.neem : bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: solid ? AppColors.paint.withOpacity(0.16) : AppColors.paint.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: solid ? AppColors.haldi : color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontFamily: 'Fraunces', fontSize: 28, height: 1.0, fontWeight: FontWeight.w700, color: fg),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: solid ? AppColors.paint.withOpacity(0.85) : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(context.watch<AppLocale>().t('registerCitizen'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterVillagerScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.ondemand_video_rounded, size: 16),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(context.watch<AppLocale>().t('awarenessHub'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CitizenHealthHubScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCitizensHeader(List<dynamic> allPatients) {
    final villages = {'All', ...allPatients.map((p) => p.villageName as String)}.toList();
    if (!villages.contains(_selectedVillageFilter)) {
      _selectedVillageFilter = 'All';
    }

    return Column(
      children: [
        Row(
          children: [
            Text(
              context.watch<AppLocale>().t('assignedCitizens'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedVillageFilter,
              underline: const SizedBox.shrink(),
              items: villages.map((v) {
                return DropdownMenuItem(value: v, child: Text(v == 'All' ? context.watch<AppLocale>().t('all') : v, style: const TextStyle(fontSize: 12)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedVillageFilter = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: context.watch<AppLocale>().t('searchCitizen'),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            filled: true,
            fillColor: Color(0xFFFBF4E8),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
      ],
    );
  }

  Widget _buildCitizensList(List<dynamic> patients, AppUser? ashaUser) {
    if (patients.isEmpty) {
      final villageTitle = (ashaUser?.villageName ?? '').isNotEmpty
          ? 'in ${ashaUser!.villageName}'
          : 'in your assigned village';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFFFBF4E8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'No citizens registered $villageTitle yet',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Onboard households and start door-to-door community health screenings.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Register First Citizen'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterVillagerScreen()),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final p = patients[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Color(0xFFFBF4E8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: AppColors.primarySurface,
              child: Text(
                p.fullName.isNotEmpty ? p.fullName[0] : '?',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    p.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                SyncStatusBadge(status: p.syncStatus, compact: true),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Text(
                  '${p.age}y, ${p.gender} • ${p.villageName} • ${p.contactNumber}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (p.isPregnant)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      context.watch<AppLocale>().t('antenatalCareActive'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.riskYellow),
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientDetailScreen(patientId: p.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
