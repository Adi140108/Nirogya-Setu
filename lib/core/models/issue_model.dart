import 'sync_status.dart';

class IssueModel {
  final String id;
  final String citizenId;
  final String citizenName;
  final String contactNumber;
  final String villageId;
  final String villageName;
  final String householdId;
  final String category;
  final String description;
  final String urgency; // 'Normal' or 'Urgent'
  final bool hasVoiceNote;
  final int voiceDurationSeconds;
  final String? voiceTranscription;
  final bool isResolved;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final SyncStatus syncStatus;

  /// ASHA worker responsible for this citizen (used to route notifications and map pins).
  final String? ashaId;

  /// Where the citizen was when the issue was raised (null if location was unavailable).
  final double? latitude;
  final double? longitude;

  /// Last change time; used to merge copies of the issue across devices.
  final DateTime? updatedAt;

  bool get hasLocation => latitude != null && longitude != null;
  DateTime get lastChangedAt => updatedAt ?? resolvedAt ?? createdAt;

  const IssueModel({
    required this.id,
    required this.citizenId,
    required this.citizenName,
    required this.contactNumber,
    required this.villageId,
    required this.villageName,
    required this.householdId,
    required this.category,
    required this.description,
    this.urgency = 'Normal',
    this.hasVoiceNote = false,
    this.voiceDurationSeconds = 0,
    this.voiceTranscription,
    this.isResolved = false,
    this.resolvedAt,
    required this.createdAt,
    this.syncStatus = SyncStatus.locallySaved,
    this.ashaId,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'citizenId': citizenId,
      'citizenName': citizenName,
      'contactNumber': contactNumber,
      'villageId': villageId,
      'villageName': villageName,
      'householdId': householdId,
      'category': category,
      'description': description,
      'urgency': urgency,
      'hasVoiceNote': hasVoiceNote,
      'voiceDurationSeconds': voiceDurationSeconds,
      'voiceTranscription': voiceTranscription,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus.value,
      'ashaId': ashaId,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory IssueModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return IssueModel(
      id: id ?? map['id'] ?? '',
      citizenId: map['citizenId'] ?? '',
      citizenName: map['citizenName'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      villageId: map['villageId'] ?? '',
      villageName: map['villageName'] ?? 'Rampura',
      householdId: map['householdId'] ?? 'HH-042',
      category: map['category'] ?? 'General Health',
      description: map['description'] ?? '',
      urgency: map['urgency'] ?? 'Normal',
      hasVoiceNote: map['hasVoiceNote'] == true,
      voiceDurationSeconds: (map['voiceDurationSeconds'] as num?)?.toInt() ?? 0,
      voiceTranscription: map['voiceTranscription'] as String?,
      isResolved: map['isResolved'] == true,
      resolvedAt: map['resolvedAt'] != null ? DateTime.tryParse(map['resolvedAt']) : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      syncStatus: SyncStatusExtension.fromString(map['syncStatus']),
      ashaId: map['ashaId'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      updatedAt: map['updatedAt'] is String ? DateTime.tryParse(map['updatedAt']) : null,
    );
  }

  IssueModel copyWith({
    String? id,
    String? citizenId,
    String? citizenName,
    String? contactNumber,
    String? villageId,
    String? villageName,
    String? householdId,
    String? category,
    String? description,
    String? urgency,
    bool? hasVoiceNote,
    int? voiceDurationSeconds,
    String? voiceTranscription,
    bool? isResolved,
    DateTime? resolvedAt,
    DateTime? createdAt,
    SyncStatus? syncStatus,
    String? ashaId,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
    bool clearResolvedAt = false,
  }) {
    return IssueModel(
      id: id ?? this.id,
      citizenId: citizenId ?? this.citizenId,
      citizenName: citizenName ?? this.citizenName,
      contactNumber: contactNumber ?? this.contactNumber,
      villageId: villageId ?? this.villageId,
      villageName: villageName ?? this.villageName,
      householdId: householdId ?? this.householdId,
      category: category ?? this.category,
      description: description ?? this.description,
      urgency: urgency ?? this.urgency,
      hasVoiceNote: hasVoiceNote ?? this.hasVoiceNote,
      voiceDurationSeconds: voiceDurationSeconds ?? this.voiceDurationSeconds,
      voiceTranscription: voiceTranscription ?? this.voiceTranscription,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: clearResolvedAt ? null : (resolvedAt ?? this.resolvedAt),
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      ashaId: ashaId ?? this.ashaId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
