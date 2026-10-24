import 'sync_status.dart';

/// Records managed from the Admin Portal: ASHA workers, doctors, hospitals and
/// Health Hub videos. Each record carries [updatedAt] and a soft-delete flag so
/// local and Firestore copies can be merged (newest wins) across devices.

DateTime _parseDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

class AshaWorkerModel {
  final String id;
  final String fullName;
  final int age;
  final String gender;
  final String mobileNumber;
  final String password;
  final String villageId;
  final String villageName;
  final String district;
  final String state;
  final String? hospitalId;
  final String ashaIdNumber;
  final String education;
  final DateTime? joiningDate;
  final String address;
  final bool isActive;
  final bool isDeleted;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AshaWorkerModel({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.mobileNumber,
    required this.password,
    required this.villageId,
    required this.villageName,
    this.district = '',
    this.state = '',
    this.hospitalId,
    required this.ashaIdNumber,
    this.education = '',
    this.joiningDate,
    this.address = '',
    this.isActive = true,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.locallySaved,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'mobileNumber': mobileNumber,
      'password': password,
      'villageId': villageId,
      'villageName': villageName,
      'district': district,
      'state': state,
      'hospitalId': hospitalId,
      'ashaIdNumber': ashaIdNumber,
      'education': education,
      'joiningDate': joiningDate?.toIso8601String(),
      'address': address,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'syncStatus': syncStatus.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AshaWorkerModel.fromMap(Map<String, dynamic> map) {
    return AshaWorkerModel(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      gender: map['gender'] ?? 'Female',
      mobileNumber: map['mobileNumber'] ?? '',
      password: map['password'] ?? '',
      villageId: map['villageId'] ?? '',
      villageName: map['villageName'] ?? '',
      district: map['district'] ?? '',
      state: map['state'] ?? '',
      hospitalId: map['hospitalId'],
      ashaIdNumber: map['ashaIdNumber'] ?? '',
      education: map['education'] ?? '',
      joiningDate: map['joiningDate'] != null ? DateTime.tryParse(map['joiningDate']) : null,
      address: map['address'] ?? '',
      isActive: map['isActive'] != false,
      isDeleted: map['isDeleted'] == true,
      syncStatus: SyncStatusExtension.fromString(map['syncStatus']),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  AshaWorkerModel copyWith({
    String? fullName,
    int? age,
    String? gender,
    String? mobileNumber,
    String? password,
    String? villageId,
    String? villageName,
    String? district,
    String? state,
    String? hospitalId,
    bool clearHospital = false,
    String? ashaIdNumber,
    String? education,
    DateTime? joiningDate,
    String? address,
    bool? isActive,
    bool? isDeleted,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return AshaWorkerModel(
      id: id,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      password: password ?? this.password,
      villageId: villageId ?? this.villageId,
      villageName: villageName ?? this.villageName,
      district: district ?? this.district,
      state: state ?? this.state,
      hospitalId: clearHospital ? null : (hospitalId ?? this.hospitalId),
      ashaIdNumber: ashaIdNumber ?? this.ashaIdNumber,
      education: education ?? this.education,
      joiningDate: joiningDate ?? this.joiningDate,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DoctorModel {
  final String id;
  final String fullName;
  final int age;
  final String gender;
  final String mobileNumber;
  final String email;
  final String password;
  final String specialization;
  final String qualification;
  final String registrationNumber;
  final int experienceYears;
  final String hospitalId;
  final bool isActive;
  final bool isDeleted;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorModel({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.mobileNumber,
    this.email = '',
    required this.password,
    required this.specialization,
    required this.qualification,
    required this.registrationNumber,
    this.experienceYears = 0,
    required this.hospitalId,
    this.isActive = true,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.locallySaved,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'mobileNumber': mobileNumber,
      'email': email,
      'password': password,
      'specialization': specialization,
      'qualification': qualification,
      'registrationNumber': registrationNumber,
      'experienceYears': experienceYears,
      'hospitalId': hospitalId,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'syncStatus': syncStatus.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      gender: map['gender'] ?? 'Male',
      mobileNumber: map['mobileNumber'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      specialization: map['specialization'] ?? 'General Physician',
      qualification: map['qualification'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      experienceYears: (map['experienceYears'] as num?)?.toInt() ?? 0,
      hospitalId: map['hospitalId'] ?? '',
      isActive: map['isActive'] != false,
      isDeleted: map['isDeleted'] == true,
      syncStatus: SyncStatusExtension.fromString(map['syncStatus']),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  DoctorModel copyWith({
    String? fullName,
    int? age,
    String? gender,
    String? mobileNumber,
    String? email,
    String? password,
    String? specialization,
    String? qualification,
    String? registrationNumber,
    int? experienceYears,
    String? hospitalId,
    bool? isActive,
    bool? isDeleted,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return DoctorModel(
      id: id,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      password: password ?? this.password,
      specialization: specialization ?? this.specialization,
      qualification: qualification ?? this.qualification,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      experienceYears: experienceYears ?? this.experienceYears,
      hospitalId: hospitalId ?? this.hospitalId,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class HospitalModel {
  final String id;
  final String name;
  final String type;
  final String address;
  final String villageTown;
  final String district;
  final String state;
  final String pincode;
  final String contactNumber;
  final int totalBeds;
  final int availableBeds;
  final int icuBeds;
  final bool hasEmergency;
  final bool hasMaternityWard;
  final bool isDeleted;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.villageTown,
    required this.district,
    required this.state,
    this.pincode = '',
    required this.contactNumber,
    this.totalBeds = 0,
    this.availableBeds = 0,
    this.icuBeds = 0,
    this.hasEmergency = false,
    this.hasMaternityWard = false,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.locallySaved,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'villageTown': villageTown,
      'district': district,
      'state': state,
      'pincode': pincode,
      'contactNumber': contactNumber,
      'totalBeds': totalBeds,
      'availableBeds': availableBeds,
      'icuBeds': icuBeds,
      'hasEmergency': hasEmergency,
      'hasMaternityWard': hasMaternityWard,
      'isDeleted': isDeleted,
      'syncStatus': syncStatus.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HospitalModel.fromMap(Map<String, dynamic> map) {
    return HospitalModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'Primary Health Centre (PHC)',
      address: map['address'] ?? '',
      villageTown: map['villageTown'] ?? '',
      district: map['district'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      totalBeds: (map['totalBeds'] as num?)?.toInt() ?? 0,
      availableBeds: (map['availableBeds'] as num?)?.toInt() ?? 0,
      icuBeds: (map['icuBeds'] as num?)?.toInt() ?? 0,
      hasEmergency: map['hasEmergency'] == true,
      hasMaternityWard: map['hasMaternityWard'] == true,
      isDeleted: map['isDeleted'] == true,
      syncStatus: SyncStatusExtension.fromString(map['syncStatus']),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  HospitalModel copyWith({
    String? name,
    String? type,
    String? address,
    String? villageTown,
    String? district,
    String? state,
    String? pincode,
    String? contactNumber,
    int? totalBeds,
    int? availableBeds,
    int? icuBeds,
    bool? hasEmergency,
    bool? hasMaternityWard,
    bool? isDeleted,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return HospitalModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      villageTown: villageTown ?? this.villageTown,
      district: district ?? this.district,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      contactNumber: contactNumber ?? this.contactNumber,
      totalBeds: totalBeds ?? this.totalBeds,
      availableBeds: availableBeds ?? this.availableBeds,
      icuBeds: icuBeds ?? this.icuBeds,
      hasEmergency: hasEmergency ?? this.hasEmergency,
      hasMaternityWard: hasMaternityWard ?? this.hasMaternityWard,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// One language version of a Health Hub video: its own YouTube link, title and description.
class VideoLanguageVariant {
  final String language;
  final String title;
  final String description;
  final String youtubeUrl;
  final String youtubeId;

  const VideoLanguageVariant({
    required this.language,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.youtubeId,
  });

  String get thumbnailUrl => 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'title': title,
      'description': description,
      'youtubeUrl': youtubeUrl,
      'youtubeId': youtubeId,
    };
  }

  factory VideoLanguageVariant.fromMap(Map<String, dynamic> map) {
    return VideoLanguageVariant(
      language: map['language'] ?? 'English',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      youtubeUrl: map['youtubeUrl'] ?? '',
      youtubeId: map['youtubeId'] ?? '',
    );
  }
}

class HealthVideoModel {
  final String id;
  final String topic;
  final List<VideoLanguageVariant> variants;
  final bool isDeleted;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HealthVideoModel({
    required this.id,
    required this.topic,
    required this.variants,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.locallySaved,
    required this.createdAt,
    required this.updatedAt,
  });

  List<String> get languages => variants.map((v) => v.language).toList();

  /// Returns the variant for [language], falling back to the first one added.
  VideoLanguageVariant variantFor(String? language) {
    for (final v in variants) {
      if (v.language == language) return v;
    }
    return variants.first;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'variants': variants.map((v) => v.toMap()).toList(),
      'isDeleted': isDeleted,
      'syncStatus': syncStatus.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HealthVideoModel.fromMap(Map<String, dynamic> map) {
    final rawVariants = map['variants'] as List<dynamic>? ?? [];
    return HealthVideoModel(
      id: map['id'] ?? '',
      topic: map['topic'] ?? 'General Health',
      variants: rawVariants
          .map((e) => VideoLanguageVariant.fromMap(Map<String, dynamic>.from(e as Map)))
          .where((v) => v.youtubeId.isNotEmpty)
          .toList(),
      isDeleted: map['isDeleted'] == true,
      syncStatus: SyncStatusExtension.fromString(map['syncStatus']),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  HealthVideoModel copyWith({
    String? topic,
    List<VideoLanguageVariant>? variants,
    bool? isDeleted,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return HealthVideoModel(
      id: id,
      topic: topic ?? this.topic,
      variants: variants ?? this.variants,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
