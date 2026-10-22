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
        const SnackBar(content: Text('Please enter clinical consultation notes.')),
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
          backgroundColor: AppColors.riskGreen,
          content: Text('✓ Clinical notes saved and synced to ASHA portal (${_selectedStatus.displayName}).'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.riskRed, content: Text('Error saving: $e')),
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

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Review: ${referral.patientName}'),
        backgroundColor: AppColors.roleDoctor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: 'Audio summary of referral',
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: 'रेफरल समीक्षा / Doctor Review',
                hindiText: '${referral.patientName}, प्राथमिकता: ${referral.priority.name.toUpperCase()}। आशा कार्यकर्ता: ${referral.originatingAshaName}',
                englishText: '${referral.patientName}, priority ${referral.priority.name.toUpperCase()}. Originating ASHA: ${referral.originatingAshaName}.',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Referral Priority & Header
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
                  Row(
                    children: [
                      PriorityBadge(priority: referral.priority),
                      const Spacer(),
                      SyncStatusBadge(status: referral.syncStatus),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${referral.patientName} (${referral.patientAge}y, ${referral.patientGender})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Village: ${referral.villageName} • Contact: ${patient?.contactNumber ?? "N/A"}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Triage Trigger: ${referral.triageReason}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        if (referral.primarySymptoms.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Reported Symptoms: ${referral.primarySymptoms.join(", ")}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Screening Vitals Inspection
            if (screening != null) ...[
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
                    const Row(
                      children: [
                        Icon(Icons.monitor_heart_outlined, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Recorded Vitals from Field Screening',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildVitalPill('BP', screening.systolicBP != null ? '${screening.systolicBP!.toInt()}/${screening.diastolicBP!.toInt()} mmHg' : 'N/A'),
                        _buildVitalPill('Pulse', screening.pulseRate != null ? '${screening.pulseRate!.toInt()} bpm' : 'N/A'),
                        _buildVitalPill('Temp', screening.temperatureF != null ? '${screening.temperatureF!.toStringAsFixed(1)}°F' : 'N/A'),
                        _buildVitalPill('SpO2', screening.spo2Percent != null ? '${screening.spo2Percent!.toInt()}%' : 'N/A'),
                        _buildVitalPill('Blood Sugar', screening.bloodSugarMgDl != null ? '${screening.bloodSugarMgDl!.toInt()} mg/dL' : 'N/A'),
                      ],
                    ),
                    if (screening.lifestyleObservations.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Observations: ${screening.lifestyleObservations}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Originating ASHA Notes
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ASHA Field Note (${referral.originatingAshaName}):',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          referral.ashaNotes,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Doctor Consultation Input Form
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
                  const Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: AppColors.roleDoctor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Doctor Clinical Consultation & Notes *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ReferralStatus>(
                    isExpanded: true,
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Referral Status / स्थिति',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ReferralStatus.underReview,
                        child: Text('Under Clinical Review / समीक्षा जारी'),
                      ),
                      DropdownMenuItem(
                        value: ReferralStatus.consulted,
                        child: Text('Consulted / Prescribed / परामर्श पूर्ण'),
                      ),
                      DropdownMenuItem(
                        value: ReferralStatus.escalatedToFacility,
                        child: Text('Escalate to District Hospital / उच्च अस्पताल रेफर'),
                      ),
                      DropdownMenuItem(
                        value: ReferralStatus.closed,
                        child: Text('Closed / Resolved / समाप्त'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clinicalNotesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Diagnosis / Assessment Notes *',
                      hintText: 'Enter clinical impressions, confirmed diagnosis or differential diagnosis...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _recommendationsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Prescriptions & ASHA Follow-up Instructions',
                      hintText: 'Prescribed medication dosage, dietary advice, repeat vitals schedule...',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status Change Audit History
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
                  const Row(
                    children: [
                      Icon(Icons.history_toggle_off_rounded, color: AppColors.textSecondary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Referral Audit Trail & Timestamps',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (referral.statusHistory.isEmpty)
                    const Text('No status changes recorded.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                  else
                    ...referral.statusHistory.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle, size: 8, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.updatedByName} • ${item.status.toUpperCase()}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  if (item.note != null && item.note!.isNotEmpty)
                                    Text(item.note!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  Text(
                                    dateFormat.format(item.timestamp),
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roleDoctor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _submitReview,
              icon: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isSaving ? 'Submitting Review...' : 'Save Clinical Review & Sync Status',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
