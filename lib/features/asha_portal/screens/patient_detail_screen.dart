import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/referral_model.dart';
import '../../../core/models/screening_model.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/priority_badge.dart';
import '../../shared/widgets/sync_status_badge.dart';
import '../../shared/widgets/ui.dart';
import 'screening_form_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HealthRepository>();
    final patient = repo.getPatientById(patientId);

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Citizen details')),
        body: const Center(
          child: EmptyState(
            icon: Icons.person_off_outlined,
            title: 'Citizen not found',
            message: 'This record may have been removed. Go back and try again.',
          ),
        ),
      );
    }

    final screenings = repo.getScreeningsForPatient(patientId);
    final referrals = repo.getReferralsForPatient(patientId);

    return Scaffold(
      appBar: AppBar(
        title: Text(patient.fullName, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Listen'),
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: 'Citizen Record',
                hindiText: '${patient.fullName}, ${patient.age} yrs, village ${patient.villageName}. Total screenings: ${screenings.length}.',
                englishText: '${patient.fullName}, ${patient.age} yrs. Total screenings: ${screenings.length}.',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderCard(patient: patient),
            const SectionHeader('Details'),
            _buildDetailsCard(patient),
            SectionHeader('Doctor referrals (${referrals.length})'),
            _buildReferralsSection(referrals),
            SectionHeader('Past screenings (${screenings.length})'),
            _buildScreeningHistorySection(screenings),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppSpacing.screen,
          child: AppButton(
            label: 'New screening',
            icon: Icons.add_chart_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScreeningFormScreen(initialPatient: patient),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(PatientModel patient) {
    return InfoCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoRow('Phone', patient.contactNumber),
          if (patient.guardianName != null && patient.guardianName!.isNotEmpty)
            InfoRow('Guardian', patient.guardianName!),
          if (patient.householdId != null && patient.householdId!.isNotEmpty)
            InfoRow('Household', patient.householdId!),
          if (patient.isPregnant)
            const InfoRow('Pregnant', 'Yes, pregnancy check-ups (ANC)', valueColor: AppColors.secondary),
          InfoRow(
            'Long-term illness',
            patient.chronicConditions.isEmpty ? 'None recorded' : patient.chronicConditions.join(', '),
          ),
          if (patient.notes != null && patient.notes!.isNotEmpty)
            InfoRow('Notes', patient.notes!),
        ],
      ),
    );
  }

  Widget _buildReferralsSection(List<ReferralModel> referrals) {
    if (referrals.isEmpty) {
      return const InfoCard(
        child: EmptyState(
          icon: Icons.local_hospital_outlined,
          title: 'No doctor referrals',
          message: 'Referrals appear here after an urgent or moderate screening.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < referrals.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _ReferralCard(referral: referrals[i]),
        ],
      ],
    );
  }

  Widget _buildScreeningHistorySection(List<ScreeningModel> screenings) {
    if (screenings.isEmpty) {
      return const InfoCard(
        child: EmptyState(
          icon: Icons.history_rounded,
          title: 'No screenings yet',
          message: 'Tap "New screening" below to start one.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < screenings.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _ScreeningCard(screening: screenings[i]),
        ],
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final PatientModel patient;
  const _HeaderCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InfoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialAvatar(patient.fullName, size: AppSizes.button),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.fullName, style: text.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${patient.age} yrs  ·  ${patient.gender}  ·  ${patient.villageName}',
                  style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SyncStatusBadge(status: patient.syncStatus),
                    if (patient.isPregnant) const StatusTag('Pregnant', icon: Icons.pregnant_woman_rounded),
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

class _ReferralCard extends StatelessWidget {
  final ReferralModel referral;
  const _ReferralCard({required this.referral});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ref = referral;
    final notes = ref.doctorClinicalNotes;
    final advice = ref.doctorRecommendations;

    return InfoCard(
      accent: ref.priority.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PriorityBadge(priority: ref.priority),
              StatusTag(ref.status.displayName, icon: Icons.assignment_outlined),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Reason', style: text.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(ref.triageReason, style: text.bodyMedium),
          if (notes != null && notes.isNotEmpty) ...[
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
                  Row(
                    children: [
                      const Icon(Icons.medical_services_outlined, size: 20, color: AppColors.primaryDark),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Doctor\'s note · ${ref.assignedDoctorName ?? "Medical Officer"}',
                          style: text.titleSmall?.copyWith(color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(notes, style: text.bodyMedium),
                  if (advice != null && advice.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text('Advice', style: text.bodySmall),
                    Text(advice, style: text.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScreeningCard extends StatelessWidget {
  final ScreeningModel screening;
  const _ScreeningCard({required this.screening});

  static final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = screening;

    return InfoCard(
      accent: s.priority.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PriorityBadge(priority: s.priority),
              SyncStatusBadge(status: s.syncStatus),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_dateFormat.format(s.createdAt), style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(s.reason, style: text.bodyMedium),
          if (s.systolicBP != null && s.diastolicBP != null)
            InfoRow('Blood pressure', '${s.systolicBP!.toInt()}/${s.diastolicBP!.toInt()} mmHg'),
          if (s.pulseRate != null) InfoRow('Pulse', '${s.pulseRate!.toInt()} beats/min'),
          if (s.temperatureF != null) InfoRow('Temperature', '${s.temperatureF!.toStringAsFixed(1)} °F'),
          if (s.spo2Percent != null) InfoRow('Oxygen (SpO2)', '${s.spo2Percent!.toInt()}%'),
          if (s.bloodSugarMgDl != null) InfoRow('Blood sugar', '${s.bloodSugarMgDl!.toInt()} mg/dL'),
        ],
      ),
    );
  }
}
