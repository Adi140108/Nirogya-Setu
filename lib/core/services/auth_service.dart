import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
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

  Future<void> bypassLoginAsRole(UserRole role, {String? displayName, String? email}) async {
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

    final cleanEmail = email?.trim().isNotEmpty == true
        ? email!.trim()
        : '${role.name}.user@aarogyasetu.gov.in';

    final user = AppUser(
      uid: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      displayName: cleanName,
      role: role,
      phoneNumber: '+91 98765 00000',
      villageId: 'village-rampura-01',
      facilityId: 'phc-khed-01',
      createdAt: DateTime.now(),
    );

    _currentUser = user;
    await _storageService.saveUserSession(user.toMap());
    _isLoading = false;
    notifyListeners();
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
