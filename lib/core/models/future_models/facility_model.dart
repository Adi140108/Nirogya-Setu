/// Extension Point: Architecture Required Now for Hospital Registration and Administration
/// Supports healthcare facilities, verified doctors, facility membership, and ASHA service-area assignments.
enum FacilityType {
  subCentre,
  healthAndWellnessCentre,
  primaryHealthCentre,
  communityHealthCentre,
  districtHospital,
  tertiaryHospital,
}

class FacilityModel {
  final String facilityId;
  final String name;
  final FacilityType type;
  final String district;
  final String state;
  final String contactPhone;
  final List<String> verifiedDoctorIds;
  final List<String> assignedAshaWorkerIds;
  final int totalBedCapacity;
  final bool hasEmergencyICU;
  final bool hasMaternalCareUnit;
  final bool isActive;

  const FacilityModel({
    required this.facilityId,
    required this.name,
    required this.type,
    required this.district,
    required this.state,
    required this.contactPhone,
    this.verifiedDoctorIds = const [],
    this.assignedAshaWorkerIds = const [],
    this.totalBedCapacity = 0,
    this.hasEmergencyICU = false,
    this.hasMaternalCareUnit = false,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'facilityId': facilityId,
      'name': name,
      'type': type.name,
      'district': district,
      'state': state,
      'contactPhone': contactPhone,
      'verifiedDoctorIds': verifiedDoctorIds,
      'assignedAshaWorkerIds': assignedAshaWorkerIds,
      'totalBedCapacity': totalBedCapacity,
      'hasEmergencyICU': hasEmergencyICU,
      'hasMaternalCareUnit': hasMaternalCareUnit,
      'isActive': isActive,
    };
  }

  factory FacilityModel.fromMap(Map<String, dynamic> map) {
    FacilityType parsedType;
    try {
      parsedType = FacilityType.values.byName(map['type'] ?? 'primaryHealthCentre');
    } catch (_) {
      parsedType = FacilityType.primaryHealthCentre;
    }

    return FacilityModel(
      facilityId: map['facilityId'] ?? '',
      name: map['name'] ?? '',
      type: parsedType,
      district: map['district'] ?? '',
      state: map['state'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      verifiedDoctorIds: List<String>.from(map['verifiedDoctorIds'] ?? []),
      assignedAshaWorkerIds: List<String>.from(map['assignedAshaWorkerIds'] ?? []),
      totalBedCapacity: (map['totalBedCapacity'] as num?)?.toInt() ?? 0,
      hasEmergencyICU: map['hasEmergencyICU'] == true,
      hasMaternalCareUnit: map['hasMaternalCareUnit'] == true,
      isActive: map['isActive'] != false,
    );
  }
}
