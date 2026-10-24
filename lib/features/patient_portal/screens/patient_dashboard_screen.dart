import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/referral_model.dart';
import '../../../core/models/screening_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/network_banner.dart';
import '../../shared/widgets/priority_badge.dart';
import '../../shared/widgets/ui.dart';
import '../../awareness_hub/screens/awareness_hub_screen.dart';
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
    final dateFormat = DateFormat('dd MMM yyyy');

    final appBar = _PortalAppBar(authService: authService, activeMember: activeMember);
    final switcher = _FamilySwitcher(
      members: familyMembers,
      activeMember: activeMember,
      onSelect: (id) => setState(() => _selectedMemberId = id),
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _TabPage(
            appBar: appBar,
            children: [
              _Greeting(name: primaryPatient.fullName),
              const SizedBox(height: AppSpacing.lg),
              switcher,
              const SizedBox(height: AppSpacing.md),
              _RecordStats(
                checkups: screenings.length,
                doctorVisits: referrals.length,
                onCheckups: () => setState(() => _currentIndex = 1),
                onDoctorVisits: () => setState(() => _currentIndex = 2),
              ),
              const SizedBox(height: AppSpacing.md),
              _HealthCard(
                citizen: activeMember,
                onShowQr: () => _showQrDialog(context, activeMember),
              ),
              const SectionHeader('More options'),
              ActionTile(
                title: 'Save card on phone',
                subtitle: 'Use it without internet',
                icon: Icons.file_download_outlined,
                onTap: () => _showMessage(
                  context,
                  'Health card for ${activeMember.fullName} is saved on this phone.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ActionTile(
                title: 'Share with ASHA worker',
                subtitle: 'Send your health details',
                icon: Icons.share_outlined,
                onTap: () => _showMessage(
                  context,
                  'Your health details and hospital token were shared with your ASHA worker.',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Show QR at hospital',
                icon: Icons.qr_code_2_rounded,
                onPressed: () => _showQrDialog(context, activeMember),
              ),
            ],
          ),
          _TabPage(
            appBar: appBar,
            children: [
              _TabTitle(
                title: 'Checkups',
                subtitle: 'Health checks done for ${activeMember.fullName}.',
              ),
              const SizedBox(height: AppSpacing.lg),
              switcher,
              const SectionHeader('Past checkups'),
              _CheckupList(screenings: screenings, dateFormat: dateFormat),
            ],
          ),
          _TabPage(
            appBar: appBar,
            children: [
              _TabTitle(
                title: 'Medicines',
                subtitle: 'Doctor advice and medicines for ${activeMember.fullName}.',
              ),
              const SizedBox(height: AppSpacing.lg),
              switcher,
              const SectionHeader('Doctor visits'),
              _DoctorVisitList(referrals: referrals),
            ],
          ),
          const AwarenessHubScreen(isPublicAccess: true),
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
              icon: Icon(Icons.badge_outlined),
              activeIcon: Icon(Icons.badge_rounded),
              label: 'Card',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment_rounded),
              label: 'Checkups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication_outlined),
              activeIcon: Icon(Icons.medication_rounded),
              label: 'Medicines',
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

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Big hospital (OPD) QR code dialog.
  void _showQrDialog(BuildContext context, PatientModel citizen) {
    showDialog(
      context: context,
      builder: (ctx) {
        final text = Theme.of(ctx).textTheme;
        // Screen width minus dialog inset, content padding and the QR frame
        // (padding + border) on both sides, kept between min and max.
        const reserved = 2 * (_QrSizes.dialogInset + AppSpacing.xl + AppSpacing.md + _QrSizes.border);
        final qrSize = (MediaQuery.sizeOf(ctx).width - reserved)
            .clamp(_QrSizes.dialogMin, _QrSizes.dialogMax)
            .toDouble();
        return AlertDialog(
          scrollable: true,
          title: const Text('Hospital QR code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(citizen.fullName, style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text('ABHA: ${citizen.computedAbhaNumber}', style: text.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.border),
                ),
                // Tight size keeps QrImageView (a LayoutBuilder) out of the
                // AlertDialog's intrinsic sizing pass.
                child: SizedBox.square(
                  dimension: qrSize,
                  child: QrImageView(
                    data: citizen.opdQrData,
                    version: QrVersions.auto,
                    size: qrSize,
                    padding: EdgeInsets.zero,
                    semanticsLabel: 'Hospital QR code for ${citizen.fullName}',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'Token number: OPD-${citizen.id.hashCode.abs() % 10000}',
                  textAlign: TextAlign.center,
                  style: text.titleSmall?.copyWith(color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Show this code at the hospital desk. They will scan it to register you quickly.',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }
}

/// Shared app bar for the citizen tabs: title, voice help, sign out.
class _PortalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AuthService authService;
  final PatientModel activeMember;

  const _PortalAppBar({required this.authService, required this.activeMember});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final message =
        'Welcome ${activeMember.fullName}. Your health card and hospital QR code are ready to use.';
    return AppBar(
      title: const Text('Aarogya Setu', maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.volume_up_outlined),
          label: const Text('Listen'),
          onPressed: () {
            VoiceService().speakPrompt(
              context,
              title: 'Aarogya Setu Citizen Portal',
              hindiText: message,
              englishText: message,
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
              roleName: 'Citizen Health Account',
            );
          },
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}

/// One tab: app bar, network banner, scrolling content.
class _TabPage extends StatelessWidget {
  final PreferredSizeWidget appBar;
  final List<Widget> children;

  const _TabPage({required this.appBar, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Home greeting plus one status line about offline use.
class _Greeting extends StatelessWidget {
  final String name;

  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final firstName = name.trim().split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Namaste, $firstName', style: text.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_done_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Your health card is saved on this phone. It works without internet.',
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Title block for the Checkups and Medicines tabs.
class _TabTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TabTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Pick which family member's records to show. Members are added by the ASHA worker.
class _FamilySwitcher extends StatelessWidget {
  final List<PatientModel> members;
  final PatientModel activeMember;
  final ValueChanged<String> onSelect;

  const _FamilySwitcher({
    required this.members,
    required this.activeMember,
    required this.onSelect,
  });

  IconData _iconFor(PatientModel member) {
    if (member.isPregnant || member.gender.toLowerCase() == 'female') {
      return Icons.female_rounded;
    }
    if (member.age < 18) return Icons.child_care_rounded;
    return Icons.person_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final count = members.length;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Family', style: text.titleSmall)),
              Text('$count ${count == 1 ? 'person' : 'people'}', style: text.labelMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap a name to see their records. Your ASHA worker adds new family members.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final member in members)
                ChoiceChip(
                  avatar: Icon(_iconFor(member), size: 20, color: AppColors.primary),
                  label: Text('${member.fullName} (${member.displayRelationship})'),
                  selected: member.id == activeMember.id,
                  onSelected: (_) => onSelect(member.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ABHA digital health card with the small scannable hospital QR code.
class _HealthCard extends StatelessWidget {
  final PatientModel citizen;
  final VoidCallback onShowQr;

  const _HealthCard({required this.citizen, required this.onShowQr});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              InitialAvatar(citizen.fullName),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(citizen.fullName, style: text.titleMedium),
                    Text('${citizen.age} years · ${citizen.gender}', style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'ABHA health card · Verified · Aadhaar linked',
                  style: text.labelMedium?.copyWith(color: AppColors.primaryDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),
          InfoRow('Village', '${citizen.villageName}, Ward ${citizen.computedWardNumber}'),
          InfoRow('District', citizen.computedDistrictState),
          InfoRow('ABHA address', citizen.computedAbhaAddress),
          const SizedBox(height: AppSpacing.xs),
          const Divider(),
          const SizedBox(height: AppSpacing.md),

          // Health ID number + QR. QR sits beside the ID when the number fits
          // on one line, otherwise it stacks below so the ID stays readable.
          LayoutBuilder(
            builder: (context, constraints) {
              final idStyle = text.titleMedium?.copyWith(fontWeight: FontWeight.w700);
              final painter = TextPainter(
                text: TextSpan(text: citizen.computedAbhaNumber, style: idStyle),
                textScaler: MediaQuery.textScalerOf(context),
                textDirection: Directionality.of(context),
                maxLines: 1,
              )..layout();
              final idWidth = painter.width;
              painter.dispose();
              final thumbWidth = _QrThumb.widthFor(context);
              final idBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Health ID number (ABHA)', style: text.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(citizen.computedAbhaNumber, style: idStyle),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Active. Works at the hospital desk.', style: text.bodySmall),
                ],
              );
              final qrBox = _QrThumb(data: citizen.opdQrData, onTap: onShowQr);
              final sideBySide =
                  constraints.maxWidth - thumbWidth - AppSpacing.md >= idWidth;
              if (sideBySide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: idBlock),
                    const SizedBox(width: AppSpacing.md),
                    qrBox,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [idBlock, const SizedBox(height: AppSpacing.md), qrBox],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Named QR dimensions (not spacing) used by the card thumb and the dialog.
abstract final class _QrSizes {
  /// QR image on the health card.
  static const double thumb = 88;

  /// Big QR in the dialog stays between these.
  static const double dialogMin = 120;
  static const double dialogMax = 200;

  /// Frame border width around a QR.
  static const double border = 1;

  /// Material's default horizontal AlertDialog inset (40).
  static const double dialogInset = AppSpacing.xxl + AppSpacing.sm;
}

/// Small tappable QR on the health card. Only the QR frame has a fixed size;
/// the caption takes its own width (see [widthFor]).
class _QrThumb extends StatelessWidget {
  // QR + padding + border on both sides.
  static const double boxWidth = _QrSizes.thumb + 2 * (AppSpacing.sm + _QrSizes.border);
  static const String _captionText = 'Tap to enlarge';

  final String data;
  final VoidCallback onTap;

  const _QrThumb({required this.data, required this.onTap});

  /// Real rendered width: the QR frame or the caption, whichever is wider
  /// at the current text scale.
  static double widthFor(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: _captionText, style: Theme.of(context).textTheme.labelSmall),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final captionWidth = painter.width;
    painter.dispose();
    return math.max(boxWidth, captionWidth);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Show bigger QR code',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border, width: _QrSizes.border),
              ),
              child: SizedBox.square(
                dimension: _QrSizes.thumb,
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: _QrSizes.thumb,
                  padding: EdgeInsets.zero,
                  semanticsLabel: 'Hospital QR code',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _captionText,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Two tappable counts for the selected member; each opens its tab.
class _RecordStats extends StatelessWidget {
  final int checkups;
  final int doctorVisits;
  final VoidCallback onCheckups;
  final VoidCallback onDoctorVisits;

  const _RecordStats({
    required this.checkups,
    required this.doctorVisits,
    required this.onCheckups,
    required this.onDoctorVisits,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatTile(
              label: 'Checkups',
              value: '$checkups',
              icon: Icons.assessment_outlined,
              onTap: onCheckups,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatTile(
              label: 'Doctor visits',
              value: '$doctorVisits',
              icon: Icons.medication_outlined,
              onTap: onDoctorVisits,
            ),
          ),
        ],
      ),
    );
  }
}

/// Past health checkups (screenings) for the selected member.
class _CheckupList extends StatelessWidget {
  final List<ScreeningModel> screenings;
  final DateFormat dateFormat;

  const _CheckupList({required this.screenings, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    if (screenings.isEmpty) {
      return const InfoCard(
        child: EmptyState(
          icon: Icons.assessment_outlined,
          title: 'No checkups yet',
          message: 'Your ASHA worker will add checkups here after a visit.',
        ),
      );
    }
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in screenings) ...[
          InfoCard(
            accent: s.priority.color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PriorityBadge(priority: s.priority),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        dateFormat.format(s.createdAt),
                        style: text.labelMedium,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(s.reason, style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Text('What to do next', style: text.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(s.recommendedNextStep, style: text.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// Doctor visits (referrals) with advice and medicines for the selected member.
class _DoctorVisitList extends StatelessWidget {
  final List<ReferralModel> referrals;

  const _DoctorVisitList({required this.referrals});

  @override
  Widget build(BuildContext context) {
    if (referrals.isEmpty) {
      return const InfoCard(
        child: EmptyState(
          icon: Icons.medication_outlined,
          title: 'No doctor visits yet',
          message: 'Advice and medicines from the doctor will show here.',
        ),
      );
    }
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final r in referrals) ...[
          InfoCard(
            accent: r.priority.color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PriorityBadge(priority: r.priority),
                    StatusTag(r.status.displayName, icon: Icons.assignment_outlined),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Doctor: ${r.assignedDoctorName ?? "Health centre doctor"}',
                  style: text.titleSmall,
                ),
                if (r.doctorClinicalNotes != null && r.doctorClinicalNotes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Doctor's advice", style: text.labelMedium?.copyWith(color: AppColors.primaryDark)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(r.doctorClinicalNotes!, style: text.bodyMedium),
                      ],
                    ),
                  ),
                ],
                if (r.doctorRecommendations != null && r.doctorRecommendations!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Medicines and how to take them', style: text.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(r.doctorRecommendations!, style: text.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
