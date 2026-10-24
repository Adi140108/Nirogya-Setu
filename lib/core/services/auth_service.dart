import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/patient_model.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  final StorageService _storageService;

  AppUser? _currentUser;
  bool _isLoading = true;
  String? _authError;

  AuthService(this._storageService) {
    _restoreSession();
  }

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get authError => _authError;

  Future<void> _restoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userMap = await _storageService.loadUserSession();
      if (userMap != null) {
        _currentUser = AppUser.fromMap(userMap);
      }
    } catch (_) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Fast 1-Click Demo Logins for Development and Field Demonstrations ---

  Future<void> loginAsDemoAsha() async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    final ashaUser = AppUser(
      uid: 'asha-shanti-01',
      email: 'asha.shanti@aarogyasetu.gov.in',
      displayName: 'Shanti Devi',
      role: UserRole.asha,
      phoneNumber: '+91 98765 00001',
      villageId: 'village-rampura-01',
      facilityId: 'phc-khed-01',
      badgeNumber: 'ASHA-MP-2024-88',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    );

    _currentUser = ashaUser;
    await _storageService.saveUserSession(ashaUser.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loginAsDemoDoctor() async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    final doctorUser = AppUser(
      uid: 'doc-rajesh-01',
      email: 'dr.rajesh@aarogyasetu.gov.in',
      displayName: 'Dr. Rajesh Sharma, MD',
      role: UserRole.doctor,
      phoneNumber: '+91 98765 00002',
      villageId: 'village-rampura-01',
      facilityId: 'phc-khed-01',
      badgeNumber: 'MCI-REG-44819',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    );

    _currentUser = doctorUser;
    await _storageService.saveUserSession(doctorUser.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loginAsDemoPatient() async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    final patientUser = AppUser(
      uid: 'patient-ramesh-01',
      email: 'ramesh.kumar@aarogyasetu.gov.in',
      displayName: 'Ramesh Kumar',
      role: UserRole.patient,
      phoneNumber: '+91 98765 43210',
      villageId: 'village-rampura-01',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    );

    _currentUser = patientUser;
    await _storageService.saveUserSession(patientUser.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> bypassLoginAsRole(
    UserRole role, {
    String? displayName,
    String? email,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    final cleanName = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : (role == UserRole.asha
            ? 'Shanti Devi'
            : role == UserRole.doctor
                ? 'Dr. Rajesh Sharma'
                : 'Ramesh Kumar');

    final cleanPhone = phoneNumber?.trim().isNotEmpty == true
        ? phoneNumber!.trim()
        : (role == UserRole.asha
            ? '+91 98765 00001'
            : role == UserRole.doctor
                ? '+91 98765 00002'
                : '+91 98765 43210');

    final cleanEmail = email?.trim().isNotEmpty == true
        ? email!.trim()
        : '${role.name}.user@aarogyasetu.gov.in';

    final user = AppUser(
      uid: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      displayName: cleanName,
      role: role,
      phoneNumber: cleanPhone,
      villageId: 'village-rampura-01',
      facilityId: 'phc-khed-01',
      createdAt: DateTime.now(),
    );

    _currentUser = user;
    await _storageService.saveUserSession(user.toMap());
    _isLoading = false;
    notifyListeners();
  }

  // --- Phone Number & Password Login ---

  Future<bool> signInWithPhonePassword({
    required String phoneNumber,
    required String password,
    required UserRole selectedRole,
    List<PatientModel>? registeredPatients,
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final cleanPhone = phoneNumber.trim();
      final cleanPass = password.trim();

      if (cleanPhone.isEmpty) {
        throw Exception('Please enter your phone number.');
      }
      if (cleanPass.isEmpty) {
        throw Exception('Please enter your password.');
      }

      String displayName = 'User';
      String? villageId = 'village-rampura-01';
      String? facilityId = 'phc-khed-01';
      String? uid;

      if (selectedRole == UserRole.patient) {
        final digits = cleanPhone.replaceAll(RegExp(r'[^0-9]'), '');
        PatientModel? matched;
        if (registeredPatients != null && registeredPatients.isNotEmpty) {
          for (final p in registeredPatients) {
            final pDigits = p.contactNumber.replaceAll(RegExp(r'[^0-9]'), '');
            if (pDigits == digits ||
                (pDigits.length >= 10 && digits.endsWith(pDigits.substring(pDigits.length - 10)))) {
              matched = p;
              break;
            }
          }
        }

        if (matched != null) {
          if (matched.password != null &&
              matched.password!.isNotEmpty &&
              matched.password != cleanPass) {
            throw Exception('Invalid password for this mobile number.');
          }
          displayName = matched.fullName;
          villageId = matched.villageId;
          uid = matched.id;
        } else {
          displayName = 'Citizen ($cleanPhone)';
        }
      } else if (selectedRole == UserRole.asha || selectedRole == UserRole.doctor) {
        // Accounts provisioned in the Admin Portal: mobile number + admin-generated password.
        final staff = await _findAdminProvisionedStaff(selectedRole, cleanPhone);
        if (staff != null) {
          if (staff['isActive'] == false) {
            throw Exception('This account has been deactivated by the administrator.');
          }
          if ((staff['password'] ?? '') != cleanPass) {
            throw Exception('Invalid password for this mobile number.');
          }
          uid = staff['id'];
          displayName = staff['fullName'] ?? displayName;
          if (selectedRole == UserRole.asha) {
            villageId = staff['villageId'] ?? villageId;
            facilityId = staff['hospitalId'];
          } else {
            facilityId = staff['hospitalId'] ?? facilityId;
          }
        } else if (selectedRole == UserRole.asha) {
          displayName = 'Shanti Devi';
          facilityId = 'phc-khed-01';
          uid = 'asha-shanti-01';
        } else {
          displayName = 'Dr. Rajesh Sharma, MD';
          facilityId = 'phc-khed-01';
          uid = 'doc-rajesh-01';
        }
      }

      final user = AppUser(
        uid: uid ?? 'user-${cleanPhone.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
        email: '$cleanPhone@aarogyasetu.gov.in',
        displayName: displayName,
        role: selectedRole,
        phoneNumber: cleanPhone,
        villageId: villageId,
        facilityId: facilityId,
        createdAt: DateTime.now(),
      );

      _currentUser = user;
      await _storageService.saveUserSession(user.toMap());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _authError = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Looks up an ASHA worker or doctor created in the Admin Portal by mobile number.
  Future<Map<String, dynamic>?> _findAdminProvisionedStaff(UserRole role, String phone) async {
    final key = role == UserRole.asha ? StorageService.keyAdminAshaWorkers : StorageService.keyAdminDoctors;
    final records = await _storageService.loadJsonList(key);
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return null;
    final last10 = digits.substring(digits.length - 10);
    for (final r in records) {
      if (r['isDeleted'] == true) continue;
      final rDigits = (r['mobileNumber'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (rDigits.length >= 10 && rDigits.substring(rDigits.length - 10) == last10) return r;
    }
    return null;
  }

  // --- Email & Password Sign In / Up ---

  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
    required UserRole selectedRole,
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      if (email.trim().isEmpty || password.trim().isEmpty) {
        throw Exception('Please provide both email and password.');
      }

      // Simulation/Local session or Firebase Auth mapping
      final user = AppUser(
        uid: 'user-${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
        email: email.trim(),
        displayName: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
        role: selectedRole,
        createdAt: DateTime.now(),
      );

      _currentUser = user;
      await _storageService.saveUserSession(user.toMap());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _authError = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = null;
    await _storageService.saveUserSession(null);
    _isLoading = false;
    notifyListeners();
  }
}
