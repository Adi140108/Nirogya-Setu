enum UserRole {
  asha,
  doctor,
  patient,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.asha:
        return 'asha';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.patient:
        return 'patient';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.asha:
        return 'ASHA Worker';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.patient:
        return 'Citizen';
    }
  }

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'asha':
        return UserRole.asha;
      case 'doctor':
        return UserRole.doctor;
      case 'patient':
      default:
        return UserRole.patient;
    }
  }
}

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? phoneNumber;
  final String? villageId;
  final String? facilityId;
  final String? badgeNumber;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber,
    this.villageId,
    this.facilityId,
    this.badgeNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.value,
      'phoneNumber': phoneNumber,
      'villageId': villageId,
      'facilityId': facilityId,
      'badgeNumber': badgeNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, {String? id}) {
    return AppUser(
      uid: id ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'User',
      role: UserRoleExtension.fromString(map['role']),
      phoneNumber: map['phoneNumber'],
      villageId: map['villageId'],
      facilityId: map['facilityId'],
      badgeNumber: map['badgeNumber'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? phoneNumber,
    String? villageId,
    String? facilityId,
    String? badgeNumber,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      villageId: villageId ?? this.villageId,
      facilityId: facilityId ?? this.facilityId,
      badgeNumber: badgeNumber ?? this.badgeNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
