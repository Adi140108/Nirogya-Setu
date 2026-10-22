import '../constants/screening_rules.dart';
import 'sync_status.dart';

class ScreeningModel {
  final String id;
  final String patientId;
  final String patientName;
  final String ashaId;
  final String ashaName;
  final String villageId;

  // Vital Signs
  final double? systolicBP;
  final double? diastolicBP;
  final double? pulseRate;
  final double? temperatureF;
  final double? bloodSugarMgDl;
  final double? spo2Percent;

  // Symptoms & Observations
  final List<String> symptoms;
  final bool isPregnant;
  final String lifestyleObservations;
  final String generalNotes;

  // Triaged Decision Support Outcome
  final HealthPriority priority;
  final String categoryTitle;
  final String reason;
  final String recommendedNextStep;
  final List<String> flaggedConcerns;

  // Sync & Timestamps
  final SyncStatus syncStatus;
  final DateTime createdAt;

  const ScreeningModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.ashaId,
    required this.ashaName,
    required this.villageId,
    this.systolicBP,
    this.diastolicBP,
    this.pulseRate,
    this.temperatureF,
    this.bloodSugarMgDl,
    this.spo2Percent,
    required this.symptoms,
    this.isPregnant = false,
    this.lifestyleObservations = '',
    this.generalNotes = '',
    required this.priority,
    required this.categoryTitle,
    required this.reason,
    required this.recommendedNextStep,
    this.flaggedConcerns = const [],
    this.syncStatus = SyncStatus.locallySaved,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'ashaId': ashaId,
      'ashaName': ashaName,
      'villageId': villageId,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'pulseRate': pulseRate,
      'temperatureF': temperatureF,
      'bloodSugarMgDl': bloodSugarMgDl,
      'spo2Percent': spo2Percent,
      'symptoms': symptoms,
      'isPregnant': isPregnant,
      'lifestyleObservations': lifestyleObservations,
      'generalNotes': generalNotes,
      'priority': priority.name,
      'categoryTitle': categoryTitle,
      'reason': reason,
      'recommendedNextStep': recommendedNextStep,
      'flaggedConcerns': flaggedConcerns,
      'syncStatus': syncStatus.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScreeningModel.fromMap(Map<String, dynamic> map, {String? id}) {
    HealthPriority parsedPriority;
    switch (map['priority']) {
      case 'red':
        parsedPriority = HealthPriority.red;
        break;
      case 'yellow':
        parsedPriority = HealthPriority.yellow;
        break;
      case 'green':
      default:
        parsedPriority = HealthPriority.green;
        break;
    }

    return ScreeningModel(
      id: id ?? map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      ashaId: map['ashaId'] ?? '',
      ashaName: map['ashaName'] ?? '',
      villageId: map['villageId'] ?? '',
      systolicBP: (map['systolicBP'] as num?)?.toDouble(),
      diastolicBP: (map['diastolicBP'] as num?)?.toDouble(),
      pulseRate: (map['pulseRate'] as num?)?.toDouble(),
      temperatureF: (map['temperatureF'] as num?)?.toDouble(),
      bloodSugarMgDl: (map['bloodSugarMgDl'] as num?)?.toDouble(),
      spo2Percent: (map['spo2Percent'] as num?)?.toDouble(),
      symptoms: List<String>.from(map['symptoms'] ?? []),
      isPregnant: map['isPregnant'] == true,
      lifestyleObservations: map['lifestyleObservations'] ?? '',
      generalNotes: map['generalNotes'] ?? '',
      priority: parsedPriority,
      categoryTitle: map['categoryTitle'] ?? '',
      reason: map['reason'] ?? '',
      recommendedNextStep: map['recommendedNextStep'] ?? '',
      flaggedConcerns: List<String>.from(map['flaggedConcerns'] ?? []),
      syncStatus: SyncStatusExtension.fromString(map['syncStatus']),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ScreeningModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? ashaId,
    String? ashaName,
    String? villageId,
    double? systolicBP,
    double? diastolicBP,
    double? pulseRate,
    double? temperatureF,
    double? bloodSugarMgDl,
    double? spo2Percent,
    List<String>? symptoms,
    bool? isPregnant,
    String? lifestyleObservations,
    String? generalNotes,
    HealthPriority? priority,
    String? categoryTitle,
    String? reason,
    String? recommendedNextStep,
    List<String>? flaggedConcerns,
    SyncStatus? syncStatus,
    DateTime? createdAt,
  }) {
    return ScreeningModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      ashaId: ashaId ?? this.ashaId,
      ashaName: ashaName ?? this.ashaName,
      villageId: villageId ?? this.villageId,
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      pulseRate: pulseRate ?? this.pulseRate,
      temperatureF: temperatureF ?? this.temperatureF,
      bloodSugarMgDl: bloodSugarMgDl ?? this.bloodSugarMgDl,
      spo2Percent: spo2Percent ?? this.spo2Percent,
      symptoms: symptoms ?? this.symptoms,
      isPregnant: isPregnant ?? this.isPregnant,
      lifestyleObservations: lifestyleObservations ?? this.lifestyleObservations,
      generalNotes: generalNotes ?? this.generalNotes,
      priority: priority ?? this.priority,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      reason: reason ?? this.reason,
      recommendedNextStep: recommendedNextStep ?? this.recommendedNextStep,
      flaggedConcerns: flaggedConcerns ?? this.flaggedConcerns,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
