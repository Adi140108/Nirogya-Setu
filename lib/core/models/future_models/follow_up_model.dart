/// Extension Point: Architecture Required Now for Follow-Up and Missed-Care Recovery
/// Prepares referral and care-record models to support future follow-up dates, reminders, and recovery workflows.
enum MissedCareSeverity {
  low,
  moderate,
  highEmergency,
}

class FollowUpModel {
  final String followUpId;
  final String referralId;
  final String patientId;
  final String assignedAshaId;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final bool isCompleted;
  final bool isMissedCare;
  final int daysOverdue;
  final MissedCareSeverity severity;
  final String? recoveryActionNotes;
  final List<DateTime> automatedReminderTimestamps;

  const FollowUpModel({
    required this.followUpId,
    required this.referralId,
    required this.patientId,
    required this.assignedAshaId,
    required this.scheduledDate,
    this.completedDate,
    this.isCompleted = false,
    this.isMissedCare = false,
    this.daysOverdue = 0,
    this.severity = MissedCareSeverity.moderate,
    this.recoveryActionNotes,
    this.automatedReminderTimestamps = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'followUpId': followUpId,
      'referralId': referralId,
      'patientId': patientId,
      'assignedAshaId': assignedAshaId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'isMissedCare': isMissedCare,
      'daysOverdue': daysOverdue,
      'severity': severity.name,
      'recoveryActionNotes': recoveryActionNotes,
      'automatedReminderTimestamps':
          automatedReminderTimestamps.map((e) => e.toIso8601String()).toList(),
    };
  }

  factory FollowUpModel.fromMap(Map<String, dynamic> map) {
    MissedCareSeverity parsedSeverity;
    try {
      parsedSeverity = MissedCareSeverity.values.byName(map['severity'] ?? 'moderate');
    } catch (_) {
      parsedSeverity = MissedCareSeverity.moderate;
    }

    final reminders = (map['automatedReminderTimestamps'] as List<dynamic>?)
            ?.map((e) => DateTime.tryParse(e.toString()) ?? DateTime.now())
            .toList() ??
        [];

    return FollowUpModel(
      followUpId: map['followUpId'] ?? '',
      referralId: map['referralId'] ?? '',
      patientId: map['patientId'] ?? '',
      assignedAshaId: map['assignedAshaId'] ?? '',
      scheduledDate: map['scheduledDate'] != null
          ? DateTime.tryParse(map['scheduledDate']) ?? DateTime.now()
          : DateTime.now(),
      completedDate: map['completedDate'] != null
          ? DateTime.tryParse(map['completedDate'])
          : null,
      isCompleted: map['isCompleted'] == true,
      isMissedCare: map['isMissedCare'] == true,
      daysOverdue: (map['daysOverdue'] as num?)?.toInt() ?? 0,
      severity: parsedSeverity,
      recoveryActionNotes: map['recoveryActionNotes'],
      automatedReminderTimestamps: reminders,
    );
  }
}
