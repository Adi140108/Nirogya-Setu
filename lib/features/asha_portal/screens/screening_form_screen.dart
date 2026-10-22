import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/screening_rules.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/screening_model.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/priority_badge.dart';

class ScreeningFormScreen extends StatefulWidget {
  final PatientModel? initialPatient;

  const ScreeningFormScreen({super.key, this.initialPatient});

  @override
  State<ScreeningFormScreen> createState() => _ScreeningFormScreenState();
}

class _ScreeningFormScreenState extends State<ScreeningFormScreen> {
  final _formKey = GlobalKey<FormState>();

  PatientModel? _selectedPatient;

  // Controllers for Vitals
  final _sysBPController = TextEditingController();
  final _diaBPController = TextEditingController();
  final _pulseController = TextEditingController();
  final _tempController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _sugarController = TextEditingController();
  final _observationsController = TextEditingController();
  final _generalNotesController = TextEditingController();

  final List<String> _selectedSymptoms = [];
  bool _isPregnant = false;
  bool _escalateToReferral = false;
  final _referralNotesController = TextEditingController();

  ScreeningAssessment? _currentAssessment;
  bool _isSaving = false;

  final _allSymptomsList = [
    // Red Flags
    'Chest pain or pressure',
    'Severe breathlessness / gasping',
    'Sudden loss of speech or movement',
    'Altered consciousness / fainting',
    'Severe continuous abdominal pain',
    'Bleeding in pregnancy / High maternal risk',
    'Severe dehydration / continuous vomiting',
    // Yellow Flags
    'Persistent cough (> 2 weeks)',
    'Unexplained weight loss',
    'High fever for more than 3 days',
    'Burning urination / dysuria',
    'Swelling in legs or feet',
    'Persistent joint pain or stiffness',
    'Non-healing skin wound / ulcer',
    'Dizziness or chronic fatigue',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.initialPatient;
    if (_selectedPatient != null) {
      _isPregnant = _selectedPatient!.isPregnant;
    }

    _sysBPController.addListener(_recalculateTriage);
    _diaBPController.addListener(_recalculateTriage);
    _pulseController.addListener(_recalculateTriage);
    _tempController.addListener(_recalculateTriage);
    _spo2Controller.addListener(_recalculateTriage);
    _sugarController.addListener(_recalculateTriage);
  }

  @override
  void dispose() {
    _sysBPController.dispose();
    _diaBPController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _spo2Controller.dispose();
    _sugarController.dispose();
    _observationsController.dispose();
    _generalNotesController.dispose();
    _referralNotesController.dispose();
    super.dispose();
  }

  void _recalculateTriage() {
    final sys = double.tryParse(_sysBPController.text);
    final dia = double.tryParse(_diaBPController.text);
    final pulse = double.tryParse(_pulseController.text);
    final temp = double.tryParse(_tempController.text);
    final spo2 = double.tryParse(_spo2Controller.text);
    final sugar = double.tryParse(_sugarController.text);

    final assessment = ScreeningRulesEngine.evaluate(
      systolicBP: sys,
      diastolicBP: dia,
      pulseRate: pulse,
      temperatureF: temp,
      bloodSugarMgDl: sugar,
      spo2Percent: spo2,
      selectedSymptoms: _selectedSymptoms,
      isPregnant: _isPregnant,
      notes: _observationsController.text,
    );

    setState(() {
      _currentAssessment = assessment;
      if (assessment.priority == HealthPriority.red || assessment.priority == HealthPriority.yellow) {
        _escalateToReferral = true;
      }
    });
  }

  Future<void> _submitScreening() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a villager for screening')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repo = context.read<HealthRepository>();
    final ashaUser = context.read<AuthService>().currentUser;

    final sys = double.tryParse(_sysBPController.text);
    final dia = double.tryParse(_diaBPController.text);
    final pulse = double.tryParse(_pulseController.text);
    final temp = double.tryParse(_tempController.text);
    final spo2 = double.tryParse(_spo2Controller.text);
    final sugar = double.tryParse(_sugarController.text);

    final assessment = _currentAssessment ??
        ScreeningRulesEngine.evaluate(
          systolicBP: sys,
          diastolicBP: dia,
          pulseRate: pulse,
          temperatureF: temp,
          bloodSugarMgDl: sugar,
          spo2Percent: spo2,
          selectedSymptoms: _selectedSymptoms,
          isPregnant: _isPregnant,
          notes: _observationsController.text,
        );

    try {
      final screeningRecord = ScreeningModel(
        id: '',
        patientId: _selectedPatient!.id,
        patientName: _selectedPatient!.fullName,
        ashaId: ashaUser?.uid ?? 'asha-shanti-01',
        ashaName: ashaUser?.displayName ?? 'Shanti Devi',
        villageId: _selectedPatient!.villageId,
        systolicBP: sys,
        diastolicBP: dia,
        pulseRate: pulse,
        temperatureF: temp,
        bloodSugarMgDl: sugar,
        spo2Percent: spo2,
        symptoms: _selectedSymptoms,
        isPregnant: _isPregnant,
        lifestyleObservations: _observationsController.text.trim(),
        generalNotes: _generalNotesController.text.trim(),
        priority: assessment.priority,
        categoryTitle: assessment.categoryTitle,
        reason: assessment.reason,
        recommendedNextStep: assessment.recommendedNextStep,
        flaggedConcerns: assessment.flaggedConcerns,
        createdAt: DateTime.now(),
      );

      final savedScreening = await repo.saveScreening(screeningRecord);

      // If user or rule escalates to doctor referral
      if (_escalateToReferral && assessment.priority != HealthPriority.green) {
        await repo.createReferral(
          patientId: _selectedPatient!.id,
          patientName: _selectedPatient!.fullName,
          patientAge: _selectedPatient!.age,
          patientGender: _selectedPatient!.gender,
          villageId: _selectedPatient!.villageId,
          villageName: _selectedPatient!.villageName,
          screeningId: savedScreening.id,
          priority: assessment.priority,
          triageReason: assessment.reason,
          primarySymptoms: _selectedSymptoms,
          originatingAshaId: ashaUser?.uid ?? 'asha-shanti-01',
          originatingAshaName: ashaUser?.displayName ?? 'Shanti Devi',
          ashaNotes: _referralNotesController.text.trim().isNotEmpty
              ? _referralNotesController.text.trim()
              : 'Referral generated from screening. Reason: ${assessment.reason}',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.riskGreen,
          content: Text(
            '✓ Screening recorded for ${_selectedPatient!.fullName}. Priority: ${assessment.priority.name.toUpperCase()} (Saved locally).',
          ),
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
    final assessment = _currentAssessment ??
        const ScreeningAssessment(
          priority: HealthPriority.green,
          categoryTitle: 'GREEN — Low Risk / Routine Preventive Care',
          reason: 'Awaiting vital parameters and reported symptoms.',
          recommendedNextStep: 'Complete vitals check and symptom inquiry.',
          flaggedConcerns: [],
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('सामान्य स्वास्थ्य जांच / General Screening'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: 'Audio guidance for screening form',
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: 'जांच सहायता / Screening Help',
                hindiText: 'रक्तचाप, नाड़ी, बुखार, ऑक्सीजन और शुगर के आंकड़े दर्ज करें। सिस्टम तुरंत हरी, पीली या लाल श्रेणी तय करेगा।',
                englishText: 'Enter vitals and symptoms. The system will categorize into Green, Yellow or Red priority.',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Patient Selector
              _buildPatientSelectionCard(repo),
              const SizedBox(height: 16),

              // Live Triage Result Card (Dynamic Assessment)
              _buildLiveTriageCard(assessment),
              const SizedBox(height: 16),

              // Vitals Inputs
              _buildVitalsCard(),
              const SizedBox(height: 16),

              // Symptoms Checklist
              _buildSymptomsCard(),
              const SizedBox(height: 16),

              // Lifestyle & Observations
              _buildObservationsCard(),
              const SizedBox(height: 16),

              // Escalation to Referral Card
              if (assessment.priority != HealthPriority.green) ...[
                _buildReferralEscalationCard(),
                const SizedBox(height: 16),
              ],

              // Statutory Decision Support Disclaimer
              _buildClinicalDisclaimer(),
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: assessment.priority == HealthPriority.red
                      ? AppColors.riskRed
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isSaving ? null : _submitScreening,
                icon: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving
                      ? 'सुरक्षित किया जा रहा है...'
                      : (_escalateToReferral && assessment.priority != HealthPriority.green
                          ? 'Save Screening & Create Referral'
                          : 'Save Screening Record'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSelectionCard(HealthRepository repo) {
    return Container(
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
              Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'मरीज का चयन / Select Villager *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedPatient?.id,
            decoration: const InputDecoration(
              labelText: 'Select Registered Villager',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            items: repo.patients.map((p) {
              return DropdownMenuItem(
                value: p.id,
                child: Text(
                  '${p.fullName} (${p.age}y, ${p.gender}) — ${p.villageName}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final patient = repo.getPatientById(val);
                setState(() {
                  _selectedPatient = patient;
                  if (patient != null) {
                    _isPregnant = patient.isPregnant;
                  }
                });
                _recalculateTriage();
              }
            },
          ),
          if (_selectedPatient != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Contact: ${_selectedPatient!.contactNumber} | Conditions: ${_selectedPatient!.chronicConditions.isEmpty ? "None" : _selectedPatient!.chronicConditions.join(", ")}',
                      style: const TextStyle(fontSize: 11, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveTriageCard(ScreeningAssessment assessment) {
    Color bg;
    Color border;
    Color fg;

    switch (assessment.priority) {
      case HealthPriority.red:
        bg = AppColors.riskRedSurface;
        border = AppColors.riskRed;
        fg = AppColors.riskRed;
        break;
      case HealthPriority.yellow:
        bg = AppColors.riskYellowSurface;
        border = AppColors.riskYellow;
        fg = AppColors.riskYellow;
        break;
      case HealthPriority.green:
        bg = AppColors.riskGreenSurface;
        border = AppColors.riskGreen;
        fg = AppColors.riskGreen;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PriorityBadge(priority: assessment.priority),
              const Spacer(),
              const Text(
                'Live Triage Engine',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            assessment.reason,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_right_alt_rounded, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Next Step: ${assessment.recommendedNextStep}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard() {
    return Container(
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
              Icon(Icons.monitor_heart_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'शारीरिक माप / Vital Signs',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _sysBPController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Systolic BP',
                    suffixText: 'mmHg',
                    hintText: '120',
                  ),
                  validator: ScreeningRulesEngine.validateSystolicBP,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _diaBPController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Diastolic BP',
                    suffixText: 'mmHg',
                    hintText: '80',
                  ),
                  validator: (v) => ScreeningRulesEngine.validateDiastolicBP(v, _sysBPController.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pulseController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pulse Rate',
                    suffixText: 'bpm',
                    hintText: '72',
                  ),
                  validator: ScreeningRulesEngine.validatePulse,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _tempController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Temperature',
                    suffixText: '°F',
                    hintText: '98.6',
                  ),
                  validator: ScreeningRulesEngine.validateTemperature,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _spo2Controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Oxygen (SpO2)',
                    suffixText: '%',
                    hintText: '98',
                  ),
                  validator: ScreeningRulesEngine.validateSpo2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _sugarController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Random Sugar',
                    suffixText: 'mg/dL',
                    hintText: '110',
                  ),
                  validator: ScreeningRulesEngine.validateBloodSugar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return Container(
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
              Icon(Icons.checklist_rtl_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'लक्षण और शिकायतें / Symptoms & Complaints',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Select all symptoms reported by villager:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _allSymptomsList.map((sym) {
              final isSelected = _selectedSymptoms.contains(sym);
              final isRed = sym.contains('pain') ||
                  sym.contains('breathlessness') ||
                  sym.contains('fainting') ||
                  sym.contains('pregnancy');

              return FilterChip(
                label: Text(sym, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                selectedColor: isRed ? AppColors.riskRedSurface : AppColors.primarySurface,
                checkmarkColor: isRed ? AppColors.riskRed : AppColors.primary,
                side: BorderSide(
                  color: isSelected
                      ? (isRed ? AppColors.riskRed : AppColors.primary)
                      : AppColors.border,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSymptoms.add(sym);
                    } else {
                      _selectedSymptoms.remove(sym);
                    }
                  });
                  _recalculateTriage();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationsCard() {
    return Container(
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
              Icon(Icons.notes_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'अवलोकन और आदतें / Observations & Lifestyle',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _observationsController,
            decoration: const InputDecoration(
              labelText: 'Lifestyle / Diet / Work Observations',
              hintText: 'e.g. Tobacco usage, pesticide exposure in fields, poor water source...',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _generalNotesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'General ASHA Field Notes',
              hintText: 'Any additional notes or patient requests...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralEscalationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Escalate to Doctor Referral / डॉक्टर रेफरल बनाएं',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary),
            ),
            subtitle: const Text(
              'Transmits screening triage to the Doctor Portal queue',
              style: TextStyle(fontSize: 11),
            ),
            value: _escalateToReferral,
            activeColor: AppColors.secondary,
            onChanged: (val) => setState(() => _escalateToReferral = val),
          ),
          if (_escalateToReferral) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _referralNotesController,
              decoration: const InputDecoration(
                labelText: 'Referral Reason / Note for Doctor',
                hintText: 'Urgent reason or clinical observation for PHC Doctor...',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClinicalDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Clinical Decision Support Notice: Risk categories (Green/Yellow/Red) are rule-based clinical guides to assist preventive triage and are NOT final medical diagnoses. Final diagnostic decisions and medical prescriptions remain with qualified healthcare practitioners.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
