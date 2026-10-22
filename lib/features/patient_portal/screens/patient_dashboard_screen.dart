import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/referral_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/network_banner.dart';
import '../../shared/widgets/priority_badge.dart';
import '../../awareness_hub/screens/awareness_hub_screen.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final repo = context.watch<HealthRepository>();
    final user = authService.currentUser;

    // Look for matching patient record or use demo patient
    final patient = repo.patients.firstWhere(
      (p) => p.id == (user?.uid ?? '') || p.fullName == (user?.displayName ?? ''),
      orElse: () => repo.patients.first,
    );

    final screenings = repo.getScreeningsForPatient(patient.id);
    final referrals = repo.getReferralsForPatient(patient.id);
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patient.fullName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'गाँव ${patient.villageName} • नागरिक स्वास्थ्य कार्ड',
              style: const TextStyle(fontSize: 11, color: Color(0xFFF3E5F5)),
            ),
          ],
        ),
        backgroundColor: AppColors.rolePatient,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: 'Audio guidance for villager',
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: 'स्वास्थ्य विवरण / Health Card',
                hindiText: 'नमस्ते ${patient.fullName} जी, यहाँ आपकी पिछली जांच और डॉक्टर की सलाह उपलब्ध है।',
                englishText: 'Welcome ${patient.fullName}. View your screening history and doctor notes.',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => authService.signOut(),
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
                  // Prominent Awareness Hub Card (Direct access)
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00796B), Color(0xFF004D40)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00796B).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AwarenessHubScreen(isPublicAccess: false),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 28),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'स्वास्थ्य जागरूकता केंद्र / Health Hub',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'डेंगू रोकथाम, गर्मी में बचाव, और पोषण के शैक्षिक वीडियो देखें (ऑफलाइन भी उपलब्ध)',
                                      style: TextStyle(fontSize: 11, color: Color(0xFFE0F2F1)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Health Profile Card
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
                            Icon(Icons.badge_outlined, color: AppColors.rolePatient, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'स्वास्थ्य प्रोफाइल / Health Profile',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildRow('Age & Gender', '${patient.age} years, ${patient.gender}'),
                        _buildRow('Village / गाँव', patient.villageName),
                        _buildRow('Phone / फ़ोन', patient.contactNumber),
                        if (patient.householdId != null)
                          _buildRow('Household ID', patient.householdId!),
                        if (patient.chronicConditions.isNotEmpty)
                          _buildRow('Conditions', patient.chronicConditions.join(', ')),
                        if (patient.isPregnant)
                          _buildRow('Maternal Care', 'Antenatal Mother (Care Active)', isAlert: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Doctor Consultations & Prescriptions
                  const Text(
                    'डॉक्टर परामर्श / Doctor Consultations & Prescriptions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                          'No doctor referrals or prescriptions recorded.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...referrals.map((r) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                            const SizedBox(height: 10),
                            Text(
                              'Doctor: ${r.assignedDoctorName ?? "Primary Health Centre Doctor"}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (r.doctorClinicalNotes != null && r.doctorClinicalNotes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'सलाह: ${r.doctorClinicalNotes!}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                            if (r.doctorRecommendations != null && r.doctorRecommendations!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'दवा / निर्देश: ${r.doctorRecommendations!}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 18),

                  // My Screenings History
                  const Text(
                    'मेरी पूर्व जांचें / My Preventive Screenings',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                          'No screenings recorded yet.',
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
}
