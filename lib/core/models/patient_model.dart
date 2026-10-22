import 'sync_status.dart';

class PatientModel {
  final String id;
  final String ashaId;
  final String fullName;
  final int age;
  final String gender;
  final String villageId;
  final String villageName;
  final String? householdId;
  final String contactNumber;
  final String? guardianName;
  final bool isPregnant;
  final List<String> knownAllergies;
  final List<String> chronicConditions;
  final String? notes;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientModel({
    required this.id,
    required this.ashaId,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.villageId,
    required this.villageName,
    this.householdId,
    required this.contactNumber,
    this.guardianName,
    this.isPregnant = false,
    this.knownAllergies = const [],
    this.chronicConditions = const [],
    this.notes,
    this.syncStatus = SyncStatus.locallySaved,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ashaId': ashaId,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'villageId': villageId,
      'villageName': villageName,
      'householdId': householdId,
      'contactNumber': contactNumber,
      'guardianName': guardianName,
      'isPregnant': isPregnant,
      'knownAllergies': knownAllergies,
      'chronicConditions': chronicConditions,
      'notes': notes,
      'syncStatus': syncStatus.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PatientModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return PatientModel(
      id: id ?? map['id'] ?? '',
      ashaId: map['ashaId'] ?? '',
      fullName: map['fullName'] ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      gender: map['gender'] ?? 'Other',
      villageId: map['villageId'] ?? 'unassigned',
      villageName: map['villageName'] ?? 'General Village',
      householdId: map['householdId'],
      contactNumber: map['contactNumber'] ?? '',
      guardianName: map['guardianName'],
      isPregnant: map['isPregnant'] == true,
      knownAllergies: List<String>.from(map['knownAllergies'] ?? []),
      chronicConditions: List<String>.from(map['chronicConditions'] ?? []),
      notes: map['notes'],
      syncStatus: SyncStatusExtension.fromString(map['syncStatus']),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  PatientModel copyWith({
    String? id,
    String? ashaId,
    String? fullName,
    int? age,
    String? gender,
    String? villageId,
    String? villageName,
    String? householdId,
    String? contactNumber,
    String? guardianName,
    bool? isPregnant,
    List<String>? knownAllergies,
    List<String>? chronicConditions,
    String? notes,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      ashaId: ashaId ?? this.ashaId,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      villageId: villageId ?? this.villageId,
      villageName: villageName ?? this.villageName,
      householdId: householdId ?? this.householdId,
      contactNumber: contactNumber ?? this.contactNumber,
      guardianName: guardianName ?? this.guardianName,
      isPregnant: isPregnant ?? this.isPregnant,
      knownAllergies: knownAllergies ?? this.knownAllergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
