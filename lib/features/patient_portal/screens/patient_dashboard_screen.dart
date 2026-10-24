import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/network_banner.dart';
import '../../shared/widgets/priority_badge.dart';
import '../../awareness_hub/screens/citizen_health_hub_screen.dart';
import '../../shared/widgets/sign_out_dialog.dart';

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
      backgroundColor: const Color(0xFFF1F5F9),
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
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF064E3B),
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.badge_outlined),
              activeIcon: Icon(Icons.badge_rounded),
              label: 'Health Card',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment_rounded),
              label: 'Records',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication_outlined),
              activeIcon: Icon(Icons.medication_rounded),
              label: 'Prescriptions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.ondemand_video_outlined),
              activeIcon: Icon(Icons.ondemand_video_rounded),
              label: 'Health Hub',
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AuthService authService, PatientModel activeMember) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_rounded, color: Color(0xFF0284C7), size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aarogya Setu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                Text(
                  'National Digital Health Ecosystem • Ayushman Bharat',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.volume_up_outlined, color: Color(0xFF334155)),
          tooltip: 'Voice Guidance',
          onPressed: () {
            VoiceService().speakPrompt(
              context,
              title: 'Aarogya Setu Citizen Portal',
              hindiText: 'Welcome ${activeMember.fullName}. Your official ABHA Health ID and OPD QR code are active.',
              englishText: 'Welcome ${activeMember.fullName}. Your official ABHA Health ID and OPD QR code are active.',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(context, authService, activeMember),
      body: Column(
        children: [
          const NetworkBanner(),

          // Dark Offline Ready Sub-header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF38BDF8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Offline Ready • ABHA Card Cached on Device',
                    style: TextStyle(fontSize: 11, color: Color(0xFFF1F5F9), fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done_rounded, color: Color(0xFF38BDF8), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Secure Offline',
                      style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Household Members Switcher (For shared family phone)
                  _buildHouseholdSwitcher(
                    familyMembers: familyMembers,
                    activeMember: activeMember,
                    onSelectMember: (id) => setState(() => _selectedMemberId = id),
                  ),
                  const SizedBox(height: 14),

                  // 2. Official ABHA Digital Health Card
                  _buildAbhaHealthCard(activeMember),
                  const SizedBox(height: 12),

                  // 3. Three Quick Action Buttons (Download, Share, Big QR)
                  _buildCardActionRow(context, activeMember),
                  const SizedBox(height: 20),
                ],
              ),
            ),
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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(context, authService, activeMember),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHouseholdSwitcher(
                    familyMembers: familyMembers,
                    activeMember: activeMember,
                    onSelectMember: (id) => setState(() => _selectedMemberId = id),
                  ),
                  const SizedBox(height: 14),
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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(context, authService, activeMember),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHouseholdSwitcher(
                    familyMembers: familyMembers,
                    activeMember: activeMember,
                    onSelectMember: (id) => setState(() => _selectedMemberId = id),
                  ),
                  const SizedBox(height: 14),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Household Health Profiles',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${familyMembers.length} Enrolled Members',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Switch profiles below to view individual records. New members are enrolled by your village ASHA worker.',
            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF064E3B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF047857) : const Color(0xFFCBD5E1),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isSelected ? Colors.white : const Color(0xFF0369A1),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${member.fullName} (${member.displayRelationship})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF047857), width: 1.5),
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
                Expanded(child: Container(height: 4, color: Colors.white)),
                Expanded(child: Container(height: 4, color: const Color(0xFF138808))),
              ],
            ),

            // Card Header: National Health Authority
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFF064E3B),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add_box_rounded, color: Color(0xFF064E3B), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AAROGYA SETU • ABHA CARD',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'NATIONAL HEALTH AUTHORITY • GOVT. OF INDIA',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: Color(0xFFA7F3D0),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF047857),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF86EFAC)),
                        SizedBox(width: 4),
                        Text(
                          'e-KYC Verified',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Container(
              padding: const EdgeInsets.all(14),
              color: const Color(0xFFFCFDFD),
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
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Center(
                              child: Text(
                                citizen.fullName.isNotEmpty ? citizen.fullName[0] : 'C',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 10, color: Color(0xFF0284C7)),
                                SizedBox(width: 3),
                                Text(
                                  'Aadhaar Linked',
                                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    citizen.fullName,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCCFBF1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${citizen.age} yrs • ${citizen.gender}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Village: ${citizen.villageName}, Ward: ${citizen.computedWardNumber}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                            ),
                            Text(
                              citizen.computedDistrictState,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ABHA Address Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ABHA ADDRESS (PHR Address)',
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                        ),
                        Text(
                          citizen.computedAbhaAddress,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Divider
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 8),

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
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                citizen.computedAbhaNumber,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(Icons.lock_outline_rounded, size: 10, color: Color(0xFF059669)),
                                SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    'Verified & Active • Hospital OPD Enabled',
                                    style: TextStyle(fontSize: 9, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Scannable QR Code
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: QrImageView(
                                data: citizen.opdQrData,
                                version: QrVersions.auto,
                                size: 64,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'SCAN OPD',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                          ],
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

  /// 3 Action Buttons below the ABHA Card
  Widget _buildCardActionRow(BuildContext context, PatientModel citizen) {
    return Row(
      children: [
        // Download Card
        Expanded(
          child: _buildActionTile(
            icon: Icons.file_download_outlined,
            title: 'Download Card',
            subtitle: 'Offline Pass',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF064E3B),
                  content: Text('✓ ABHA Card for ${citizen.fullName} cached for offline presentation.'),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),

        // Send to ASHA
        Expanded(
          child: _buildActionTile(
            icon: Icons.share_outlined,
            title: 'Share with ASHA',
            subtitle: 'Sync Records',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text('✓ Health Profile & OPD Token shared with your village ASHA worker.'),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),

        // Big QR Code
        Expanded(
          child: _buildActionTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'View OPD Token',
            subtitle: 'Hospital Desk',
            onTap: () => _showQrExpandedDialog(context, citizen),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              children: [
                Icon(icon, color: const Color(0xFF0284C7), size: 22),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Big OPD QR Code Dialog
  void _showQrExpandedDialog(BuildContext context, PatientModel citizen) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'OPD Token & ABHA Scan',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  citizen.fullName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                ),
                Text(
                  'ABHA: ${citizen.computedAbhaNumber}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                  ),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: QrImageView(
                      data: citizen.opdQrData,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'OPD Token: OPD-${citizen.id.hashCode.abs() % 10000}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Present this code at PHC registration desk for fast-track entry.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Doctor Consultations & Prescriptions
  Widget _buildDoctorConsultationsSection(List<dynamic> referrals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doctor Consultations & Prescriptions',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        if (referrals.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No active doctor consultations for this member.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...referrals.map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
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
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Doctor: ${r.assignedDoctorName ?? "Primary Health Centre Doctor"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (r.doctorClinicalNotes != null && r.doctorClinicalNotes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Advice: ${r.doctorClinicalNotes}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  if (r.doctorRecommendations != null && r.doctorRecommendations.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Medication / Dosage: ${r.doctorRecommendations}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
        const Text(
          'Preventive Health Screenings',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        if (screenings.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No screenings recorded yet for this member.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...screenings.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
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
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(s.reason, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    'Next Steps: ${s.recommendedNextStep}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
