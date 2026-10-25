import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/craft_background.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/admin_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/patient_qr.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/expandable_details.dart';
import '../../shared/widgets/network_banner.dart';
import '../../shared/widgets/priority_badge.dart';
import '../../awareness_hub/screens/citizen_health_hub_screen.dart';
import '../../shared/widgets/sign_out_dialog.dart';
import 'raise_issue_screen.dart';
import '../../../core/services/app_locale.dart';
import '../../shared/widgets/language_selector.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _currentIndex = 0;
  String? _selectedMemberId;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final repo = context.watch<HealthRepository>();
    final user = authService.currentUser;

    // Identify current user's primary patient profile
    final primaryPatient = repo.patients.firstWhere(
      (p) => p.id == (user?.uid ?? '') || p.fullName == (user?.displayName ?? ''),
      orElse: () => repo.patients.isNotEmpty
          ? repo.patients.first
          : PatientModel(
              id: 'P-DEMO',
              ashaId: 'ASHA-88',
              fullName: 'Sunita Devi',
              age: 28,
              gender: 'Female',
              villageId: 'VIL-01',
              villageName: 'Rampura',
              contactNumber: '9876543210',
              isPregnant: true,
              householdId: 'HH-RAM-001',
              relationship: 'Self',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
    );

    // Get all family members in this household sharing the same phone
    final familyMembers = repo.getFamilyMembersForPatient(primaryPatient.id);

    // Set currently active member (fallback to primary)
    final activeMember = familyMembers.firstWhere(
      (m) => m.id == _selectedMemberId,
      orElse: () => primaryPatient,
    );

    // Clinical records strictly scoped to this selected family member
    final screenings = repo.getScreeningsForPatient(activeMember.id);
    final referrals = repo.getReferralsForPatient(activeMember.id);
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF3E8D5),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'citizen_raise_issue_fab',
        backgroundColor: const Color(0xFF2C4D27),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(
          context.watch<AppLocale>().t('raiseIssueToAsha'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => RaiseIssueScreen(patient: activeMember),
            ),
          );
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHealthCardTab(context, authService, primaryPatient, familyMembers, activeMember),
          _buildRecordsTab(context, authService, activeMember, familyMembers, screenings, dateFormat),
          _buildPrescriptionsTab(context, authService, activeMember, familyMembers, referrals),
          const CitizenHealthHubScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.neemDark, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: CraftNavTheme.background,
          selectedItemColor: CraftNavTheme.selected,
          unselectedItemColor: CraftNavTheme.unselected,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.badge_outlined),
              activeIcon: const Icon(Icons.badge_rounded),
              label: context.watch<AppLocale>().t('healthCard'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assessment_outlined),
              activeIcon: const Icon(Icons.assessment_rounded),
              label: context.watch<AppLocale>().t('records'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.medication_outlined),
              activeIcon: const Icon(Icons.medication_rounded),
              label: context.watch<AppLocale>().t('prescriptions'),
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

  PreferredSizeWidget _buildAppBar(BuildContext context, AuthService authService, PatientModel activeMember) {
    return AppBar(
      elevation: 0,
      flexibleSpace: const CraftHeaderStitch(motif: CraftMotif.neem),
      backgroundColor: AppColors.neem,
      foregroundColor: AppColors.paint,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.paint.withOpacity(0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_rounded, color: AppColors.haldi, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nirogya Setu',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.paint),
                ),
                Text(
                  'National Digital Health Ecosystem • Ayushman Bharat',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFFE4E6CC), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        const LanguageSelector(),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.volume_up_outlined, color: AppColors.paint),
          tooltip: 'Voice Guidance',
          onPressed: () {
            VoiceService().speakPrompt(
              context,
              title: 'Nirogya Setu Citizen Portal',
              hindiText: 'Welcome ${activeMember.fullName}. Your official ABHA Health ID and OPD QR code are active.',
              englishText: 'Welcome ${activeMember.fullName}. Your official ABHA Health ID and OPD QR code are active.',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppColors.paint),
          tooltip: 'Sign Out',
          onPressed: () {
            showSignOutConfirmationDialog(
              context: context,
              authService: authService,
              roleName: 'Citizen Health Account',
            );
          },
        ),
      ],
    );
  }

  /// Tab 0: Health Card
  Widget _buildHealthCardTab(
    BuildContext context,
    AuthService authService,
    PatientModel primaryPatient,
    List<PatientModel> familyMembers,
    PatientModel activeMember,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E8D5),
      appBar: _buildAppBar(context, authService, activeMember),
      body: Column(
        children: [
          const NetworkBanner(),

          // Dark Offline Ready Sub-header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFF33200F),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA8C98E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.watch<AppLocale>().t('offlineReadyHeader'),
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFFF3E8D5), fontWeight: FontWeight.w500, height: 1.3),
                    maxLines: 2,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_done_rounded, color: Color(0xFFA8C98E), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      context.watch<AppLocale>().t('secureOffline'),
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFFA8C98E), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Household Members Switcher (For shared family phone)
                  _buildHouseholdSwitcher(
                    familyMembers: familyMembers,
                    activeMember: activeMember,
                    onSelectMember: (id) => setState(() => _selectedMemberId = id),
                  ),
                  const SizedBox(height: 20),

                  // 2. Official ABHA Digital Health Card
                  _buildAbhaHealthCard(activeMember),
                  const SizedBox(height: 16),


                  // 4. Raise Issue Card (Voice / Text directly to ASHA)
                  _buildRaiseIssueToAshaCard(context, activeMember),
                  const SizedBox(height: 20),

                  // 5. Call the citizen's own ASHA worker
                  _buildCallAshaCard(context, activeMember),
                  const SizedBox(height: 40), // Padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallAshaCard(BuildContext context, PatientModel activeMember) {
    final asha = context.watch<AdminRepository>().ashaById(activeMember.ashaId);
    final name = asha?.fullName ?? 'Your ASHA worker';
    final mobile = asha?.mobileNumber ?? '';

    Future<void> call() async {
      final ok = await launchUrl(Uri(scheme: 'tel', path: '+91${AdminRepository.normalizeMobile(mobile)}'));
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the phone dialer on this device.')),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xFFFBF4E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2D2B6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Color(0xFFE4E6CC), shape: BoxShape.circle),
                child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFF2C4D27), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Color(0xFF33200F))),
                    const SizedBox(height: 4),
                    Text(
                      mobile.isEmpty
                          ? 'ASHA worker contact not available yet'
                          : 'Your ASHA worker • ${AdminRepository.formatMobile(mobile)}',
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B5443), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B6634),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
            ),
            onPressed: mobile.isEmpty ? null : call,
            icon: const Icon(Icons.call_rounded, size: 18),
            label: const Text('Call ASHA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildRaiseIssueToAshaCard(BuildContext context, PatientModel activeMember) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C4D27), Color(0xFF2C4D27)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C4D27).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.watch<AppLocale>().t('raiseIssueTitle'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.watch<AppLocale>().t('raiseIssueSubtitle'),
            style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.3),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFBF4E8),
                    foregroundColor: const Color(0xFF2C4D27),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => RaiseIssueScreen(patient: activeMember),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: Text(
                    context.watch<AppLocale>().t('raiseIssueWithPlus'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => RaiseIssueScreen(patient: activeMember),
                    ),
                  );
                },
                icon: const Icon(Icons.mic_rounded, size: 18),
                label: Text(context.watch<AppLocale>().t('mic'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tab 1: Health Records
  Widget _buildRecordsTab(
    BuildContext context,
    AuthService authService,
    PatientModel activeMember,
    List<PatientModel> familyMembers,
    List<dynamic> screenings,
    DateFormat dateFormat,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E8D5),
      appBar: _buildAppBar(context, authService, activeMember),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHouseholdSwitcher(
                    familyMembers: familyMembers,
                    activeMember: activeMember,
                    onSelectMember: (id) => setState(() => _selectedMemberId = id),
                  ),
                  const SizedBox(height: 20),
                  _buildScreeningsSection(screenings, dateFormat),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 2: Prescriptions & Doctor Advice
  Widget _buildPrescriptionsTab(
    BuildContext context,
    AuthService authService,
    PatientModel activeMember,
    List<PatientModel> familyMembers,
    List<dynamic> referrals,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E8D5),
      appBar: _buildAppBar(context, authService, activeMember),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHouseholdSwitcher(
                    familyMembers: familyMembers,
                    activeMember: activeMember,
                    onSelectMember: (id) => setState(() => _selectedMemberId = id),
                  ),
                  const SizedBox(height: 20),
                  _buildDoctorConsultationsSection(referrals),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Household Members Selector Bar (Enrolled by ASHA - Citizen view only)
  Widget _buildHouseholdSwitcher({
    required List<PatientModel> familyMembers,
    required PatientModel activeMember,
    required Function(String) onSelectMember,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFBF4E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2D2B6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.watch<AppLocale>().t('householdHealthProfiles'),
                style: const TextStyle(
                    fontFamily: 'Fraunces', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF33200F)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E6CC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${familyMembers.length} ${context.watch<AppLocale>().t('enrolledMembers')}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF3B6634)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.watch<AppLocale>().t('switchProfilesHint'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B5443)),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: familyMembers.map((member) {
                final isSelected = member.id == activeMember.id;
                IconData icon = Icons.person;
                if (member.isPregnant || member.gender.toLowerCase() == 'female') {
                  icon = Icons.female_rounded;
                } else if (member.age < 18) {
                  icon = Icons.child_care_rounded;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelectMember(member.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2C4D27) : const Color(0xFFF3E8D5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2C4D27) : const Color(0xFFD5C1A0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isSelected ? Colors.white : const Color(0xFF3B6634),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${member.fullName} (${member.displayRelationship})',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF33200F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Official ABHA Digital Health Card
  Widget _buildAbhaHealthCard(PatientModel citizen) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFBF4E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C4D27), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14047857),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indian Tricolor Ribbon Strip
            Row(
              children: [
                Expanded(child: Container(height: 4, color: const Color(0xFFFF9933))),
                Expanded(child: Container(height: 4, color: const Color(0xFFFBF4E8))),
                Expanded(child: Container(height: 4, color: const Color(0xFF138808))),
              ],
            ),

            // Card Header: National Health Authority
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              color: const Color(0xFF2C4D27),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Color(0xFFFBF4E8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add_box_rounded, color: Color(0xFF2C4D27), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NIROGYA SETU • ABHA CARD',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, height: 1.25),
                          maxLines: 2,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'NHA • GOVT. OF INDIA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            height: 1.3,
                            color: Color(0xFFE4E6CC),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C4D27),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFFA8C98E)),
                        SizedBox(width: 4),
                        Text(
                          'e-KYC Verified',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Container(
              padding: const EdgeInsets.all(18),
              color: const Color(0xFFFBF4E8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Citizen Photo & Aadhaar Badge
                      Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2D2B6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFD5C1A0)),
                            ),
                            child: Center(
                              child: Text(
                                citizen.fullName.isNotEmpty ? citizen.fullName[0] : 'C',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2C4D27)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4E6CC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 10, color: Color(0xFF3B6634)),
                                SizedBox(width: 3),
                                Text(
                                  'Aadhaar Linked',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF3B6634)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Demographics details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              citizen.fullName,
                              style: const TextStyle(
                                  fontFamily: 'Fraunces', fontSize: 21, height: 1.1, fontWeight: FontWeight.w700, color: Color(0xFF33200F)),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE4E6CC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${citizen.age} yrs • ${citizen.gender}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2C4D27)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Village: ${citizen.villageName}, Ward: ${citizen.computedWardNumber}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF4A3626), height: 1.35),
                            ),
                            Text(
                              citizen.computedDistrictState,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF6B5443), height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ABHA Address Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8D5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE4E6CC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ABHA ADDRESS (PHR Address)',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF3B6634)),
                        ),
                        Text(
                          citizen.computedAbhaAddress,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF2C4D27)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Divider
                  const Divider(color: Color(0xFFE2D2B6), height: 1),
                  const SizedBox(height: 12),

                  // ABHA Number & OPD QR Code Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ABHA NUMBER (14-Digit Health ID)',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF6B5443)),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                citizen.computedAbhaNumber,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: Color(0xFF33200F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Scannable citizen QR code (opens this account when scanned by ASHA / doctor)
                      GestureDetector(
                        onTap: () => _showScanQrDialog(context, citizen),
                        child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Color(0xFFFBF4E8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD5C1A0)),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: QrImageView(
                                data: PatientQr.encode(citizen),
                                version: QrVersions.auto,
                                size: 64,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'TAP TO SCAN',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF33200F)),
                            ),
                          ],
                        ),
                      ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Large QR for scanning by the ASHA worker or doctor.
  void _showScanQrDialog(BuildContext context, PatientModel citizen) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Color(0xFFFBF4E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(citizen.fullName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF33200F))),
              const SizedBox(height: 6),
              Text('ABHA: ${citizen.computedAbhaNumber}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B5443))),
              const SizedBox(height: 16),
              SizedBox(
                width: 240,
                height: 240,
                child: QrImageView(data: PatientQr.encode(citizen), version: QrVersions.auto, size: 240),
              ),
              const SizedBox(height: 16),
              const Text(
                'Show this to your ASHA worker or doctor. Scanning it opens your health record directly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF4A3626), height: 1.35),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          ),
        ),
      ),
    );
  }

  /// Doctor Consultations & Prescriptions
  Widget _buildDoctorConsultationsSection(List<dynamic> referrals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.watch<AppLocale>().t('doctorConsultationsSection'),
          style: const TextStyle(fontFamily: 'Fraunces', fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 14),
        if (referrals.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFFBF4E8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                context.watch<AppLocale>().t('noDoctorConsultations'),
                style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...referrals.map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Color(0xFFFBF4E8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PriorityBadge(priority: r.priority),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.status.displayName,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Doctor: ${r.assignedDoctorName ?? "Primary Health Centre Doctor"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  if (r.doctorClinicalNotes != null && r.doctorClinicalNotes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4E6CC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Advice: ${r.doctorClinicalNotes}',
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF2C4D27), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  if (r.doctorRecommendations != null && r.doctorRecommendations.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Medication / Dosage: ${r.doctorRecommendations}',
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  /// Screenings History Section
  Widget _buildScreeningsSection(List<dynamic> screenings, DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.watch<AppLocale>().t('preventiveScreenings'),
          style: const TextStyle(fontFamily: 'Fraunces', fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 14),
        if (screenings.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFFBF4E8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                context.watch<AppLocale>().t('noScreenings'),
                style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...screenings.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Color(0xFFFBF4E8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PriorityBadge(priority: s.priority),
                      const Spacer(),
                      Text(
                        dateFormat.format(s.createdAt),
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ExpandableDetails(
                    builder: (context, open) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.reason,
                          maxLines: open ? null : 1,
                          overflow: open ? null : TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
                        ),
                        if (open) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Next Steps: ${s.recommendedNextStep}',
                            style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
