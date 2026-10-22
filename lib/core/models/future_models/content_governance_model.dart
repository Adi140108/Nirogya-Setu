/// Extension Point: Architecture Required Now for Content Management
/// Supports future administrative publishing, review and approval states, content versioning, and updated offline downloads.
enum ContentApprovalStatus {
  draft,
  underMedicalReview,
  approved,
  published,
  archived,
}

class ContentGovernanceModel {
  final String contentId;
  final ContentApprovalStatus approvalStatus;
  final String reviewerMedicalOfficerId;
  final String reviewerMedicalOfficerName;
  final DateTime? reviewedTimestamp;
  final String? clinicalReviewNotes;
  final int schemaVersion;
  final List<String> targetVillageIds; // Geo-targeting e.g. for regional outbreaks

  const ContentGovernanceModel({
    required this.contentId,
    required this.approvalStatus,
    required this.reviewerMedicalOfficerId,
    required this.reviewerMedicalOfficerName,
    this.reviewedTimestamp,
    this.clinicalReviewNotes,
    this.schemaVersion = 1,
    this.targetVillageIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'approvalStatus': approvalStatus.name,
      'reviewerMedicalOfficerId': reviewerMedicalOfficerId,
      'reviewerMedicalOfficerName': reviewerMedicalOfficerName,
      'reviewedTimestamp': reviewedTimestamp?.toIso8601String(),
      'clinicalReviewNotes': clinicalReviewNotes,
      'schemaVersion': schemaVersion,
      'targetVillageIds': targetVillageIds,
    };
  }

  factory ContentGovernanceModel.fromMap(Map<String, dynamic> map) {
    ContentApprovalStatus status;
    try {
      status = ContentApprovalStatus.values.byName(map['approvalStatus'] ?? 'approved');
    } catch (_) {
      status = ContentApprovalStatus.approved;
    }

    return ContentGovernanceModel(
      contentId: map['contentId'] ?? '',
      approvalStatus: status,
      reviewerMedicalOfficerId: map['reviewerMedicalOfficerId'] ?? '',
      reviewerMedicalOfficerName: map['reviewerMedicalOfficerName'] ?? 'Public Health Board',
      reviewedTimestamp: map['reviewedTimestamp'] != null
          ? DateTime.tryParse(map['reviewedTimestamp'])
          : null,
      clinicalReviewNotes: map['clinicalReviewNotes'],
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      targetVillageIds: List<String>.from(map['targetVillageIds'] ?? []),
    );
  }
}
