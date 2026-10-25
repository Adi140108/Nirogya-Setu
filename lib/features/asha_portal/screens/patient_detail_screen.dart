import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/priority_badge.dart';
import '../../shared/widgets/sync_status_badge.dart';
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
        appBar: AppBar(title: const Text('Citizen Details')),
        body: const Center(child: Text('Citizen record not found.')),
      );
    }

    final screenings = repo.getScreeningsForPatient(patientId);
    final referrals = repo.getReferralsForPatient(patientId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(patient.fullName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: 'Audio summary of citizen',
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Demographics Profile Card
            _buildProfileCard(patient),
            const SizedBox(height: 16),

            // Quick Action Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScreeningFormScreen(initialPatient: patient),
                  ),
                );
              },
              icon: const Icon(Icons.add_chart_rounded),
              label: const Text(
                'Conduct New Health Screening',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Active Referrals & Doctor Notes
            _buildReferralsSection(referrals),
            const SizedBox(height: 20),

            // Screening History
            _buildScreeningHistorySection(screenings),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(PatientModel patient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFBF4E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  patient.fullName.isNotEmpty ? patient.fullName[0] : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${patient.age} years • ${patient.gender} • ${patient.villageName}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              SyncStatusBadge(status: patient.syncStatus),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Mobile Phone', patient.contactNumber),
          if (patient.guardianName != null && patient.guardianName!.isNotEmpty)
            _buildInfoRow('Guardian / Head', patient.guardianName!),
          if (patient.householdId != null && patient.householdId!.isNotEmpty)
            _buildInfoRow('Household ID', patient.householdId!),
          if (patient.isPregnant)
            _buildInfoRow('Maternal Status', 'Antenatal Mother (Pregnant)', isAlert: true),
          _buildInfoRow(
            'Chronic Conditions',
            patient.chronicConditions.isEmpty ? 'None recorded' : patient.chronicConditions.join(', '),
          ),
          if (patient.notes != null && patient.notes!.isNotEmpty)
            _buildInfoRow('Field Notes', patient.notes!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isAlert ? FontWeight.bold : FontWeight.w600,
                color: isAlert ? AppColors.riskRed : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralsSection(List<dynamic> referrals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.outgoing_mail, color: AppColors.roleDoctor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Doctor Referrals & Consultations',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Spacer(),
            Text('${referrals.length} active', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 10),
        if (referrals.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFFBF4E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No active doctor referrals for this citizen.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...referrals.map((ref) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
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
                      PriorityBadge(priority: ref.priority),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ref.status.displayName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Triage: ${ref.triageReason}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  if (ref.doctorClinicalNotes != null && ref.doctorClinicalNotes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4E6CC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medical_services_rounded, size: 14, color: AppColors.roleDoctor),
                              const SizedBox(width: 4),
                              Text(
                                'Doctor Note (${ref.assignedDoctorName ?? "Medical Officer"}):',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.roleDoctor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ref.doctorClinicalNotes,
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          ),
                          if (ref.doctorRecommendations != null && ref.doctorRecommendations.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Recommendations: ${ref.doctorRecommendations}',
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildScreeningHistorySection(List<dynamic> screenings) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Screening Records History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Spacer(),
            Text('${screenings.length} total', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 10),
        if (screenings.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFFBF4E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No screening recorded yet for this citizen.',
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
                      SyncStatusBadge(status: s.syncStatus),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateFormat.format(s.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.reason,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: [
                      if (s.systolicBP != null && s.diastolicBP != null)
                        Text('BP: ${s.systolicBP.toInt()}/${s.diastolicBP.toInt()}', style: const TextStyle(fontSize: 11)),
                      if (s.pulseRate != null)
                        Text('Pulse: ${s.pulseRate.toInt()} bpm', style: const TextStyle(fontSize: 11)),
                      if (s.temperatureF != null)
                        Text('Temp: ${s.temperatureF.toStringAsFixed(1)}°F', style: const TextStyle(fontSize: 11)),
                      if (s.spo2Percent != null)
                        Text('SpO2: ${s.spo2Percent.toInt()}%', style: const TextStyle(fontSize: 11)),
                      if (s.bloodSugarMgDl != null)
                        Text('RBS: ${s.bloodSugarMgDl.toInt()} mg/dL', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
