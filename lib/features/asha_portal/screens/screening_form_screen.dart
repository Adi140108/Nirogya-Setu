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
import '../../shared/widgets/ui.dart';

class ScreeningFormScreen extends StatefulWidget {
  final PatientModel? initialPatient;

  const ScreeningFormScreen({super.key, this.initialPatient});

  @override
  State<ScreeningFormScreen> createState() => _ScreeningFormScreenState();
}

class _ScreeningFormScreenState extends State<ScreeningFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

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

  /// Current step of the stepped flow (UI only).
  int _step = 0;

  static const _stepTitles = [
    'Person and vitals',
    'Symptoms',
    'Lifestyle and notes',
    'Result',
  ];

  /// The first [_dangerSignCount] entries of [_allSymptomsList] are red flags.
  static const _dangerSignCount = 7;

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

  /// Plain-language labels for the symptom checkboxes. The keys are the exact
  /// strings the rules engine expects and are what gets saved; only the
  /// on-screen wording changes here.
  static const _symptomLabels = {
    'Severe breathlessness / gasping': 'Very hard to breathe or gasping',
    'Sudden loss of speech or movement': 'Suddenly cannot speak or move',
    'Altered consciousness / fainting': 'Confused or fainting',
    'Severe continuous abdominal pain': 'Strong stomach pain that does not stop',
    'Bleeding in pregnancy / High maternal risk': 'Bleeding or serious problem in pregnancy',
    'Severe dehydration / continuous vomiting': 'Vomiting again and again, very dry',
    'Persistent cough (> 2 weeks)': 'Cough for more than 2 weeks',
    'Unexplained weight loss': 'Losing weight without reason',
    'Burning urination / dysuria': 'Burning or pain when passing urine',
    'Persistent joint pain or stiffness': 'Joint pain or stiffness that stays',
    'Non-healing skin wound / ulcer': 'Wound or sore that does not heal',
    'Dizziness or chronic fatigue': 'Dizzy or always tired',
  };

  String _symptomLabel(String value) => _symptomLabels[value] ?? value;

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
    _scrollController.dispose();
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
        const SnackBar(content: Text('Please choose the person you are checking')),
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
          content: Text(
            'Visit saved for ${_selectedPatient!.fullName}. Result: ${assessment.priority.word}. Saved on this phone.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('ScreeningFormScreen: save failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the visit. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Step navigation (presentation only; validation rules are unchanged)
  // ---------------------------------------------------------------------------

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _onNext() {
    // Only the vitals step has validators; check them before moving on so
    // errors are shown next to the fields that caused them.
    if (_step == 0 && !(_formKey.currentState?.validate() ?? true)) return;
    _goToStep(_step + 1);
  }

  void _onSave() {
    // If something on step 1 needs fixing, take the worker back there so the
    // message is visible, then let the normal save flow run its checks.
    final formValid = _formKey.currentState?.validate() ?? true;
    if (_selectedPatient == null || !formValid) _goToStep(0);
    _submitScreening();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HealthRepository>();
    final assessment = _currentAssessment ??
        const ScreeningAssessment(
          priority: HealthPriority.green,
          categoryTitle: 'GREEN — Low Risk / Routine Preventive Care',
          reason: 'No readings or symptoms entered yet.',
          recommendedNextStep: 'Go back and enter the vitals and symptoms.',
          flaggedConcerns: [],
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health check'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Listen'),
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: 'Screening Help',
                hindiText: 'Enter vitals and symptoms. The result will show as Normal, Moderate or Urgent.',
                englishText: 'Enter vitals and symptoms. The result will show as Normal, Moderate or Urgent.',
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepHeader(context),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // All steps stay mounted so typed data and validators are kept.
                    _stepBody(0, _buildVitalsStep(context, repo)),
                    _stepBody(1, _buildSymptomsStep(context)),
                    _stepBody(2, _buildLifestyleStep(context)),
                    _stepBody(3, _buildResultStep(context, assessment)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(assessment),
    );
  }

  Widget _stepBody(int index, Widget child) {
    return Visibility(
      visible: _step == index,
      maintainState: true,
      child: child,
    );
  }

  Widget _buildStepHeader(BuildContext context) {
    // Hide the live result while the keyboard is open so the fields keep
    // enough room on small phones.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showLive = _currentAssessment != null && _step < _stepTitles.length - 1 && !keyboardOpen;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepHeader(
            step: _step + 1,
            total: _stepTitles.length,
            title: _stepTitles[_step],
          ),
          if (showLive) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Flexible(
                  child: Text('Result so far', style: Theme.of(context).textTheme.bodySmall),
                ),
                const SizedBox(width: AppSpacing.sm),
                PriorityBadge(priority: _currentAssessment!.priority),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(ScreeningAssessment assessment) {
    final isLast = _step == _stepTitles.length - 1;
    final willRefer = _escalateToReferral && assessment.priority != HealthPriority.green;

    final Widget primary = isLast
        ? AppButton(
            label: willRefer ? 'Save and refer' : 'Save visit',
            icon: willRefer ? Icons.send_rounded : Icons.save_rounded,
            loading: _isSaving,
            loadingLabel: 'Saving…',
            onPressed: _isSaving ? null : _onSave,
          )
        : AppButton(
            label: 'Next',
            icon: Icons.arrow_forward_rounded,
            onPressed: _onNext,
          );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.screen,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final onBack = _isSaving ? null : () => _goToStep(_step - 1);
              if (_step == 0) return primary;

              // On narrow screens or large text, a side-by-side Back button
              // squeezes the main label onto several lines. Stack instead:
              // main action full width, Back as a text button below it.
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final narrow = constraints.maxWidth / scale < 320;

              if (narrow) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    primary,
                    const SizedBox(height: AppSpacing.xs),
                    TextButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppSizes.primaryButton),
                    child: OutlinedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: primary),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: person and vitals
  // ---------------------------------------------------------------------------

  Widget _buildVitalsStep(BuildContext context, HealthRepository repo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Who are you checking?'),
        _buildPatientSelector(repo),
        const SectionHeader('Blood pressure'),
        TextFormField(
          controller: _sysBPController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Top number (systolic)',
            suffixText: 'mmHg',
            hintText: '120',
          ),
          validator: ScreeningRulesEngine.validateSystolicBP,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _diaBPController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Bottom number (diastolic)',
            suffixText: 'mmHg',
            hintText: '80',
          ),
          validator: (v) => ScreeningRulesEngine.validateDiastolicBP(v, _sysBPController.text),
        ),
        const SectionHeader('Other readings'),
        TextFormField(
          controller: _pulseController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Pulse',
            suffixText: 'beats/min',
            hintText: '72',
          ),
          validator: ScreeningRulesEngine.validatePulse,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _tempController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Temperature',
            suffixText: '°F',
            hintText: '98.6',
          ),
          validator: ScreeningRulesEngine.validateTemperature,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _spo2Controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Oxygen level (SpO2)',
            suffixText: '%',
            hintText: '98',
          ),
          validator: ScreeningRulesEngine.validateSpo2,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _sugarController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Blood sugar (random)',
            suffixText: 'mg/dL',
            hintText: '110',
          ),
          validator: ScreeningRulesEngine.validateBloodSugar,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Leave a box empty if you did not take that reading.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPatientSelector(HealthRepository repo) {
    final patient = _selectedPatient;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _selectedPatient?.id,
          decoration: const InputDecoration(
            labelText: 'Choose a registered person',
            prefixIcon: Icon(Icons.person_search_rounded),
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
        if (patient != null) ...[
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Column(
              children: [
                InfoRow('Phone', patient.contactNumber),
                InfoRow(
                  'Long-term illness',
                  patient.chronicConditions.isEmpty ? 'None recorded' : patient.chronicConditions.join(', '),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: symptoms
  // ---------------------------------------------------------------------------

  Widget _buildSymptomsStep(BuildContext context) {
    final dangerSigns = _allSymptomsList.take(_dangerSignCount).toList();
    final otherSymptoms = _allSymptomsList.skip(_dangerSignCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Tick every problem the person tells you about. ${_selectedSymptoms.length} ticked.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SectionHeader('Danger signs'),
        _buildSymptomGroup(dangerSigns),
        const SectionHeader('Other problems'),
        _buildSymptomGroup(otherSymptoms),
      ],
    );
  }

  Widget _buildSymptomGroup(List<String> symptoms) {
    return InfoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < symptoms.length; i++) ...[
            if (i > 0) const Divider(),
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(_symptomLabel(symptoms[i])),
              value: _selectedSymptoms.contains(symptoms[i]),
              onChanged: (selected) {
                final sym = symptoms[i];
                setState(() {
                  if (selected == true) {
                    _selectedSymptoms.add(sym);
                  } else {
                    _selectedSymptoms.remove(sym);
                  }
                });
                _recalculateTriage();
              },
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: lifestyle and notes
  // ---------------------------------------------------------------------------

  Widget _buildLifestyleStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Lifestyle'),
        TextFormField(
          controller: _observationsController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Food, work and habits',
            hintText: 'For example: tobacco, pesticide work, unsafe water',
          ),
        ),
        const SectionHeader('Your notes'),
        TextFormField(
          controller: _generalNotesController,
          maxLines: 3,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            labelText: 'Other notes (optional)',
            hintText: 'Anything else, or what the person asked for',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4: result
  // ---------------------------------------------------------------------------

  Widget _buildResultStep(BuildContext context, ScreeningAssessment assessment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        _buildTriageResult(context, assessment),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'This result is a guide based on set health rules. It is not a diagnosis. '
                'A qualified doctor makes the final decision and gives any medicine.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        if (assessment.priority != HealthPriority.green) ...[
          const SectionHeader('Doctor referral'),
          _buildReferralEscalation(context),
        ],
        const SectionHeader('Check before saving'),
        _buildSummary(),
      ],
    );
  }

  Widget _buildTriageResult(BuildContext context, ScreeningAssessment assessment) {
    final text = Theme.of(context).textTheme;
    // Before any reading or symptom is entered there is no real result yet,
    // so show a neutral state instead of a triage colour.
    final checked = _currentAssessment != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: checked ? assessment.priority.surfaceColor : AppColors.surface,
        borderRadius: AppRadius.card,
        border: checked ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (checked)
            PriorityBadge(priority: assessment.priority)
          else
            const StatusTag(
              'Not checked yet',
              icon: Icons.hourglass_empty_rounded,
              color: AppColors.textSecondary,
              background: AppColors.background,
            ),
          const SizedBox(height: AppSpacing.md),
          Text(assessment.reason, style: text.titleSmall),
          if (assessment.flaggedConcerns.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final concern in assessment.flaggedConcerns)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xs / 2),
                      child: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: Text(concern, style: text.bodyMedium)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Text('Next step', style: text.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(assessment.recommendedNextStep, style: text.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildReferralEscalation(BuildContext context) {
    return InfoCard(
      accent: AppColors.secondary,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: const Text('Send to doctor'),
            subtitle: const Text("Adds this person to the PHC doctor's list"),
            value: _escalateToReferral,
            onChanged: (val) => setState(() => _escalateToReferral = val),
          ),
          if (_escalateToReferral)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: TextFormField(
                controller: _referralNotesController,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Note for the doctor (optional)',
                  hintText: 'Why this person needs to be seen',
                  alignLabelWithHint: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _reading(TextEditingController c, String unit) {
    final value = c.text.trim();
    return value.isEmpty ? 'Not taken' : '$value $unit';
  }

  Widget _buildSummary() {
    final sys = _sysBPController.text.trim();
    final dia = _diaBPController.text.trim();
    final bp = (sys.isEmpty && dia.isEmpty)
        ? 'Not taken'
        : '${sys.isEmpty ? '-' : sys}/${dia.isEmpty ? '-' : dia} mmHg';

    return InfoCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Column(
        children: [
          InfoRow(
            'Person',
            _selectedPatient?.fullName ?? 'Not chosen',
            valueColor: _selectedPatient == null ? AppColors.secondary : null,
          ),
          if (_isPregnant) const InfoRow('Pregnant', 'Yes'),
          InfoRow('Blood pressure', bp),
          InfoRow('Pulse', _reading(_pulseController, 'beats/min')),
          InfoRow('Temperature', _reading(_tempController, '°F')),
          InfoRow('Oxygen (SpO2)', _reading(_spo2Controller, '%')),
          InfoRow('Blood sugar', _reading(_sugarController, 'mg/dL')),
          InfoRow(
            'Symptoms',
            _selectedSymptoms.isEmpty ? 'None ticked' : _selectedSymptoms.map(_symptomLabel).join(', '),
          ),
        ],
      ),
    );
  }
}
