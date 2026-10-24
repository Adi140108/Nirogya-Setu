import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/admin_models.dart';
import '../models/patient_model.dart';
import '../models/sync_status.dart';
import 'storage_service.dart';

/// Single source of truth for everything the Admin Portal manages.
///
/// Records are saved locally first (works fully offline) and then mirrored to
/// Cloud Firestore. On refresh, cloud copies are pulled and merged by
/// [updatedAt] so changes made on another device appear here too. Deletes are
/// soft (tombstones) so they propagate across devices as well.
class AdminRepository extends ChangeNotifier {
  static const String defaultAdminPassword = 'admin123';

  static const String _colAsha = 'admin_asha_workers';
  static const String _colDoctors = 'admin_doctors';
  static const String _colHospitals = 'admin_hospitals';
  static const String _colVideos = 'health_videos';
  static const String _colConfig = 'admin_config';
  static const String _docCredentials = 'credentials';

  static const Duration _cloudTimeout = Duration(seconds: 10);

  final StorageService _storage;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  List<AshaWorkerModel> _asha = [];
  List<DoctorModel> _doctors = [];
  List<HospitalModel> _hospitals = [];
  List<HealthVideoModel> _videos = [];

  bool _isLoaded = false;
  bool _isAdminLoggedIn = false;
  bool _isSyncing = false;
  String? _lastSyncError;
  DateTime? _lastSyncTimestamp;

  AdminRepository(this._storage) {
    _init();
  }

  // --- Public read API (tombstones hidden) ---
  bool get isLoaded => _isLoaded;
  bool get isAdminLoggedIn => _isAdminLoggedIn;
  bool get isSyncing => _isSyncing;
  String? get lastSyncError => _lastSyncError;
  DateTime? get lastSyncTimestamp => _lastSyncTimestamp;

  List<AshaWorkerModel> get ashaWorkers =>
      _asha.where((e) => !e.isDeleted).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  List<DoctorModel> get doctors =>
      _doctors.where((e) => !e.isDeleted).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  List<HospitalModel> get hospitals =>
      _hospitals.where((e) => !e.isDeleted).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  List<HealthVideoModel> get videos =>
      _videos.where((e) => !e.isDeleted && e.variants.isNotEmpty).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get pendingSyncCount =>
      _asha.where((e) => e.syncStatus != SyncStatus.synced).length +
      _doctors.where((e) => e.syncStatus != SyncStatus.synced).length +
      _hospitals.where((e) => e.syncStatus != SyncStatus.synced).length +
      _videos.where((e) => e.syncStatus != SyncStatus.synced).length;

  /// All languages that have at least one video, in a stable display order.
  List<String> get availableVideoLanguages {
    final found = <String>{};
    for (final v in videos) {
      found.addAll(v.languages);
    }
    final ordered = supportedVideoLanguages.where(found.contains).toList();
    ordered.addAll(found.where((l) => !supportedVideoLanguages.contains(l)));
    return ordered;
  }

  static const List<String> supportedVideoLanguages = [
    'Hindi',
    'English',
    'Marathi',
    'Bengali',
    'Gujarati',
    'Punjabi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Odia',
    'Assamese',
    'Urdu',
    'Bhojpuri',
  ];

  // --- Initialisation ---
  Future<void> _init() async {
    final storedAsha = await _storage.loadJsonList(StorageService.keyAdminAshaWorkers);
    final storedDoctors = await _storage.loadJsonList(StorageService.keyAdminDoctors);
    final storedHospitals = await _storage.loadJsonList(StorageService.keyAdminHospitals);
    final storedVideos = await _storage.loadJsonList(StorageService.keyHealthVideos);

    _asha = storedAsha.map(AshaWorkerModel.fromMap).toList();
    _doctors = storedDoctors.map(DoctorModel.fromMap).toList();
    _hospitals = storedHospitals.map(HospitalModel.fromMap).toList();
    _videos = storedVideos.map(HealthVideoModel.fromMap).toList();

    if (_asha.isEmpty && _doctors.isEmpty && _hospitals.isEmpty) {
      _seedLinkedDemoData();
      await _persistStaff();
    }

    _isLoaded = true;
    notifyListeners();

    unawaited(syncWithCloud());
    _listenForCloudChanges();
  }

  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _cloudSubs = [];

  /// Live updates: anything added or edited on another device (for example a
  /// video published by the admin) appears here without a manual refresh.
  void _listenForCloudChanges() {
    if (!_cloudAvailable) return;
    final firestore = FirebaseFirestore.instance;
    void onError(Object e) => debugPrint('Admin live sync paused: $e');

    _cloudSubs.add(firestore.collection(_colVideos).snapshots().listen((snap) async {
      _videos = _merge(_videos, snap.docs, HealthVideoModel.fromMap, (e) => e.id, (e) => e.updatedAt,
          (e) => e.copyWith(syncStatus: SyncStatus.synced));
      await _persistVideos();
      notifyListeners();
    }, onError: onError));
    _cloudSubs.add(firestore.collection(_colAsha).snapshots().listen((snap) async {
      _asha = _merge(_asha, snap.docs, AshaWorkerModel.fromMap, (e) => e.id, (e) => e.updatedAt,
          (e) => e.copyWith(syncStatus: SyncStatus.synced));
      await _persistStaff();
      notifyListeners();
    }, onError: onError));
    _cloudSubs.add(firestore.collection(_colDoctors).snapshots().listen((snap) async {
      _doctors = _merge(_doctors, snap.docs, DoctorModel.fromMap, (e) => e.id, (e) => e.updatedAt,
          (e) => e.copyWith(syncStatus: SyncStatus.synced));
      await _persistStaff();
      notifyListeners();
    }, onError: onError));
    _cloudSubs.add(firestore.collection(_colHospitals).snapshots().listen((snap) async {
      _hospitals = _merge(_hospitals, snap.docs, HospitalModel.fromMap, (e) => e.id, (e) => e.updatedAt,
          (e) => e.copyWith(syncStatus: SyncStatus.synced));
      await _persistStaff();
      notifyListeners();
    }, onError: onError));
  }

  @override
  void dispose() {
    for (final sub in _cloudSubs) {
      sub.cancel();
    }
    super.dispose();
  }

  /// Seeds records that match the existing demo identities used elsewhere in
  /// the app (Shanti Devi, Dr. Rajesh Sharma, PHC Khed) so the admin views show
  /// real linked villagers, screenings and referrals from day one.
  void _seedLinkedDemoData() {
    final now = DateTime.now();
    _hospitals = [
      HospitalModel(
        id: 'phc-khed-01',
        name: 'Primary Health Centre, Khed',
        type: hospitalTypes.first,
        address: 'Near Gram Panchayat Bhavan, Main Road',
        villageTown: 'Khed Buzurg',
        district: 'Varanasi',
        state: 'Uttar Pradesh',
        pincode: '221001',
        contactNumber: '9876500010',
        totalBeds: 30,
        availableBeds: 12,
        icuBeds: 2,
        hasEmergency: true,
        hasMaternityWard: true,
        createdAt: now.subtract(const Duration(days: 400)),
        updatedAt: now.subtract(const Duration(days: 400)),
      ),
    ];
    _asha = [
      AshaWorkerModel(
        id: 'asha-shanti-01',
        fullName: 'Shanti Devi',
        age: 38,
        gender: 'Female',
        mobileNumber: '9876500001',
        password: generatePassword('Shanti Devi', '9876500001'),
        villageId: 'village-rampura-01',
        villageName: 'Rampura',
        district: 'Varanasi',
        state: 'Uttar Pradesh',
        hospitalId: 'phc-khed-01',
        ashaIdNumber: 'ASHA-MP-2024-88',
        education: '10th Pass',
        joiningDate: DateTime(2024, 4, 1),
        address: 'Ward 4, Rampura',
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 180)),
      ),
    ];
    _doctors = [
      DoctorModel(
        id: 'doc-rajesh-01',
        fullName: 'Dr. Rajesh Sharma',
        age: 45,
        gender: 'Male',
        mobileNumber: '9876500002',
        email: 'dr.rajesh@aarogyasetu.gov.in',
        password: generatePassword('Dr. Rajesh Sharma', '9876500002'),
        specialization: 'General Physician',
        qualification: 'MBBS, MD (Medicine)',
        registrationNumber: 'MCI-REG-44819',
        experienceYears: 18,
        hospitalId: 'phc-khed-01',
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now.subtract(const Duration(days: 365)),
      ),
    ];
  }

  // --- Form option lists ---
  static const List<String> hospitalTypes = [
    'Primary Health Centre (PHC)',
    'Community Health Centre (CHC)',
    'Sub-Centre / Health & Wellness Centre',
    'District Hospital',
    'Sub-District Hospital',
    'Private Hospital',
    'Medical College Hospital',
  ];

  static const List<String> doctorSpecializations = [
    'General Physician',
    'Gynecologist & Obstetrician',
    'Pediatrician',
    'General Surgeon',
    'Cardiologist',
    'Orthopedic',
    'Dermatologist',
    'ENT Specialist',
    'Ophthalmologist',
    'Psychiatrist',
    'Pulmonologist',
    'Community Medicine',
    'AYUSH Practitioner',
  ];

  static const List<String> ashaEducationLevels = [
    '8th Pass',
    '10th Pass',
    '12th Pass',
    'Graduate',
    'Post Graduate',
  ];

  static String villageIdFor(String villageName, {String district = ''}) {
    final slug = '$villageName $district'.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return 'village-$slug';
  }

  // --- Validation & credential helpers ---

  /// Last 10 digits of a phone number, ignoring +91, spaces and dashes.
  static String normalizeMobile(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  /// Returns an error message, or null when [input] is a valid Indian mobile number.
  static String? validateMobile(String? input) {
    final value = (input ?? '').trim();
    if (value.isEmpty) return 'Mobile number is required';
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final local = digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : (digits.length == 11 && digits.startsWith('0') ? digits.substring(1) : digits);
    if (local.length != 10) return 'Enter a 10-digit mobile number';
    if (!RegExp(r'^[6-9]').hasMatch(local)) return 'Mobile number must start with 6, 7, 8 or 9';
    return null;
  }

  static String formatMobile(String mobile) {
    final m = normalizeMobile(mobile);
    if (m.length != 10) return mobile;
    return '+91 ${m.substring(0, 5)} ${m.substring(5)}';
  }

  /// Simple, easy-to-share password: first 4 letters of the name + @ + last 4 mobile digits.
  /// Example: Shanti Devi / 98765 00001 -> Shan@0001
  static String generatePassword(String fullName, String mobile, {String? suffix}) {
    final withoutTitle = fullName.trim().replaceFirst(RegExp(r'^dr\.?\s+', caseSensitive: false), '');
    var letters = withoutTitle.replaceAll(RegExp(r'[^A-Za-z]'), '').toLowerCase();
    if (letters.isEmpty) letters = 'user';
    final prefix = (letters.length >= 4 ? letters.substring(0, 4) : letters.padRight(4, 'x'));
    final digits = normalizeMobile(mobile);
    final tail = suffix ?? (digits.length >= 4 ? digits.substring(digits.length - 4) : digits.padLeft(4, '0'));
    return '${prefix[0].toUpperCase()}${prefix.substring(1)}@$tail';
  }

  String _randomFourDigits() => (1000 + _random.nextInt(9000)).toString();

  /// Extracts the 11-character video ID from any common YouTube link
  /// (watch, youtu.be, shorts, embed, live, mobile) or a bare ID. Returns null if invalid.
  static String? parseYoutubeId(String input) {
    final value = input.trim();
    if (value.isEmpty) return null;
    final idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');
    if (idPattern.hasMatch(value)) return value;

    final uri = Uri.tryParse(value.startsWith('http') ? value : 'https://$value');
    if (uri == null) return null;
    final host = uri.host.toLowerCase().replaceFirst('www.', '').replaceFirst('m.', '');

    String? candidate;
    if (host == 'youtu.be') {
      candidate = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (host == 'youtube.com' || host == 'music.youtube.com' || host == 'youtube-nocookie.com') {
      candidate = uri.queryParameters['v'];
      if (candidate == null && uri.pathSegments.length >= 2) {
        const prefixes = {'shorts', 'embed', 'live', 'v', 'e'};
        if (prefixes.contains(uri.pathSegments.first)) candidate = uri.pathSegments[1];
      }
    }
    if (candidate != null && idPattern.hasMatch(candidate)) return candidate;
    return null;
  }

  /// Returns who already uses [mobile] (as "ASHA worker X" / "Doctor Y"), or null if free.
  String? mobileInUseBy(String mobile, {String? excludeId}) {
    final target = normalizeMobile(mobile);
    for (final a in ashaWorkers) {
      if (a.id != excludeId && normalizeMobile(a.mobileNumber) == target) return 'ASHA worker ${a.fullName}';
    }
    for (final d in doctors) {
      if (d.id != excludeId && normalizeMobile(d.mobileNumber) == target) return 'Doctor ${d.fullName}';
    }
    return null;
  }

  // --- Admin authentication ---
  static String _hashPassword(String password) =>
      sha256.convert(utf8.encode('aarogya-setu-admin::$password')).toString();

  Future<String> _currentPasswordHash() async {
    final stored = await _storage.loadValue(StorageService.keyAdminPasswordHash);
    return stored ?? _hashPassword(defaultAdminPassword);
  }

  /// Picks up a password changed on another device, if the cloud is reachable.
  Future<void> _pullAdminPasswordFromCloud() async {
    if (!_cloudAvailable) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_colConfig)
          .doc(_docCredentials)
          .get()
          .timeout(const Duration(seconds: 4));
      final remoteHash = snap.data()?['passwordHash'];
      if (remoteHash is String && remoteHash.isNotEmpty) {
        await _storage.saveValue(StorageService.keyAdminPasswordHash, remoteHash);
      }
    } catch (e) {
      debugPrint('Admin credential cloud check skipped: $e');
    }
  }

  Future<bool> adminLogin(String password) async {
    await _pullAdminPasswordFromCloud();
    final ok = _hashPassword(password.trim()) == await _currentPasswordHash();
    if (ok) {
      _isAdminLoggedIn = true;
      notifyListeners();
      unawaited(syncWithCloud());
    }
    return ok;
  }

  /// Quick access for demos and testing: signs in without the password.
  void adminBypassLogin() {
    _isAdminLoggedIn = true;
    notifyListeners();
    unawaited(syncWithCloud());
  }

  void adminLogout() {
    _isAdminLoggedIn = false;
    notifyListeners();
  }

  /// Returns an error message, or null on success.
  Future<String?> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final current = currentPassword.trim();
    final next = newPassword.trim();
    if (current.isEmpty || next.isEmpty || confirmPassword.trim().isEmpty) {
      return 'Please fill in all three fields.';
    }
    if (_hashPassword(current) != await _currentPasswordHash()) {
      return 'Current password is incorrect.';
    }
    if (next.length < 6) return 'New password must be at least 6 characters.';
    if (!RegExp(r'[A-Za-z]').hasMatch(next) || !RegExp(r'[0-9]').hasMatch(next)) {
      return 'New password must contain both letters and numbers.';
    }
    if (next == current) return 'New password must be different from the current password.';
    if (next != confirmPassword.trim()) return 'New password and confirmation do not match.';

    final hash = _hashPassword(next);
    await _storage.saveValue(StorageService.keyAdminPasswordHash, hash);

    if (_cloudAvailable) {
      try {
        await FirebaseFirestore.instance.collection(_colConfig).doc(_docCredentials).set({
          'passwordHash': hash,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true)).timeout(_cloudTimeout);
      } catch (e) {
        debugPrint('Admin password saved locally; cloud update pending: $e');
      }
    }
    return null;
  }

  // --- ASHA workers ---
  Future<AshaWorkerModel> addAshaWorker({
    required String fullName,
    required int age,
    required String gender,
    required String mobileNumber,
    required String villageName,
    required String district,
    required String state,
    String? hospitalId,
    required String ashaIdNumber,
    String education = '',
    DateTime? joiningDate,
    String address = '',
  }) async {
    final conflict = mobileInUseBy(mobileNumber);
    if (conflict != null) throw Exception('This mobile number is already registered to $conflict.');

    final now = DateTime.now();
    final mobile = normalizeMobile(mobileNumber);
    final worker = AshaWorkerModel(
      id: 'asha-${_uuid.v4().substring(0, 8)}',
      fullName: fullName.trim(),
      age: age,
      gender: gender,
      mobileNumber: mobile,
      password: generatePassword(fullName, mobile),
      villageId: villageIdFor(villageName, district: district),
      villageName: villageName.trim(),
      district: district,
      state: state,
      hospitalId: hospitalId,
      ashaIdNumber: ashaIdNumber.trim(),
      education: education,
      joiningDate: joiningDate,
      address: address.trim(),
      createdAt: now,
      updatedAt: now,
    );
    _asha.add(worker);
    await _afterStaffWrite();
    return worker;
  }

  Future<void> updateAshaWorker(AshaWorkerModel updated) async {
    final conflict = mobileInUseBy(updated.mobileNumber, excludeId: updated.id);
    if (conflict != null) throw Exception('This mobile number is already registered to $conflict.');
    final index = _asha.indexWhere((e) => e.id == updated.id);
    if (index == -1) return;
    _asha[index] = updated.copyWith(
      mobileNumber: normalizeMobile(updated.mobileNumber),
      syncStatus: SyncStatus.pendingSync,
      updatedAt: DateTime.now(),
    );
    await _afterStaffWrite();
  }

  /// Assigns a village to an ASHA worker and commits directly to local database and Firestore
  Future<void> assignVillageToAsha({
    required String ashaId,
    required String villageName,
    required String district,
    required String state,
  }) async {
    final index = _asha.indexWhere((e) => e.id == ashaId);
    if (index == -1) return;

    final updated = _asha[index].copyWith(
      villageName: villageName.trim(),
      villageId: villageIdFor(villageName, district: district),
      district: district.trim(),
      state: state.trim(),
      syncStatus: SyncStatus.pendingSync,
      updatedAt: DateTime.now(),
    );
    _asha[index] = updated;
    await _afterStaffWrite();

    // Mirror to Firestore user document for immediate cross-portal recognition
    if (_cloudAvailable) {
      try {
        final payload = {
          'assignedVillage': villageName.trim(),
          'villageName': villageName.trim(),
          'villageId': updated.villageId,
          'district': district.trim(),
          'state': state.trim(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        await FirebaseFirestore.instance.collection('users').doc(updated.id).set(payload, SetOptions(merge: true));
        final mobile = normalizeMobile(updated.mobileNumber);
        if (mobile.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(mobile).set(payload, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Direct user doc village sync notice: $e');
      }
    }
  }

  /// Returns all villages matching the given State and District
  List<String> getVillagesForDistrict({
    required String state,
    required String district,
    List<PatientModel>? patients,
  }) {
    final cleanState = state.trim().toLowerCase();
    final cleanDistrict = district.trim().toLowerCase();
    final villages = <String>{};

    // 1. From patients/households
    if (patients != null) {
      for (final p in patients) {
        final pState = p.computedState.trim().toLowerCase();
        final pDistrict = p.computedDistrict.trim().toLowerCase();
        if ((cleanState.isEmpty || pState.isEmpty || pState == cleanState) &&
            (cleanDistrict.isEmpty || pDistrict.isEmpty || pDistrict == cleanDistrict)) {
          if (p.villageName.trim().isNotEmpty) {
            villages.add(p.villageName.trim());
          }
        }
      }
    }

    // 2. From assigned ASHA workers
    for (final a in ashaWorkers) {
      final aState = a.state.trim().toLowerCase();
      final aDistrict = a.district.trim().toLowerCase();
      if ((cleanState.isEmpty || aState.isEmpty || aState == cleanState) &&
          (cleanDistrict.isEmpty || aDistrict.isEmpty || aDistrict == cleanDistrict)) {
        if (a.villageName.trim().isNotEmpty) {
          villages.add(a.villageName.trim());
        }
      }
    }

    // 3. From hospitals
    for (final h in hospitals) {
      final hState = h.state.trim().toLowerCase();
      final hDistrict = h.district.trim().toLowerCase();
      if ((cleanState.isEmpty || hState.isEmpty || hState == cleanState) &&
          (cleanDistrict.isEmpty || hDistrict.isEmpty || hDistrict == cleanDistrict)) {
        if (h.villageTown.trim().isNotEmpty) {
          villages.add(h.villageTown.trim());
        }
      }
    }

    // 4. Default fallbacks if Varanasi / Uttar Pradesh
    if (cleanDistrict.isEmpty || cleanDistrict == 'varanasi' || cleanState == 'uttar pradesh') {
      villages.addAll(['Rampura', 'Khed Buzurg', 'Sundarpur', 'Shivpur', 'Cholapur', 'Sarnath']);
    }

    final list = villages.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  Future<void> setAshaActive(String id, bool active) async {
    final index = _asha.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _asha[index] = _asha[index].copyWith(isActive: active, syncStatus: SyncStatus.pendingSync, updatedAt: DateTime.now());
    await _afterStaffWrite();
  }

  Future<String> resetAshaPassword(String id) async {
    final index = _asha.indexWhere((e) => e.id == id);
    if (index == -1) return '';
    final current = _asha[index];
    final password = generatePassword(current.fullName, current.mobileNumber, suffix: _randomFourDigits());
    _asha[index] = current.copyWith(password: password, syncStatus: SyncStatus.pendingSync, updatedAt: DateTime.now());
    await _afterStaffWrite();
    return password;
  }

  Future<void> deleteAshaWorker(String id) async {
    final index = _asha.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _asha[index] = _asha[index].copyWith(isDeleted: true, syncStatus: SyncStatus.pendingSync, updatedAt: DateTime.now());
    await _afterStaffWrite();
  }

  AshaWorkerModel? ashaById(String? id) {
    for (final a in ashaWorkers) {
      if (a.id == id) return a;
    }
    return null;
  }

  // --- Doctors ---
  Future<DoctorModel> addDoctor({
    required String fullName,
    required int age,
    required String gender,
    required String mobileNumber,
    String email = '',
    required String specialization,
    required String qualification,
    required String registrationNumber,
    int experienceYears = 0,
    required String hospitalId,
  }) async {
    final conflict = mobileInUseBy(mobileNumber);
    if (conflict != null) throw Exception('This mobile number is already registered to $conflict.');
    if (hospitalById(hospitalId) == null) throw Exception('Please select a hospital from the hospital list.');

    final now = DateTime.now();
    final mobile = normalizeMobile(mobileNumber);
    final doctor = DoctorModel(
      id: 'doc-${_uuid.v4().substring(0, 8)}',
      fullName: fullName.trim(),
      age: age,
      gender: gender,
      mobileNumber: mobile,
      email: email.trim(),
      password: generatePassword(fullName, mobile),
      specialization: specialization,
      qualification: qualification.trim(),
      registrationNumber: registrationNumber.trim(),
      experienceYears: experienceYears,
      hospitalId: hospitalId,
      createdAt: now,
      updatedAt: now,
    );
    _doctors.add(doctor);
    await _afterStaffWrite();
    return doctor;
  }

  Future<void> updateDoctor(DoctorModel updated) async {
    final conflict = mobileInUseBy(updated.mobileNumber, excludeId: updated.id);
    if (conflict != null) throw Exception('This mobile number is already registered to $conflict.');
    if (hospitalById(updated.hospitalId) == null) throw Exception('Please select a hospital from the hospital list.');
    final index = _doctors.indexWhere((e) => e.id == updated.id);
    if (index == -1) return;
    _doctors[index] = updated.copyWith(
      mobileNumber: normalizeMobile(updated.mobileNumber),
      syncStatus: SyncStatus.pendingSync,
      updatedAt: DateTime.now(),
    );
    await _afterStaffWrite();
  }

  Future<void> setDoctorActive(String id, bool active) async {
    final index = _doctors.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _doctors[index] =
        _doctors[index].copyWith(isActive: active, syncStatus: SyncStatus.pendingSync, updatedAt: DateTime.now());
    await _afterStaffWrite();
  }

  Future<String> resetDoctorPassword(String id) async {
    final index = _doctors.indexWhere((e) => e.id == id);
    if (index == -1) return '';
    final current = _doctors[index];
    final password = generatePassword(current.fullName, current.mobileNumber, suffix: _randomFourDigits());
    _doctors[index] = current.copyWith(password: password, syncStatus: SyncStatus.pendingSync, updatedAt: DateTime.now());
    await _afterStaffWrite();
    return password;
  }

  Future<void> deleteDoctor(String id) async {
    final index = _doctors.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _doctors[index] =
        _doctors[index].copyWith(isDeleted: true, syncStatus: SyncStatus.pendingSync, updatedAt: DateTime.now());
    await _afterStaffWrite();
  }

  // --- Hospitals ---
  Future<HospitalModel> addHospital({
    required String name,
    required String type,
    required String address,
    required String villageTown,
    required String district,
    required String state,
    String pincode = '',
    required String contactNumber,
    int totalBeds = 0,
    int availableBeds = 0,
    int icuBeds = 0,
    bool hasEmergency = false,
    bool hasMaternityWard = false,
  }) async {
    final duplicate = hospitals.any((h) =>
        h.name.trim().toLowerCase() == name.trim().toLowerCase() &&
        h.villageTown.trim().toLowerCase() == villageTown.trim().toLowerCase());
    if (duplicate) throw Exception('A hospital with this name already exists in $villageTown.');

    final now = DateTime.now();
    final hospital = HospitalModel(
      id: 'hosp-${_uuid.v4().substring(0, 8)}',
      name: name.trim(),
      type: type,
      address: address.trim(),
      villageTown: villageTown.trim(),
      district: district.trim(),
      state: state.trim(),
      pincode: pincode.trim(),
      contactNumber: contactNumber.trim(),
      totalBeds: totalBeds,
      availableBeds: availableBeds,
      icuBeds: icuBeds,
      hasEmergency: hasEmergency,
      hasMaternityWard: hasMaternityWard,
      createdAt: now,
      updatedAt: now,
    );
    _hospitals.add(hospital);
    await _afterStaffWrite();
    return hospital;
  }

  Future<void> updateHospital(HospitalModel updated) async {
    final index = _hospitals.indexWhere((e) => e.id == updated.id);
    if (index == -1) return;
    _hospitals[index] = updated.copyWith(syncStatus: SyncStatus.pendingSync, updatedAt: DateTime.now());
    await _afterStaffWrite();
  }

  /// Returns an error message when the hospital still has linked staff, otherwise deletes it.
  Future<String?> deleteHospital(String id) async {
    final linkedDoctors = doctorsForHospital(id).length;
    final linkedAsha = ashaForHospital(id).length;
    if (linkedDoctors > 0 || linkedAsha > 0) {
      return 'This hospital still has $linkedDoctors doctor(s) and $linkedAsha ASHA worker(s) linked. '
          'Move them to another hospital before deleting it.';
    }
    final index = _hospitals.indexWhere((e) => e.id == id);
    if (index == -1) return null;
    _hospitals[index] =
        _hospitals[index].copyWith(isDeleted: true, syncStatus: SyncStatus.pendingSync, updatedAt: DateTime.now());
    await _afterStaffWrite();
    return null;
  }

  HospitalModel? hospitalById(String? id) {
    for (final h in hospitals) {
      if (h.id == id) return h;
    }
    return null;
  }

  List<DoctorModel> doctorsForHospital(String hospitalId) =>
      doctors.where((d) => d.hospitalId == hospitalId).toList();

  List<AshaWorkerModel> ashaForHospital(String hospitalId) =>
      ashaWorkers.where((a) => a.hospitalId == hospitalId).toList();

  /// Villagers registered by (linked to) a given ASHA worker.
  static List<PatientModel> villagersForAsha(String ashaId, List<PatientModel> patients) =>
      patients.where((p) => p.ashaId == ashaId).toList();

  /// Villagers covered by all ASHA workers linked to a hospital.
  List<PatientModel> villagersForHospital(String hospitalId, List<PatientModel> patients) {
    final ashaIds = ashaForHospital(hospitalId).map((a) => a.id).toSet();
    return patients.where((p) => ashaIds.contains(p.ashaId)).toList();
  }

  // --- Health Hub videos ---
  Future<HealthVideoModel> addVideo({
    required String topic,
    required List<VideoLanguageVariant> variants,
  }) async {
    if (variants.isEmpty) throw Exception('Add at least one language with a YouTube link.');
    final now = DateTime.now();
    final video = HealthVideoModel(
      id: 'vid-${_uuid.v4().substring(0, 8)}',
      topic: topic.trim(),
      variants: variants,
      createdAt: now,
      updatedAt: now,
    );
    _videos.add(video);
    await _afterVideoWrite();
    return video;
  }

  Future<void> updateVideo(HealthVideoModel updated) async {
    final index = _videos.indexWhere((e) => e.id == updated.id);
    if (index == -1) return;
    _videos[index] = updated.copyWith(syncStatus: SyncStatus.pendingSync, updatedAt: DateTime.now());
    await _afterVideoWrite();
  }

  Future<void> deleteVideo(String id) async {
    final index = _videos.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _videos[index] =
        _videos[index].copyWith(isDeleted: true, syncStatus: SyncStatus.pendingSync, updatedAt: DateTime.now());
    await _afterVideoWrite();
  }

  // --- Persistence ---
  Future<void> _persistStaff() async {
    await _storage.saveJsonList(StorageService.keyAdminAshaWorkers, _asha.map((e) => e.toMap()).toList());
    await _storage.saveJsonList(StorageService.keyAdminDoctors, _doctors.map((e) => e.toMap()).toList());
    await _storage.saveJsonList(StorageService.keyAdminHospitals, _hospitals.map((e) => e.toMap()).toList());
  }

  Future<void> _persistVideos() async {
    await _storage.saveJsonList(StorageService.keyHealthVideos, _videos.map((e) => e.toMap()).toList());
  }

  Future<void> _afterStaffWrite() async {
    await _persistStaff();
    notifyListeners();
    unawaited(_pushPending());
  }

  Future<void> _afterVideoWrite() async {
    await _persistVideos();
    notifyListeners();
    unawaited(_pushPending());
  }

  // --- Cloud Firestore sync ---
  bool get _cloudAvailable => Firebase.apps.isNotEmpty;

  /// Pulls cloud changes, merges them, then pushes local pending changes.
  Future<void> syncWithCloud() async {
    if (_isSyncing) return;
    if (!_cloudAvailable) {
      _lastSyncError = 'Cloud database not configured on this device. Data is saved locally.';
      notifyListeners();
      return;
    }
    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      final firestore = FirebaseFirestore.instance;
      final results = await Future.wait([
        firestore.collection(_colAsha).get(),
        firestore.collection(_colDoctors).get(),
        firestore.collection(_colHospitals).get(),
        firestore.collection(_colVideos).get(),
      ]).timeout(_cloudTimeout);

      _asha = _merge(_asha, results[0].docs, AshaWorkerModel.fromMap, (e) => e.id, (e) => e.updatedAt,
          (e) => e.copyWith(syncStatus: SyncStatus.synced));
      _doctors = _merge(_doctors, results[1].docs, DoctorModel.fromMap, (e) => e.id, (e) => e.updatedAt,
          (e) => e.copyWith(syncStatus: SyncStatus.synced));
      _hospitals = _merge(_hospitals, results[2].docs, HospitalModel.fromMap, (e) => e.id, (e) => e.updatedAt,
          (e) => e.copyWith(syncStatus: SyncStatus.synced));
      _videos = _merge(_videos, results[3].docs, HealthVideoModel.fromMap, (e) => e.id, (e) => e.updatedAt,
          (e) => e.copyWith(syncStatus: SyncStatus.synced));

      await _persistStaff();
      await _persistVideos();
      notifyListeners();

      await _pushPending(force: true);
      _lastSyncTimestamp = DateTime.now();
    } catch (e) {
      debugPrint('Admin cloud sync notice: $e');
      _lastSyncError = 'Could not reach the cloud database. Changes are saved on this device and will sync later.';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  List<T> _merge<T>(
    List<T> local,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> remoteDocs,
    T Function(Map<String, dynamic>) fromMap,
    String Function(T) idOf,
    DateTime Function(T) updatedAtOf,
    T Function(T) markSynced,
  ) {
    final byId = <String, T>{for (final item in local) idOf(item): item};
    for (final doc in remoteDocs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] ??= doc.id;
      final remote = markSynced(fromMap(data));
      final existing = byId[idOf(remote)];
      if (existing == null || updatedAtOf(remote).isAfter(updatedAtOf(existing))) {
        byId[idOf(remote)] = remote;
      }
    }
    return byId.values.toList();
  }

  bool _isPushing = false;

  /// Pushes records that are not yet confirmed by the cloud.
  Future<void> _pushPending({bool force = false}) async {
    if (!_cloudAvailable || (_isPushing && !force)) return;
    _isPushing = true;
    var changed = false;
    try {
      final firestore = FirebaseFirestore.instance;

      Future<void> push(String collection, String id, Map<String, dynamic> map) async {
        map['syncStatus'] = SyncStatus.synced.value;
        await firestore.collection(collection).doc(id).set(map, SetOptions(merge: true)).timeout(_cloudTimeout);
      }

      for (var i = 0; i < _asha.length; i++) {
        if (_asha[i].syncStatus == SyncStatus.synced) continue;
        await push(_colAsha, _asha[i].id, _asha[i].toMap());
        _asha[i] = _asha[i].copyWith(syncStatus: SyncStatus.synced);
        changed = true;
      }
      for (var i = 0; i < _doctors.length; i++) {
        if (_doctors[i].syncStatus == SyncStatus.synced) continue;
        await push(_colDoctors, _doctors[i].id, _doctors[i].toMap());
        _doctors[i] = _doctors[i].copyWith(syncStatus: SyncStatus.synced);
        changed = true;
      }
      for (var i = 0; i < _hospitals.length; i++) {
        if (_hospitals[i].syncStatus == SyncStatus.synced) continue;
        await push(_colHospitals, _hospitals[i].id, _hospitals[i].toMap());
        _hospitals[i] = _hospitals[i].copyWith(syncStatus: SyncStatus.synced);
        changed = true;
      }
      for (var i = 0; i < _videos.length; i++) {
        if (_videos[i].syncStatus == SyncStatus.synced) continue;
        await push(_colVideos, _videos[i].id, _videos[i].toMap());
        _videos[i] = _videos[i].copyWith(syncStatus: SyncStatus.synced);
        changed = true;
      }
    } catch (e) {
      debugPrint('Admin cloud push pending (offline or permission): $e');
    } finally {
      _isPushing = false;
      if (changed) {
        await _persistStaff();
        await _persistVideos();
        notifyListeners();
      }
    }
  }
}
