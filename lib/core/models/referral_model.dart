import '../constants/screening_rules.dart';
import 'sync_status.dart';

enum ReferralStatus {
  pending('Pending Review', 'pending'),
  underReview('Under Clinical Review', 'under_review'),
  consulted('Consulted / Prescribed', 'consulted'),
  escalatedToFacility('Escalated to Hospital', 'escalated_to_facility'),
  closed('Closed / Resolved', 'closed');

  final String displayName;
  final String value;
  const ReferralStatus(this.displayName, this.value);
  static ReferralStatus fromString(String? val) {
    switch (val) {
      case 'under_review':
        return ReferralStatus.underReview;
      case 'consulted':
        return ReferralStatus.consulted;
      case 'escalated_to_facility':
        return ReferralStatus.escalatedToFacility;
      case 'closed':
        return ReferralStatus.closed;
      case 'pending':
      default:
        return ReferralStatus.pending;
    }
  }
}

class ReferralStatusLog {
  final String status;
  final String updatedByUserId;
  final String updatedByName;
  final String updatedByRole;
  final String? note;
  final DateTime timestamp;

  const ReferralStatusLog({
    required this.status,
    required this.updatedByUserId,
    required this.updatedByName,
    required this.updatedByRole,
    this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'updatedByUserId': updatedByUserId,
      'updatedByName': updatedByName,
      'updatedByRole': updatedByRole,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ReferralStatusLog.fromMap(Map<String, dynamic> map) {
    return ReferralStatusLog(
      status: map['status'] ?? 'pending',
      updatedByUserId: map['updatedByUserId'] ?? '',
      updatedByName: map['updatedByName'] ?? 'System',
      updatedByRole: map['updatedByRole'] ?? 'system',
      note: map['note'],
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ReferralModel {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String villageId;
  final String villageName;

  final String screeningId;
  final HealthPriority priority;
  final String triageReason;
  final List<String> primarySymptoms;

  final String originatingAshaId;
  final String originatingAshaName;
  final String ashaNotes;

  // Doctor Review fields
  final String? assignedDoctorId;
  final String? assignedDoctorName;
  final String? doctorClinicalNotes;
  final String? doctorRecommendations;
  final ReferralStatus status;

  // Future-ready extension hooks
  final String? facilityId;
  final DateTime? scheduledFollowUpDate;
  final bool isMissedCare;

  // Audit trail
  final List<ReferralStatusLog> statusHistory;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReferralModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.villageId,
    required this.villageName,
    required this.screeningId,
    required this.priority,
    required this.triageReason,
    this.primarySymptoms = const [],
    required this.originatingAshaId,
    required this.originatingAshaName,
    required this.ashaNotes,
    this.assignedDoctorId,
    this.assignedDoctorName,
    this.doctorClinicalNotes,
    this.doctorRecommendations,
    this.status = ReferralStatus.pending,
    this.facilityId,
    this.scheduledFollowUpDate,
    this.isMissedCare = false,
    this.statusHistory = const [],
    this.syncStatus = SyncStatus.locallySaved,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'villageId': villageId,
      'villageName': villageName,
      'screeningId': screeningId,
      'priority': priority.name,
      'triageReason': triageReason,
      'primarySymptoms': primarySymptoms,
      'originatingAshaId': originatingAshaId,
      'originatingAshaName': originatingAshaName,
      'ashaNotes': ashaNotes,
      'assignedDoctorId': assignedDoctorId,
      'assignedDoctorName': assignedDoctorName,
      'doctorClinicalNotes': doctorClinicalNotes,
      'doctorRecommendations': doctorRecommendations,
      'status': status.value,
      'facilityId': facilityId,
      'scheduledFollowUpDate': scheduledFollowUpDate?.toIso8601String(),
      'isMissedCare': isMissedCare,
      'statusHistory': statusHistory.map((x) => x.toMap()).toList(),
      'syncStatus': syncStatus.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ReferralModel.fromMap(Map<String, dynamic> map, {String? id}) {
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

    final historyList = (map['statusHistory'] as List<dynamic>?)
            ?.map((e) => ReferralStatusLog.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return ReferralModel(
      id: id ?? map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      patientAge: (map['patientAge'] as num?)?.toInt() ?? 0,
      patientGender: map['patientGender'] ?? 'Other',
      villageId: map['villageId'] ?? '',
      villageName: map['villageName'] ?? 'General Area',
      screeningId: map['screeningId'] ?? '',
      priority: parsedPriority,
      triageReason: map['triageReason'] ?? '',
      primarySymptoms: List<String>.from(map['primarySymptoms'] ?? []),
      originatingAshaId: map['originatingAshaId'] ?? '',
      originatingAshaName: map['originatingAshaName'] ?? '',
      ashaNotes: map['ashaNotes'] ?? '',
      assignedDoctorId: map['assignedDoctorId'],
      assignedDoctorName: map['assignedDoctorName'],
      doctorClinicalNotes: map['doctorClinicalNotes'],
      doctorRecommendations: map['doctorRecommendations'],
      status: ReferralStatus.fromString(map['status']),
      facilityId: map['facilityId'],
      scheduledFollowUpDate: map['scheduledFollowUpDate'] != null
          ? DateTime.tryParse(map['scheduledFollowUpDate'])
          : null,
      isMissedCare: map['isMissedCare'] == true,
      statusHistory: historyList,
      syncStatus: SyncStatusExtension.fromString(map['syncStatus']),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ReferralModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? villageId,
    String? villageName,
    String? screeningId,
    HealthPriority? priority,
    String? triageReason,
    List<String>? primarySymptoms,
    String? originatingAshaId,
    String? originatingAshaName,
    String? ashaNotes,
    String? assignedDoctorId,
    String? assignedDoctorName,
    String? doctorClinicalNotes,
    String? doctorRecommendations,
    ReferralStatus? status,
    String? facilityId,
    DateTime? scheduledFollowUpDate,
    bool? isMissedCare,
    List<ReferralStatusLog>? statusHistory,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReferralModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      villageId: villageId ?? this.villageId,
      villageName: villageName ?? this.villageName,
      screeningId: screeningId ?? this.screeningId,
      priority: priority ?? this.priority,
      triageReason: triageReason ?? this.triageReason,
      primarySymptoms: primarySymptoms ?? this.primarySymptoms,
      originatingAshaId: originatingAshaId ?? this.originatingAshaId,
      originatingAshaName: originatingAshaName ?? this.originatingAshaName,
      ashaNotes: ashaNotes ?? this.ashaNotes,
      assignedDoctorId: assignedDoctorId ?? this.assignedDoctorId,
      assignedDoctorName: assignedDoctorName ?? this.assignedDoctorName,
      doctorClinicalNotes: doctorClinicalNotes ?? this.doctorClinicalNotes,
      doctorRecommendations:
          doctorRecommendations ?? this.doctorRecommendations,
      status: status ?? this.status,
      facilityId: facilityId ?? this.facilityId,
      scheduledFollowUpDate:
          scheduledFollowUpDate ?? this.scheduledFollowUpDate,
      isMissedCare: isMissedCare ?? this.isMissedCare,
      statusHistory: statusHistory ?? this.statusHistory,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
