enum HealthPriority {
  green,
  yellow,
  red,
}

class ScreeningAssessment {
  final HealthPriority priority;
  final String categoryTitle;
  final String reason;
  final String recommendedNextStep;
  final List<String> flaggedConcerns;

  const ScreeningAssessment({
    required this.priority,
    required this.categoryTitle,
    required this.reason,
    required this.recommendedNextStep,
    required this.flaggedConcerns,
  });
}

class ScreeningRulesEngine {
  /// Evaluates patient vitals and reported symptoms according to national rural preventive guidelines.
  /// Decision Support only — Clinical judgment remains with qualified medical personnel.
  static ScreeningAssessment evaluate({
    required double? systolicBP,
    required double? diastolicBP,
    required double? pulseRate,
    required double? temperatureF,
    required double? bloodSugarMgDl,
    required double? spo2Percent,
    required List<String> selectedSymptoms,
    required bool isPregnant,
    required String notes,
  }) {
    List<String> redFlags = [];
    List<String> yellowFlags = [];

    // --- 1. Vital Signs Validation & Risk Rules ---

    // Blood Pressure
    if (systolicBP != null && diastolicBP != null) {
      if (systolicBP >= 180 || diastolicBP >= 110) {
        redFlags.add('Hypertensive Crisis (BP: ${systolicBP.toInt()}/${diastolicBP.toInt()} mmHg)');
      } else if (systolicBP >= 140 || diastolicBP >= 90) {
        yellowFlags.add('Elevated Blood Pressure (Stage 1/2 HTN: ${systolicBP.toInt()}/${diastolicBP.toInt()} mmHg)');
      } else if (systolicBP < 90 || diastolicBP < 60) {
        yellowFlags.add('Hypotension / Low Blood Pressure (BP: ${systolicBP.toInt()}/${diastolicBP.toInt()} mmHg)');
      }
    }

    // Oxygen Saturation (SpO2)
    if (spo2Percent != null) {
      if (spo2Percent < 90) {
        redFlags.add('Critical Hypoxia (SpO2: ${spo2Percent.toInt()}%)');
      } else if (spo2Percent < 94) {
        yellowFlags.add('Mild-to-Moderate Hypoxemia (SpO2: ${spo2Percent.toInt()}%)');
      }
    }

    // Pulse Rate
    if (pulseRate != null) {
      if (pulseRate > 130 || pulseRate < 45) {
        redFlags.add('Severe Tachycardia/Bradycardia (Pulse: ${pulseRate.toInt()} bpm)');
      } else if (pulseRate > 100 || pulseRate < 55) {
        yellowFlags.add('Abnormal Pulse Rate (Pulse: ${pulseRate.toInt()} bpm)');
      }
    }

    // Temperature (Fahrenheit)
    if (temperatureF != null) {
      if (temperatureF >= 104.0) {
        redFlags.add('Severe Hyperpyrexia (Temp: ${temperatureF.toStringAsFixed(1)}°F)');
      } else if (temperatureF >= 100.4) {
        yellowFlags.add('Fever detected (Temp: ${temperatureF.toStringAsFixed(1)}°F)');
      }
    }

    // Random Blood Sugar
    if (bloodSugarMgDl != null) {
      if (bloodSugarMgDl >= 300 || bloodSugarMgDl < 55) {
        redFlags.add('Critical Glycemic Event (RBS: ${bloodSugarMgDl.toInt()} mg/dL)');
      } else if (bloodSugarMgDl >= 200 || bloodSugarMgDl < 70) {
        yellowFlags.add('Elevated Blood Glucose (RBS: ${bloodSugarMgDl.toInt()} mg/dL)');
      }
    }

    // --- 2. Red Flag Symptoms ---
    final severeSymptoms = [
      'Chest pain or pressure',
      'Severe breathlessness / gasping',
      'Sudden loss of speech or movement',
      'Altered consciousness / fainting',
      'Severe continuous abdominal pain',
      'Bleeding in pregnancy / High maternal risk',
      'Severe dehydration / continuous vomiting',
    ];

    for (final sym in severeSymptoms) {
      if (selectedSymptoms.contains(sym)) {
        redFlags.add('High-risk symptom: $sym');
      }
    }

    // --- 3. Yellow Flag Symptoms ---
    final moderateSymptoms = [
      'Persistent cough (> 2 weeks)',
      'Unexplained weight loss',
      'High fever for more than 3 days',
      'Burning urination / dysuria',
      'Swelling in legs or feet',
      'Persistent joint pain or stiffness',
      'Non-healing skin wound / ulcer',
      'Dizziness or chronic fatigue',
    ];

    for (final sym in moderateSymptoms) {
      if (selectedSymptoms.contains(sym)) {
        yellowFlags.add('Symptoms noted: $sym');
      }
    }

    // Pregnancy check
    if (isPregnant && yellowFlags.isNotEmpty) {
      // Elevate risk for antenatal mothers with moderate flags
      redFlags.add('Maternal Health Warning: Antenatal mother exhibiting warning symptoms');
    }

    // --- 4. Priority Categorization ---
    if (redFlags.isNotEmpty) {
      return ScreeningAssessment(
        priority: HealthPriority.red,
        categoryTitle: 'RED — High Urgency / Immediate Escalation',
        reason: 'Critical indicators observed: ${redFlags.join(", ")}.',
        recommendedNextStep:
            'Immediate referral to Primary Health Centre (PHC) or District Hospital within 24 hours. ASHA must arrange emergency transport or accompany patient if symptoms deteriorate.',
        flaggedConcerns: [...redFlags, ...yellowFlags],
      );
    } else if (yellowFlags.isNotEmpty) {
      return ScreeningAssessment(
        priority: HealthPriority.yellow,
        categoryTitle: 'YELLOW — Moderate Urgency / Medical Review Needed',
        reason: 'Borderline or chronic warning signs detected: ${yellowFlags.join(", ")}.',
        recommendedNextStep:
            'Refer for Doctor Consultation at the nearest Health and Wellness Centre (HWC) within 7 days. Provide preventive counseling and schedule a 5-day follow-up.',
        flaggedConcerns: yellowFlags,
      );
    } else {
      return const ScreeningAssessment(
        priority: HealthPriority.green,
        categoryTitle: 'GREEN — Low Risk / Routine Preventive Care',
        reason: 'All recorded vital parameters and observations are within expected normal thresholds.',
        recommendedNextStep:
            'Continue regular healthy diet and physical activity. Provide standard preventive education via Awareness Hub. Schedule routine follow-up screening in 3-6 months.',
        flaggedConcerns: [],
      );
    }
  }

  /// Validation of inputs for biological plausibility
  static String? validateSystolicBP(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value);
    if (n == null) return 'Must be a valid number';
    if (n < 50 || n > 260) return 'Implausible BP (50-260 mmHg)';
    return null;
  }

  static String? validateDiastolicBP(String? value, String? systolic) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value);
    if (n == null) return 'Must be a valid number';
    if (n < 30 || n > 160) return 'Implausible BP (30-160 mmHg)';
    if (systolic != null && systolic.isNotEmpty) {
      final s = double.tryParse(systolic);
      if (s != null && n >= s) return 'Diastolic must be lower than systolic';
    }
    return null;
  }

  static String? validatePulse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value);
    if (n == null) return 'Must be a valid number';
    if (n < 30 || n > 220) return 'Implausible pulse (30-220 bpm)';
    return null;
  }

  static String? validateTemperature(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value);
    if (n == null) return 'Must be a valid number';
    if (n < 92.0 || n > 108.0) return 'Implausible temp (92.0-108.0°F)';
    return null;
  }

  static String? validateSpo2(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value);
    if (n == null) return 'Must be a valid number';
    if (n < 50 || n > 100) return 'Implausible SpO2 (50-100%)';
    return null;
  }

  static String? validateBloodSugar(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value);
    if (n == null) return 'Must be a valid number';
    if (n < 30 || n > 700) return 'Implausible RBS (30-700 mg/dL)';
    return null;
  }
}
