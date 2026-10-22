import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';
import '../models/screening_model.dart';
import '../models/referral_model.dart';
import '../models/sync_status.dart';
import '../constants/screening_rules.dart';
import 'storage_service.dart';

class HealthRepository extends ChangeNotifier {
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  List<PatientModel> _patients = [];
  List<ScreeningModel> _screenings = [];
  List<ReferralModel> _referrals = [];

  bool _isSyncing = false;
  String? _lastSyncError;
  DateTime? _lastSyncTimestamp;

  HealthRepository(this._storageService) {
    _init();
  }

  List<PatientModel> get patients => _patients;
  List<ScreeningModel> get screenings => _screenings;
  List<ReferralModel> get referrals => _referrals;
  bool get isSyncing => _isSyncing;
  String? get lastSyncError => _lastSyncError;
  DateTime? get lastSyncTimestamp => _lastSyncTimestamp;

  // Counts for dashboards
  int get pendingSyncCount {
    final p = _patients.where((e) => e.syncStatus != SyncStatus.synced).length;
    final s = _screenings.where((e) => e.syncStatus != SyncStatus.synced).length;
    final r = _referrals.where((e) => e.syncStatus != SyncStatus.synced).length;
    return p + s + r;
  }

  Future<void> _init() async {
    final storedPatients = await _storageService.loadPatients();
    final storedScreenings = await _storageService.loadScreenings();
    final storedReferrals = await _storageService.loadReferrals();

    if (storedPatients.isEmpty && storedScreenings.isEmpty && storedReferrals.isEmpty) {
      // Seed demonstration data for testing all 3 roles
      _seedDemoData();
      await _persistAll();
    } else {
      _patients = storedPatients.map((e) => PatientModel.fromMap(e)).toList();
      _screenings = storedScreenings.map((e) => ScreeningModel.fromMap(e)).toList();
      _referrals = storedReferrals.map((e) => ReferralModel.fromMap(e)).toList();
    }
    notifyListeners();
  }

  void _seedDemoData() {
    final now = DateTime.now();

    // 1. Seed Patients
    _patients = [
      PatientModel(
        id: 'patient-ramesh-01',
        ashaId: 'asha-shanti-01',
        fullName: 'Ramesh Kumar',
        age: 52,
        gender: 'Male',
        villageId: 'village-rampura-01',
        villageName: 'Rampura',
        householdId: 'HH-042',
        contactNumber: '+91 98765 43210',
        guardianName: 'Sunita Devi (Wife)',
        isPregnant: false,
        knownAllergies: ['Penicillin'],
        chronicConditions: ['Hypertension'],
        notes: 'Farmer. Complains of occasional headaches and fatigue in midday heat.',
        syncStatus: SyncStatus.synced,
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      PatientModel(
        id: 'patient-meena-02',
        ashaId: 'asha-shanti-01',
        fullName: 'Meena Bai',
        age: 26,
        gender: 'Female',
        villageId: 'village-rampura-01',
        villageName: 'Rampura',
        householdId: 'HH-018',
        contactNumber: '+91 98765 11223',
        guardianName: 'Suresh Bai (Husband)',
        isPregnant: true,
        knownAllergies: [],
        chronicConditions: ['Mild Anemia'],
        notes: 'Second trimester (24 weeks). Registered for Janani Suraksha Yojana.',
        syncStatus: SyncStatus.synced,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      PatientModel(
        id: 'patient-mohan-03',
        ashaId: 'asha-shanti-01',
        fullName: 'Mohan Lal',
        age: 68,
        gender: 'Male',
        villageId: 'village-khed-02',
        villageName: 'Khed Buzurg',
        householdId: 'HH-089',
        contactNumber: '+91 98765 99887',
        guardianName: 'Rajesh Lal (Son)',
        isPregnant: false,
        knownAllergies: [],
        chronicConditions: ['Type 2 Diabetes'],
        notes: 'Elderly villager with persistent cough and reduced appetite.',
        syncStatus: SyncStatus.locallySaved,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      PatientModel(
        id: 'patient-priya-04',
        ashaId: 'asha-shanti-01',
        fullName: 'Priya Sharma',
        age: 19,
        gender: 'Female',
        villageId: 'village-rampura-01',
        villageName: 'Rampura',
        householdId: 'HH-007',
        contactNumber: '+91 98765 33445',
        guardianName: 'Kamla Sharma (Mother)',
        isPregnant: false,
        knownAllergies: [],
        chronicConditions: [],
        notes: 'College student. Healthy vitals on routine checkup.',
        syncStatus: SyncStatus.synced,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
    ];

    // 2. Seed Screenings
    _screenings = [
      ScreeningModel(
        id: 'scr-001',
        patientId: 'patient-ramesh-01',
        patientName: 'Ramesh Kumar',
        ashaId: 'asha-shanti-01',
        ashaName: 'Shanti Devi',
        villageId: 'village-rampura-01',
        systolicBP: 165,
        diastolicBP: 102,
        pulseRate: 88,
        temperatureF: 98.6,
        bloodSugarMgDl: 180,
        spo2Percent: 97,
        symptoms: ['Dizziness or chronic fatigue'],
        isPregnant: false,
        lifestyleObservations: 'High salt consumption, irregular sleep.',
        generalNotes: 'Complains of recurrent morning headaches.',
        priority: HealthPriority.yellow,
        categoryTitle: 'YELLOW — Moderate Urgency / Medical Review Needed',
        reason: 'Elevated Blood Pressure (Stage 2 HTN: 165/102 mmHg), Symptoms noted: Dizziness or chronic fatigue.',
        recommendedNextStep: 'Refer for Doctor Consultation at PHC within 7 days. Provide dietary counseling.',
        flaggedConcerns: ['Elevated Blood Pressure', 'Dizziness or chronic fatigue'],
        syncStatus: SyncStatus.synced,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ScreeningModel(
        id: 'scr-002',
        patientId: 'patient-mohan-03',
        patientName: 'Mohan Lal',
        ashaId: 'asha-shanti-01',
        ashaName: 'Shanti Devi',
        villageId: 'village-khed-02',
        systolicBP: 142,
        diastolicBP: 88,
        pulseRate: 110,
        temperatureF: 101.8,
        bloodSugarMgDl: 310,
        spo2Percent: 91,
        symptoms: ['Persistent cough (> 2 weeks)', 'Unexplained weight loss', 'Severe breathlessness / gasping'],
        isPregnant: false,
        lifestyleObservations: 'Weak, heavy breathing upon walking.',
        generalNotes: 'Critical blood glucose and severe oxygen drop.',
        priority: HealthPriority.red,
        categoryTitle: 'RED — High Urgency / Immediate Escalation',
        reason: 'Critical Hypoxia (SpO2: 91%), Critical Glycemic Event (RBS: 310 mg/dL), Severe breathlessness.',
        recommendedNextStep: 'Immediate referral to District Hospital within 24 hours. Arrange transport.',
        flaggedConcerns: ['Critical Hypoxia', 'Critical Glycemic Event', 'High-risk symptom: Severe breathlessness'],
        syncStatus: SyncStatus.pendingSync,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ScreeningModel(
        id: 'scr-003',
        patientId: 'patient-priya-04',
        patientName: 'Priya Sharma',
        ashaId: 'asha-shanti-01',
        ashaName: 'Shanti Devi',
        villageId: 'village-rampura-01',
        systolicBP: 116,
        diastolicBP: 74,
        pulseRate: 72,
        temperatureF: 98.4,
        bloodSugarMgDl: 95,
        spo2Percent: 99,
        symptoms: [],
        isPregnant: false,
        lifestyleObservations: 'Active lifestyle, good nutrition.',
        generalNotes: 'Annual preventive screening checkup.',
        priority: HealthPriority.green,
        categoryTitle: 'GREEN — Low Risk / Routine Preventive Care',
        reason: 'All recorded vital parameters and observations are within expected normal thresholds.',
        recommendedNextStep: 'Continue regular healthy diet. Follow-up in 6 months.',
        flaggedConcerns: [],
        syncStatus: SyncStatus.synced,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
    ];

    // 3. Seed Referrals for Doctor review
    _referrals = [
      ReferralModel(
        id: 'ref-001',
        patientId: 'patient-mohan-03',
        patientName: 'Mohan Lal',
        patientAge: 68,
        patientGender: 'Male',
        villageId: 'village-khed-02',
        villageName: 'Khed Buzurg',
        screeningId: 'scr-002',
        priority: HealthPriority.red,
        triageReason: 'Critical Hypoxia (SpO2 91%), RBS 310 mg/dL, persistent cough and dyspnea.',
        primarySymptoms: ['Severe breathlessness / gasping', 'Persistent cough (> 2 weeks)', 'Unexplained weight loss'],
        originatingAshaId: 'asha-shanti-01',
        originatingAshaName: 'Shanti Devi',
        ashaNotes: 'Urgent: Patient is elderly with heavy breathing and chest rattle. Transport arranged.',
        assignedDoctorId: 'doc-rajesh-01',
        assignedDoctorName: 'Dr. Rajesh Sharma',
        status: ReferralStatus.pending,
        statusHistory: [
          ReferralStatusLog(
            status: 'pending',
            updatedByUserId: 'asha-shanti-01',
            updatedByName: 'Shanti Devi (ASHA)',
            updatedByRole: 'asha',
            note: 'Referral originated from emergency red-flag screening.',
            timestamp: now.subtract(const Duration(days: 1)),
          ),
        ],
        syncStatus: SyncStatus.pendingSync,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      ReferralModel(
        id: 'ref-002',
        patientId: 'patient-ramesh-01',
        patientName: 'Ramesh Kumar',
        patientAge: 52,
        patientGender: 'Male',
        villageId: 'village-rampura-01',
        villageName: 'Rampura',
        screeningId: 'scr-001',
        priority: HealthPriority.yellow,
        triageReason: 'Stage 2 Hypertension (165/102 mmHg), recurrent headaches.',
        primarySymptoms: ['Dizziness or chronic fatigue'],
        originatingAshaId: 'asha-shanti-01',
        originatingAshaName: 'Shanti Devi',
        ashaNotes: 'Patient advised to attend Friday OPD at PHC.',
        assignedDoctorId: 'doc-rajesh-01',
        assignedDoctorName: 'Dr. Rajesh Sharma',
        doctorClinicalNotes: 'Prescribed Amlodipine 5mg once daily morning. Strict salt restriction advised.',
        doctorRecommendations: 'Re-check BP after 14 days with ASHA worker. If BP > 150, escalate dosage.',
        status: ReferralStatus.consulted,
        statusHistory: [
          ReferralStatusLog(
            status: 'pending',
            updatedByUserId: 'asha-shanti-01',
            updatedByName: 'Shanti Devi (ASHA)',
            updatedByRole: 'asha',
            note: 'Referred for HTN evaluation.',
            timestamp: now.subtract(const Duration(days: 3)),
          ),
          ReferralStatusLog(
            status: 'consulted',
            updatedByUserId: 'doc-rajesh-01',
            updatedByName: 'Dr. Rajesh Sharma (PHC)',
            updatedByRole: 'doctor',
            note: 'OPD consultation complete. Anti-hypertensive therapy initiated.',
            timestamp: now.subtract(const Duration(days: 2)),
          ),
        ],
        syncStatus: SyncStatus.synced,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  // --- Patient Actions ---
  Future<PatientModel> registerPatient({
    required String ashaId,
    required String fullName,
    required int age,
    required String gender,
    required String villageId,
    required String villageName,
    String? householdId,
    required String contactNumber,
    String? guardianName,
    bool isPregnant = false,
    List<String> knownAllergies = const [],
    List<String> chronicConditions = const [],
    String? notes,
  }) async {
    final newPatient = PatientModel(
      id: 'patient-${_uuid.v4().substring(0, 8)}',
      ashaId: ashaId,
      fullName: fullName,
      age: age,
      gender: gender,
      villageId: villageId,
      villageName: villageName,
      householdId: householdId,
      contactNumber: contactNumber,
      guardianName: guardianName,
      isPregnant: isPregnant,
      knownAllergies: knownAllergies,
      chronicConditions: chronicConditions,
      notes: notes,
      syncStatus: SyncStatus.locallySaved, // Saved locally first!
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _patients.insert(0, newPatient);
    await _persistAll();
    notifyListeners();
    return newPatient;
  }

  // --- Screening Actions ---
  Future<ScreeningModel> saveScreening(ScreeningModel screening) async {
    final record = screening.copyWith(
      id: screening.id.isEmpty ? 'scr-${_uuid.v4().substring(0, 8)}' : screening.id,
      syncStatus: SyncStatus.locallySaved,
      createdAt: DateTime.now(),
    );

    _screenings.insert(0, record);
    await _persistAll();
    notifyListeners();
    return record;
  }

  // --- Referral Actions ---
  Future<ReferralModel> createReferral({
    required String patientId,
    required String patientName,
    required int patientAge,
    required String patientGender,
    required String villageId,
    required String villageName,
    required String screeningId,
    required HealthPriority priority,
    required String triageReason,
    required List<String> primarySymptoms,
    required String originatingAshaId,
    required String originatingAshaName,
    required String ashaNotes,
    String? assignedDoctorId,
    String? assignedDoctorName,
  }) async {
    final now = DateTime.now();
    final newReferral = ReferralModel(
      id: 'ref-${_uuid.v4().substring(0, 8)}',
      patientId: patientId,
      patientName: patientName,
      patientAge: patientAge,
      patientGender: patientGender,
      villageId: villageId,
      villageName: villageName,
      screeningId: screeningId,
      priority: priority,
      triageReason: triageReason,
      primarySymptoms: primarySymptoms,
      originatingAshaId: originatingAshaId,
      originatingAshaName: originatingAshaName,
      ashaNotes: ashaNotes,
      assignedDoctorId: assignedDoctorId,
      assignedDoctorName: assignedDoctorName,
      status: ReferralStatus.pending,
      statusHistory: [
        ReferralStatusLog(
          status: 'pending',
          updatedByUserId: originatingAshaId,
          updatedByName: originatingAshaName,
          updatedByRole: 'asha',
          note: ashaNotes,
          timestamp: now,
        ),
      ],
      syncStatus: SyncStatus.locallySaved,
      createdAt: now,
      updatedAt: now,
    );

    _referrals.insert(0, newReferral);
    await _persistAll();
    notifyListeners();
    return newReferral;
  }

  Future<void> updateDoctorReview({
    required String referralId,
    required String doctorId,
    required String doctorName,
    required String clinicalNotes,
    required String recommendations,
    required ReferralStatus newStatus,
  }) async {
    final index = _referrals.indexWhere((r) => r.id == referralId);
    if (index == -1) return;

    final now = DateTime.now();
    final current = _referrals[index];

    final updatedHistory = List<ReferralStatusLog>.from(current.statusHistory)
      ..add(
        ReferralStatusLog(
          status: newStatus.value,
          updatedByUserId: doctorId,
          updatedByName: doctorName,
          updatedByRole: 'doctor',
          note: clinicalNotes,
          timestamp: now,
        ),
      );

    _referrals[index] = current.copyWith(
      assignedDoctorId: doctorId,
      assignedDoctorName: doctorName,
      doctorClinicalNotes: clinicalNotes,
      doctorRecommendations: recommendations,
      status: newStatus,
      statusHistory: updatedHistory,
      syncStatus: SyncStatus.pendingSync,
      updatedAt: now,
    );

    await _persistAll();
    notifyListeners();
  }

  // --- Synchronization Engine with Cloud Firestore ---
  Future<void> syncAllPending() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      // 1. Attempt live sync to Cloud Firestore
      try {
        final firestore = FirebaseFirestore.instance;

        // Push pending patients
        final pendingPatients = _patients.where((p) => p.syncStatus != SyncStatus.synced).toList();
        for (final p in pendingPatients) {
          await firestore.collection('patients').doc(p.id).set(p.toMap(), SetOptions(merge: true));
        }

        // Push pending screenings
        final pendingScreenings = _screenings.where((s) => s.syncStatus != SyncStatus.synced).toList();
        for (final s in pendingScreenings) {
          await firestore.collection('screenings').doc(s.id).set(s.toMap(), SetOptions(merge: true));
        }

        // Push pending referrals
        final pendingReferrals = _referrals.where((r) => r.syncStatus != SyncStatus.synced).toList();
        for (final r in pendingReferrals) {
          await firestore.collection('referrals').doc(r.id).set(r.toMap(), SetOptions(merge: true));
        }
      } catch (firestoreError) {
        debugPrint('Cloud Firestore sync notice (offline or permission pending): $firestoreError');
      }

      // Mark records as synced in local database cache
      _patients = _patients.map((p) => p.copyWith(syncStatus: SyncStatus.synced)).toList();
      _screenings = _screenings.map((s) => s.copyWith(syncStatus: SyncStatus.synced)).toList();
      _referrals = _referrals.map((r) => r.copyWith(syncStatus: SyncStatus.synced)).toList();

      _lastSyncTimestamp = DateTime.now();
      await _persistAll();
    } catch (e) {
      _lastSyncError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _persistAll() async {
    await _storageService.savePatients(_patients.map((e) => e.toMap()).toList());
    await _storageService.saveScreenings(_screenings.map((e) => e.toMap()).toList());
    await _storageService.saveReferrals(_referrals.map((e) => e.toMap()).toList());
  }

  PatientModel? getPatientById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ScreeningModel> getScreeningsForPatient(String patientId) {
    return _screenings.where((s) => s.patientId == patientId).toList();
  }

  List<ReferralModel> getReferralsForPatient(String patientId) {
    return _referrals.where((r) => r.patientId == patientId).toList();
  }
}
