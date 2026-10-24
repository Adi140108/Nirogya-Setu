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
import '../../shared/widgets/ui.dart';
import '../../awareness_hub/screens/awareness_hub_screen.dart';
import 'doctor_review_screen.dart';
import '../../shared/widgets/sign_out_dialog.dart';

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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildTriageQueueTab(context, authService, doctor, referrals, redCount, yellowCount, pendingCount, consultedCount),
          _buildConsultedTab(context, authService, doctor, referrals),
          _buildAnalyticsTab(context, authService, doctor, repo),
          const AwarenessHubScreen(isPublicAccess: false),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency_outlined),
              activeIcon: Icon(Icons.emergency_rounded),
              label: 'Queue',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_outlined),
              activeIcon: Icon(Icons.task_alt_rounded),
              label: 'Consulted',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'Reports',
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

  PreferredSizeWidget _buildDoctorAppBar(BuildContext context, AuthService authService, dynamic doctor, String title) {
    return AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.volume_up_outlined),
          label: const Text('Listen'),
          onPressed: () {
            VoiceService().speakPrompt(
              context,
              title: 'Doctor Portal Guidance',
              hindiText: 'Referral queue. Review urgent cases first.',
              englishText: 'Referral queue. Review urgent cases first.',
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
              roleName: 'Medical Officer Portal',
            );
          },
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  /// Home greeting plus one short status line, matching the other dashboards.
  Widget _buildGreeting(BuildContext context, dynamic doctor, int pendingCount, int redCount) {
    final text = Theme.of(context).textTheme;
    final name = '${doctor?.displayName ?? "Doctor"}';
    final waiting = pendingCount == 1 ? '1 case waiting' : '$pendingCount cases waiting';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Namaste, $name', style: text.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$waiting  ·  $redCount urgent',
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
      appBar: _buildDoctorAppBar(context, authService, doctor, 'Referral queue'),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: ListView(
              padding: AppSpacing.screen,
              children: [
                _buildGreeting(context, doctor, pendingCount, redCount),
                const SizedBox(height: AppSpacing.lg),
                _statRow([
                  StatTile(
                    label: 'Urgent',
                    value: '$redCount',
                    icon: Icons.warning_rounded,
                    color: AppColors.riskRed,
                    onTap: () => setState(() => _selectedFilter = 'Red'),
                  ),
                  StatTile(
                    label: 'Moderate',
                    value: '$yellowCount',
                    icon: Icons.error_outline_rounded,
                    color: AppColors.riskYellow,
                    onTap: () => setState(() => _selectedFilter = 'Yellow'),
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),
                _statRow([
                  StatTile(
                    label: 'Waiting',
                    value: '$pendingCount',
                    icon: Icons.hourglass_top_rounded,
                    onTap: () => setState(() => _selectedFilter = 'Pending'),
                  ),
                  StatTile(
                    label: 'Consulted',
                    value: '$consultedCount',
                    icon: Icons.task_alt_rounded,
                    onTap: () => setState(() => _selectedFilter = 'Consulted'),
                  ),
                ]),
                const SizedBox(height: AppSpacing.xl),

                // Search
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search patient, village or ASHA',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: AppSpacing.md),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'All (${referrals.length})'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Red', 'Urgent ($redCount)'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Yellow', 'Moderate ($yellowCount)'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Pending', 'Waiting ($pendingCount)'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Consulted', 'Consulted ($consultedCount)'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Referral cards
                if (filteredList.isEmpty)
                  const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No referrals here',
                    message: 'Try another filter or clear the search.',
                  )
                else
                  ..._separated(filteredList.map((ref) => _buildReferralCard(context, ref))),
              ],
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: _buildDoctorAppBar(context, authService, doctor, 'Consulted'),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: ListView(
              padding: AppSpacing.screen,
              children: [
                InfoCard(
                  color: AppColors.primarySurface,
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          '${consultedList.length} patients seen and given treatment.',
                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (consultedList.isEmpty)
                  const EmptyState(
                    icon: Icons.task_alt_outlined,
                    title: 'No consultations yet',
                    message: 'Cases you mark as consulted will show here.',
                  )
                else
                  ..._separated(consultedList.map((ref) => _buildReferralCard(context, ref))),
              ],
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
      appBar: _buildDoctorAppBar(context, authService, doctor, 'Reports'),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: ListView(
              padding: AppSpacing.screen,
              children: [
                const SectionHeader('Area overview'),
                _statRow([
                  StatTile(label: 'Registered citizens', value: '${patients.length}', icon: Icons.people_rounded),
                  StatTile(label: 'Screenings', value: '${screenings.length}', icon: Icons.checklist_rounded),
                ]),
                const SizedBox(height: AppSpacing.md),
                _statRow([
                  StatTile(
                    label: 'Urgent cases',
                    value: '$redCases',
                    icon: Icons.warning_rounded,
                    color: AppColors.riskRed,
                  ),
                  StatTile(
                    label: 'Moderate cases',
                    value: '$yellowCases',
                    icon: Icons.error_outline_rounded,
                    color: AppColors.riskYellow,
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),
                _statRow([
                  StatTile(label: 'Pregnant women (ANC)', value: '$pregnantCount', icon: Icons.pregnant_woman_rounded),
                  const SizedBox.shrink(),
                ]),

                // Village breakdown
                const SectionHeader('Citizens by village'),
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final vName in {'Rampura', 'Khed', 'Shivpur'})
                        _buildVillageRow(context, vName, patients.where((p) => p.villageName == vName).length, patients.length),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVillageRow(BuildContext context, String vName, int count, int total) {
    final textTheme = Theme.of(context).textTheme;
    final fraction = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(vName, style: textTheme.titleSmall)),
              const SizedBox(width: AppSpacing.sm),
              Text(count == 1 ? '1 citizen' : '$count citizens', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: '$vName: $count of $total citizens',
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
              minHeight: AppSpacing.sm,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ],
      ),
    );
  }

  /// Two equal columns for [StatTile]s.
  Widget _statRow(List<Widget> tiles) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tiles[0]),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: tiles[1]),
        ],
      ),
    );
  }

  /// Puts a standard gap between cards.
  List<Widget> _separated(Iterable<Widget> items) {
    final out = <Widget>[];
    for (final item in items) {
      if (out.isNotEmpty) out.add(const SizedBox(height: AppSpacing.md));
      out.add(item);
    }
    return out;
  }

  void _openReview(BuildContext context, ReferralModel ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorReviewScreen(referralId: ref.id),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilter == key,
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildReferralCard(BuildContext context, ReferralModel ref) {
    final textTheme = Theme.of(context).textTheme;
    final hasNotes = ref.doctorClinicalNotes != null && ref.doctorClinicalNotes!.isNotEmpty;

    return InfoCard(
      accent: ref.priority.color,
      onTap: () => _openReview(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PriorityBadge(priority: ref.priority),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: SyncStatusBadge(status: ref.syncStatus, compact: true)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusTag(ref.status.displayName, icon: Icons.flag_outlined),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${ref.patientName}, ${ref.patientAge} yrs, ${ref.patientGender}',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Village: ${ref.villageName} · ASHA: ${ref.originatingAshaName}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text('Reason: ${ref.triageReason}', style: textTheme.bodyMedium),
          ),
          if (hasNotes) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your notes: ${ref.doctorClinicalNotes}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: AppColors.primaryDark),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            icon: const Icon(Icons.rate_review_rounded, size: 20),
            label: Text(ref.status == ReferralStatus.consulted ? 'Update notes' : 'Review case'),
            onPressed: () => _openReview(context, ref),
          ),
        ],
      ),
    );
  }
}
