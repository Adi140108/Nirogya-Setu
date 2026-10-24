import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/referral_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/network_banner.dart';
import '../../shared/widgets/sync_status_badge.dart';
import '../../shared/widgets/ui.dart';
import '../../awareness_hub/screens/awareness_hub_screen.dart';
import 'register_villager_screen.dart';
import 'screening_form_screen.dart';
import 'patient_detail_screen.dart';
import 'asha_households_screen.dart';
import 'asha_chatbot_screen.dart';
import '../../shared/widgets/sign_out_dialog.dart';

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
          const AwarenessHubScreen(isPublicAccess: false),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) => setState(() => _currentNavIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.family_restroom_outlined),
              activeIcon: Icon(Icons.family_restroom_rounded),
              label: 'Households',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              activeIcon: Icon(Icons.smart_toy_rounded),
              label: 'Assistant',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.ondemand_video_outlined),
              activeIcon: Icon(Icons.ondemand_video_rounded),
              label: 'Videos',
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

    final allPatients = repo.patients;
    final allScreenings = repo.screenings;
    final allReferrals = repo.referrals;

    final query = _searchQuery.toLowerCase();
    final filteredPatients = allPatients.where((p) {
      final matchesSearch = p.fullName.toLowerCase().contains(query) ||
          p.contactNumber.contains(_searchQuery) ||
          p.villageName.toLowerCase().contains(query);
      final matchesVillage = _selectedVillageFilter == 'All' || p.villageName == _selectedVillageFilter;
      return matchesSearch && matchesVillage;
    }).toList();

    final pendingFollowUpsCount = allReferrals.where((r) => r.status != ReferralStatus.closed).length;
    final name = ashaUser?.displayName ?? 'ASHA worker';
    final badge = ashaUser?.badgeNumber ?? 'ASHA-88';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aarogya Setu'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Listen'),
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: 'ASHA Field Worker Portal Help',
                hindiText: 'Register citizens, conduct preventive screenings, and view doctor referrals.',
                englishText: 'Register citizens, conduct preventive screenings, and view doctor referrals.',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () {
              showSignOutConfirmationDialog(
                context: context,
                authService: authService,
                roleName: 'ASHA Field Worker Portal',
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGreeting(context, name, badge, pendingFollowUpsCount),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSummaryMetrics(
                    citizenCount: allPatients.length,
                    screeningCount: allScreenings.length,
                    activeReferralCount: allReferrals.length,
                    pendingFollowUps: pendingFollowUpsCount,
                  ),
                  const SectionHeader('Tasks'),
                  _buildTasks(context),
                  SectionHeader('Your citizens (${filteredPatients.length})'),
                  _buildCitizenFilters(allPatients),
                  const SizedBox(height: AppSpacing.md),
                  _buildCitizensList(filteredPatients),
                  // Room so the last card is not hidden behind the button.
                  const SizedBox(height: AppSizes.primaryButton + AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text('New screening'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreeningFormScreen()),
          );
        },
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String name, String badge, int followUps) {
    final text = Theme.of(context).textTheme;
    final followUpText = followUps == 1 ? '1 follow-up due' : '$followUps follow-ups due';
    final firstName = name.trim().split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Namaste, $firstName', style: text.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Badge $badge  ·  $followUpText',
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSummaryMetrics({
    required int citizenCount,
    required int screeningCount,
    required int activeReferralCount,
    required int pendingFollowUps,
  }) {
    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: a),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: b),
            ],
          ),
        );

    return Column(
      children: [
        row(
          StatTile(label: 'Citizens', value: '$citizenCount', icon: Icons.people_alt_outlined),
          StatTile(label: 'Screenings done', value: '$screeningCount', icon: Icons.checklist_rounded),
        ),
        const SizedBox(height: AppSpacing.md),
        row(
          StatTile(label: 'Referrals', value: '$activeReferralCount', icon: Icons.local_hospital_outlined),
          StatTile(
            label: 'Follow-ups due',
            value: '$pendingFollowUps',
            icon: Icons.schedule_rounded,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTasks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionTile(
          title: 'Register citizen',
          subtitle: 'Add a new person to your list',
          icon: Icons.person_add_alt_1_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterVillagerScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ActionTile(
          title: 'Health videos',
          subtitle: 'Show short videos to families',
          icon: Icons.ondemand_video_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AwarenessHubScreen(isPublicAccess: false)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCitizenFilters(List<PatientModel> allPatients) {
    final villages = {'All', ...allPatients.map((p) => p.villageName)}.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search name, phone or village',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final v in villages) ...[
                ChoiceChip(
                  label: Text(v == 'All' ? 'All villages' : v),
                  selected: _selectedVillageFilter == v,
                  onSelected: (_) => setState(() => _selectedVillageFilter = v),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCitizensList(List<PatientModel> patients) {
    if (patients.isEmpty) {
      return const InfoCard(
        child: EmptyState(
          icon: Icons.person_search_rounded,
          title: 'No citizens found',
          message: 'Try another name, or choose "All villages".',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < patients.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _CitizenCard(patient: patients[i]),
        ],
      ],
    );
  }
}

class _CitizenCard extends StatelessWidget {
  final PatientModel patient;

  const _CitizenCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = patient;

    return InfoCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PatientDetailScreen(patientId: p.id)),
        );
      },
      child: Row(
        children: [
          InitialAvatar(p.fullName),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.fullName, style: text.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text('${p.age} yrs  ·  ${p.gender}  ·  ${p.villageName}', style: text.bodySmall),
                Text(p.contactNumber, style: text.bodySmall),
                if (p.isPregnant) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const StatusTag('Pregnant', icon: Icons.pregnant_woman_rounded),
                ],
                const SizedBox(height: AppSpacing.xs),
                SyncStatusBadge(status: p.syncStatus),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
