/// Extension Point: Architecture Required Now for Future Care-Gap Radar and Village Map
/// Prepared data models for future map-based dashboard and cluster alerts without database redesign.
class VillageModel {
  final String villageId;
  final String name;
  final String subDistrict;
  final String district;
  final String state;
  final double latitude;
  final double longitude;
  final int estimatedPopulation;
  final String clusterZone; // e.g., 'Zone-North', 'Zone-RiverValley'

  // Future aggregate metric hooks (anonymized, non-patient identifying)
  final int totalScreenedCount;
  final int highRiskClusterCount;
  final double careGapIndex; // 0.0 to 1.0 (unaddressed referrals / total)

  const VillageModel({
    required this.villageId,
    required this.name,
    required this.subDistrict,
    required this.district,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.estimatedPopulation,
    required this.clusterZone,
    this.totalScreenedCount = 0,
    this.highRiskClusterCount = 0,
    this.careGapIndex = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'villageId': villageId,
      'name': name,
      'subDistrict': subDistrict,
      'district': district,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'estimatedPopulation': estimatedPopulation,
      'clusterZone': clusterZone,
      'totalScreenedCount': totalScreenedCount,
      'highRiskClusterCount': highRiskClusterCount,
      'careGapIndex': careGapIndex,
    };
  }

  factory VillageModel.fromMap(Map<String, dynamic> map) {
    return VillageModel(
      villageId: map['villageId'] ?? '',
      name: map['name'] ?? '',
      subDistrict: map['subDistrict'] ?? '',
      district: map['district'] ?? '',
      state: map['state'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      estimatedPopulation: (map['estimatedPopulation'] as num?)?.toInt() ?? 0,
      clusterZone: map['clusterZone'] ?? 'DefaultZone',
      totalScreenedCount: (map['totalScreenedCount'] as num?)?.toInt() ?? 0,
      highRiskClusterCount: (map['highRiskClusterCount'] as num?)?.toInt() ?? 0,
      careGapIndex: (map['careGapIndex'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
