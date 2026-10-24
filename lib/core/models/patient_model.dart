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
  final String? abhaNumber;
  final String? abhaAddress;
  final String? district;
  final String? state;
  final String? relationship;
  final String? hindiName;
  final String? wardNumber;
  final String? districtState;
  final String? password;
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
    this.abhaNumber,
    this.abhaAddress,
    this.district,
    this.state,
    this.relationship,
    this.hindiName,
    this.wardNumber,
    this.districtState,
    this.password,
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
      'abhaNumber': abhaNumber,
      'abhaAddress': abhaAddress,
      'district': district ?? computedDistrict,
      'state': state ?? computedState,
      'relationship': relationship,
      'hindiName': hindiName,
      'wardNumber': wardNumber,
      'districtState': districtState,
      'password': password,
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
      abhaNumber: map['abhaNumber'],
      abhaAddress: map['abhaAddress'],
      district: map['district'],
      state: map['state'],
      relationship: map['relationship'],
      hindiName: map['hindiName'],
      wardNumber: map['wardNumber'],
      districtState: map['districtState'],
      password: map['password'] as String?,
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
    String? abhaNumber,
    String? abhaAddress,
    String? district,
    String? state,
    String? relationship,
    String? hindiName,
    String? wardNumber,
    String? districtState,
    String? password,
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
      abhaNumber: abhaNumber ?? this.abhaNumber,
      abhaAddress: abhaAddress ?? this.abhaAddress,
      district: district ?? this.district,
      state: state ?? this.state,
      relationship: relationship ?? this.relationship,
      hindiName: hindiName ?? this.hindiName,
      wardNumber: wardNumber ?? this.wardNumber,
      districtState: districtState ?? this.districtState,
      password: password ?? this.password,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 14-digit standardized ABHA number formatted like 91-XXXX-XXXX-XXXX
  String get computedAbhaNumber {
    if (abhaNumber != null && abhaNumber!.trim().isNotEmpty) {
      final clean = abhaNumber!.trim();
      final digitsOnly = clean.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length == 14 && !clean.contains('-')) {
        return '${digitsOnly.substring(0, 2)}-${digitsOnly.substring(2, 6)}-${digitsOnly.substring(6, 10)}-${digitsOnly.substring(10, 14)}';
      }
      return clean;
    }
    final digits = id.hashCode.abs().toString().padRight(12, '7').substring(0, 12);
    return '91-${digits.substring(0, 4)}-${digits.substring(4, 8)}-${digits.substring(8, 12)}';
  }

  /// ABHA address e.g. name.surname@abdm
  String get computedAbhaAddress {
    if (abhaAddress != null && abhaAddress!.trim().isNotEmpty) return abhaAddress!;
    if (abhaNumber != null && abhaNumber!.contains('@')) return abhaNumber!;
    final sanitized = fullName.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]'), '.');
    return '$sanitized@abdm';
  }

  /// Localized Hindi name for government health cards
  String get computedHindiName {
    if (hindiName != null && hindiName!.trim().isNotEmpty) return hindiName!;
    if (fullName.toLowerCase().contains('ramesh')) return 'रमेश कुमार';
    if (fullName.toLowerCase().contains('sunita')) return 'सुनीता देवी';
    if (fullName.toLowerCase().contains('aarav')) return 'आरव कुमार';
    if (fullName.toLowerCase().contains('ananya')) return 'अनन्या कुमार';
    if (fullName.toLowerCase().contains('meena')) return 'मीना बाई';
    if (fullName.toLowerCase().contains('mohan')) return 'मोहन लाल';
    if (fullName.toLowerCase().contains('priya')) return 'प्रिया शर्मा';
    return fullName;
  }

  /// Family relationship description
  String get displayRelationship {
    if (relationship != null && relationship!.trim().isNotEmpty) return relationship!;
    if (isPregnant) return 'Wife (ANC)';
    if (age > 60) return 'Elder';
    if (age < 18) return 'Child';
    return 'Self';
  }

  String get computedWardNumber => wardNumber ?? '4';
  String get computedDistrict => district ?? 'Varanasi';
  String get computedState => state ?? 'Uttar Pradesh';
  String get computedDistrictState => districtState ?? 'District: $computedDistrict, $computedState';

  /// Generates the official QR code OPD token payload
  String get opdQrData {
    return '{"abha":"$computedAbhaNumber","name":"$fullName","gender":"$gender","age":$age,"phr":"$computedAbhaAddress","village":"$villageName","token":"OPD-${id.hashCode.abs() % 10000}"}';
  }
}
