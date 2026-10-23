import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/referral_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/network_banner.dart';
import '../../shared/widgets/sync_status_badge.dart';
import '../../awareness_hub/screens/awareness_hub_screen.dart';
import 'register_villager_screen.dart';
import 'screening_form_screen.dart';
import 'patient_detail_screen.dart';
import '../../../main.dart';

class AshaDashboardScreen extends StatefulWidget {
  const AshaDashboardScreen({super.key});

  @override
  State<AshaDashboardScreen> createState() => _AshaDashboardScreenState();
}

class _AshaDashboardScreenState extends State<AshaDashboardScreen> {
  String _searchQuery = '';
  String _selectedVillageFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final repo = context.watch<HealthRepository>();
    final ashaUser = authService.currentUser;

    final allPatients = repo.patients;
    final allScreenings = repo.screenings;
    final allReferrals = repo.referrals;

    final filteredPatients = allPatients.where((p) {
      final matchesSearch = p.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.contactNumber.contains(_searchQuery) ||
          p.villageName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesVillage = _selectedVillageFilter == 'All' || p.villageName == _selectedVillageFilter;
      return matchesSearch && matchesVillage;
    }).toList();

    final pendingFollowUpsCount = allReferrals.where((r) => r.status != ReferralStatus.closed).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ashaUser?.displayName ?? 'ASHA Field Worker',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Rampura Sector • Badge: ${ashaUser?.badgeNumber ?? "ASHA-88"}',
              style: const TextStyle(fontSize: 11, color: Color(0xFFE0F2F1)),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
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
                title: 'आशा पोर्टल सहायता / ASHA Portal Help',
                hindiText: 'यहाँ आप नागरिकों का पंजीकरण, स्वास्थ्य जांच और रेफरल स्थिति देख सकती हैं।',
                englishText: 'Register citizens, conduct preventive screenings, and view doctor referrals.',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RootGateScreen()),
                  (route) => false,
                );
              }
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
                    citizenCount: allPatients.length,
                    screeningCount: allScreenings.length,
                    activeReferralCount: allReferrals.length,
                    pendingFollowUps: pendingFollowUpsCount,
                  ),
                  const SizedBox(height: 18),

                  // Quick Action Buttons
                  _buildQuickActionButtons(context),
                  const SizedBox(height: 20),

                  // Assigned Citizens Header with Search & Filter
                  _buildCitizensHeader(allPatients),
                  const SizedBox(height: 10),

                  // Citizens List
                  _buildCitizensList(filteredPatients),
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
        label: const Text('New Screening', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Assigned Citizens',
                '$citizenCount',
                Icons.people_alt_outlined,
                AppColors.primary,
                AppColors.primarySurface,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Screenings Done',
                '$screeningCount',
                Icons.checklist_rounded,
                const Color(0xFF0288D1),
                const Color(0xFFE1F5FE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Active Referrals',
                '$activeReferralCount',
                Icons.outgoing_mail,
                AppColors.secondary,
                AppColors.secondarySurface,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Follow-ups Due',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Register Citizen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterVillagerScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.ondemand_video_rounded, size: 18),
            label: const Text('Awareness Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AwarenessHubScreen(isPublicAccess: false)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCitizensHeader(List<dynamic> allPatients) {
    final villages = {'All', ...allPatients.map((p) => p.villageName as String)}.toList();

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Assigned Citizens / पंजीकृत नागरिक',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedVillageFilter,
              underline: const SizedBox.shrink(),
              items: villages.map((v) {
                return DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 12)));
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
            hintText: 'Search by name, phone or village...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
      ],
    );
  }

  Widget _buildCitizensList(List<dynamic> patients) {
    if (patients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'No citizens found matching query.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
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
            color: Colors.white,
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
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'Antenatal Care Active',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.riskYellow),
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
