import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/referral_model.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/priority_badge.dart';
import '../../shared/widgets/sync_status_badge.dart';
import '../../shared/widgets/ui.dart';

class DoctorReviewScreen extends StatefulWidget {
  final String referralId;

  const DoctorReviewScreen({super.key, required this.referralId});

  @override
  State<DoctorReviewScreen> createState() => _DoctorReviewScreenState();
}

class _DoctorReviewScreenState extends State<DoctorReviewScreen> {
  final _clinicalNotesController = TextEditingController();
  final _recommendationsController = TextEditingController();

  ReferralStatus _selectedStatus = ReferralStatus.consulted;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final repo = context.read<HealthRepository>();
    final ref = repo.referrals.firstWhere((r) => r.id == widget.referralId);
    _clinicalNotesController.text = ref.doctorClinicalNotes ?? '';
    _recommendationsController.text = ref.doctorRecommendations ?? '';
    _selectedStatus = ref.status == ReferralStatus.pending ? ReferralStatus.consulted : ref.status;
  }

  @override
  void dispose() {
    _clinicalNotesController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_clinicalNotesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your consultation notes.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final repo = context.read<HealthRepository>();
    final doctor = context.read<AuthService>().currentUser;

    try {
      await repo.updateDoctorReview(
        referralId: widget.referralId,
        doctorId: doctor?.uid ?? 'doc-rajesh-01',
        doctorName: doctor?.displayName ?? 'Dr. Rajesh Sharma, MD',
        clinicalNotes: _clinicalNotesController.text.trim(),
        recommendations: _recommendationsController.text.trim(),
        newStatus: _selectedStatus,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review saved and shared with the ASHA (${_selectedStatus.displayName}).'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      debugPrint('DoctorReviewScreen: save failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the review. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HealthRepository>();
    final referral = repo.referrals.firstWhere((r) => r.id == widget.referralId);
    final patient = repo.getPatientById(referral.patientId);
    final screeningList = repo.screenings.where((s) => s.id == referral.screeningId).toList();
    final screening = screeningList.isNotEmpty ? screeningList.first : null;
    final textTheme = Theme.of(context).textTheme;

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Review: ${referral.patientName}', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Listen'),
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: 'Doctor Referral Review',
                hindiText: '${referral.patientName}, ${referral.priority.word}. Originating ASHA: ${referral.originatingAshaName}.',
                englishText: '${referral.patientName}, ${referral.priority.word}. Originating ASHA: ${referral.originatingAshaName}.',
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          // Header: who, how urgent, why
          InfoCard(
            accent: referral.priority.color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    PriorityBadge(priority: referral.priority),
                    SyncStatusBadge(status: referral.syncStatus),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${referral.patientName}, ${referral.patientAge} yrs, ${referral.patientGender}',
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                InfoRow('Village', referral.villageName),
                InfoRow('Phone', patient?.contactNumber ?? 'Not given'),
                InfoRow('Status', referral.status.displayName),
                InfoRow('Reason', referral.triageReason),
                if (referral.primarySymptoms.isNotEmpty) InfoRow('Symptoms', referral.primarySymptoms.join(', ')),
              ],
            ),
          ),

          // Vitals
          if (screening != null) ...[
            const SectionHeader('Vitals from field visit'),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InfoRow(
                    'Blood pressure',
                    screening.systolicBP != null ? '${screening.systolicBP!.toInt()}/${screening.diastolicBP!.toInt()} mmHg' : 'Not recorded',
                  ),
                  InfoRow('Pulse', screening.pulseRate != null ? '${screening.pulseRate!.toInt()} beats/min' : 'Not recorded'),
                  InfoRow('Temperature', screening.temperatureF != null ? '${screening.temperatureF!.toStringAsFixed(1)} °F' : 'Not recorded'),
                  InfoRow('Oxygen (SpO2)', screening.spo2Percent != null ? '${screening.spo2Percent!.toInt()}%' : 'Not recorded'),
                  InfoRow('Blood sugar', screening.bloodSugarMgDl != null ? '${screening.bloodSugarMgDl!.toInt()} mg/dL' : 'Not recorded'),
                  if (screening.lifestyleObservations.isNotEmpty) InfoRow('Observations', screening.lifestyleObservations),
                ],
              ),
            ),
          ],

          // ASHA note
          const SectionHeader('Note from ASHA'),
          InfoCard(
            color: AppColors.primarySurface,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.badge_outlined, color: AppColors.primary, size: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        referral.originatingAshaName,
                        style: textTheme.titleSmall?.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(referral.ashaNotes, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Consultation form
          const SectionHeader('Your consultation'),
          DropdownButtonFormField<ReferralStatus>(
            isExpanded: true,
            initialValue: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Referral status',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: ReferralStatus.underReview,
                child: Text('Under review'),
              ),
              DropdownMenuItem(
                value: ReferralStatus.consulted,
                child: Text('Consulted / prescribed'),
              ),
              DropdownMenuItem(
                value: ReferralStatus.escalatedToFacility,
                child: Text('Send to district hospital'),
              ),
              DropdownMenuItem(
                value: ReferralStatus.closed,
                child: Text('Closed / resolved'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedStatus = val);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _clinicalNotesController,
            minLines: 3,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Diagnosis and notes *',
              hintText: 'Clinical impression, confirmed or differential diagnosis',
              helperText: 'Required',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _recommendationsController,
            minLines: 3,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Prescription and follow-up for ASHA',
              hintText: 'Medicine and dose, diet advice, when to recheck vitals',
              alignLabelWithHint: true,
            ),
          ),

          // History
          const SectionHeader('History'),
          InfoCard(
            child: referral.statusHistory.isEmpty
                ? Text('No status changes yet.', style: textTheme.bodySmall)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in referral.statusHistory) _buildHistoryItem(context, item, dateFormat),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppSpacing.screen,
          child: AppButton(
            label: 'Save review',
            icon: Icons.check_circle_rounded,
            loading: _isSaving,
            loadingLabel: 'Saving…',
            onPressed: _submitReview,
          ),
        ),
      ),
    );
  }

  /// Turns a raw status value like "under_review" into "Under review".
  String _readableStatus(String raw) {
    final text = raw.replaceAll('_', ' ').trim().toLowerCase();
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildHistoryItem(BuildContext context, ReferralStatusLog item, DateFormat dateFormat) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_rounded, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.updatedByName} · ${_readableStatus(item.status)}', style: textTheme.titleSmall),
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(item.note!, style: textTheme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  dateFormat.format(item.timestamp),
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
