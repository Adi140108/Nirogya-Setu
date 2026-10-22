import 'package:flutter_test/flutter_test.dart';
import 'package:aarogya_setu/core/constants/screening_rules.dart';
import 'package:aarogya_setu/core/models/patient_model.dart';
import 'package:aarogya_setu/core/models/referral_model.dart';
import 'package:aarogya_setu/core/models/sync_status.dart';
import 'package:aarogya_setu/core/models/user_model.dart';
import 'package:aarogya_setu/core/models/awareness_content_model.dart';

void main() {
  group('AarogyaSetu AI Decision Support & Screening Rules Engine Tests', () {
    test('Normal vitals and no symptoms should triage as GREEN', () {
      final assessment = ScreeningRulesEngine.evaluate(
        systolicBP: 118,
        diastolicBP: 78,
        pulseRate: 72,
        temperatureF: 98.4,
        bloodSugarMgDl: 95,
        spo2Percent: 98,
        selectedSymptoms: [],
        isPregnant: false,
        notes: '',
      );

      expect(assessment.priority, HealthPriority.green);
      expect(assessment.categoryTitle.contains('GREEN'), isTrue);
      expect(assessment.flaggedConcerns.isEmpty, isTrue);
    });

    test('Stage 2 Hypertension (160/100) should triage as YELLOW', () {
      final assessment = ScreeningRulesEngine.evaluate(
        systolicBP: 160,
        diastolicBP: 100,
        pulseRate: 75,
        temperatureF: 98.6,
        bloodSugarMgDl: 110,
        spo2Percent: 97,
        selectedSymptoms: ['Dizziness or chronic fatigue'],
        isPregnant: false,
        notes: '',
      );

      expect(assessment.priority, HealthPriority.yellow);
      expect(assessment.categoryTitle.contains('YELLOW'), isTrue);
      expect(assessment.flaggedConcerns.isNotEmpty, isTrue);
    });

    test('Severe hypoxia (<90%) or chest pain should triage as RED emergency', () {
      final assessment = ScreeningRulesEngine.evaluate(
        systolicBP: 130,
        diastolicBP: 85,
        pulseRate: 115,
        temperatureF: 101.5,
        bloodSugarMgDl: 140,
        spo2Percent: 88, // Critical Hypoxia
        selectedSymptoms: ['Chest pain or pressure'],
        isPregnant: false,
        notes: '',
      );

      expect(assessment.priority, HealthPriority.red);
      expect(assessment.categoryTitle.contains('RED'), isTrue);
      expect(assessment.reason.contains('Critical Hypoxia'), isTrue);
      expect(assessment.recommendedNextStep.contains('within 24 hours'), isTrue);
    });

    test('Antenatal mother exhibiting warning symptoms gets elevated risk', () {
      final assessment = ScreeningRulesEngine.evaluate(
        systolicBP: 135,
        diastolicBP: 88,
        pulseRate: 85,
        temperatureF: 99.0,
        bloodSugarMgDl: 120,
        spo2Percent: 96,
        selectedSymptoms: ['Dizziness or chronic fatigue'],
        isPregnant: true,
        notes: '',
      );

      expect(assessment.priority, HealthPriority.red);
      expect(assessment.reason.contains('Maternal Health Warning'), isTrue);
    });

    test('Biological plausibility validation correctly rejects impossible values', () {
      // Systolic BP range is 50-260
      expect(ScreeningRulesEngine.validateSystolicBP('400'), isNotNull);
      expect(ScreeningRulesEngine.validateSystolicBP('120'), isNull);

      // Diastolic must be less than systolic
      expect(ScreeningRulesEngine.validateDiastolicBP('130', '120'), isNotNull);
      expect(ScreeningRulesEngine.validateDiastolicBP('80', '120'), isNull);

      // Pulse range is 30-220
      expect(ScreeningRulesEngine.validatePulse('350'), isNotNull);
      expect(ScreeningRulesEngine.validatePulse('72'), isNull);

      // Temperature range is 92-108 F
      expect(ScreeningRulesEngine.validateTemperature('120'), isNotNull);
      expect(ScreeningRulesEngine.validateTemperature('98.6'), isNull);
    });
  });

  group('Domain Models & Serialization Tests', () {
    test('PatientModel serialization and sync status handling', () {
      final now = DateTime.now();
      final patient = PatientModel(
        id: 'patient-test-01',
        ashaId: 'asha-01',
        fullName: 'Kamla Devi',
        age: 44,
        gender: 'Female',
        villageId: 'village-rampura-01',
        villageName: 'Rampura',
        contactNumber: '+91 99999 88888',
        syncStatus: SyncStatus.locallySaved,
        createdAt: now,
        updatedAt: now,
      );

      final map = patient.toMap();
      expect(map['fullName'], 'Kamla Devi');
      expect(map['syncStatus'], 'locally_saved');

      final deserialized = PatientModel.fromMap(map);
      expect(deserialized.id, 'patient-test-01');
      expect(deserialized.syncStatus, SyncStatus.locallySaved);
    });

    test('ReferralModel audit log timestamps and status progression', () {
      final now = DateTime.now();
      final log = ReferralStatusLog(
        status: 'consulted',
        updatedByUserId: 'doc-01',
        updatedByName: 'Dr. Sharma',
        updatedByRole: 'doctor',
        note: 'Initiated medication',
        timestamp: now,
      );

      final referral = ReferralModel(
        id: 'ref-test-01',
        patientId: 'patient-test-01',
        patientName: 'Kamla Devi',
        patientAge: 44,
        patientGender: 'Female',
        villageId: 'village-rampura-01',
        villageName: 'Rampura',
        screeningId: 'scr-01',
        priority: HealthPriority.yellow,
        triageReason: 'Stage 1 HTN',
        originatingAshaId: 'asha-01',
        originatingAshaName: 'Shanti Devi',
        ashaNotes: 'Advised PHC visit',
        status: ReferralStatus.consulted,
        statusHistory: [log],
        createdAt: now,
        updatedAt: now,
      );

      final map = referral.toMap();
      final deserialized = ReferralModel.fromMap(map);
      expect(deserialized.status, ReferralStatus.consulted);
      expect(deserialized.statusHistory.length, 1);
      expect(deserialized.statusHistory.first.updatedByName, 'Dr. Sharma');
    });

    test('AwarenessContentModel download status transitions', () {
      const content = AwarenessContentModel(
        id: 'vid-01',
        title: 'Dengue Prevention',
        topic: 'Vector-borne',
        description: 'Mosquito control guidance',
        language: 'Hindi',
        source: 'MoHFW',
        reviewDate: 'Oct 2026',
        version: 1,
        remoteVideoUrl: 'https://example.com/video.mp4',
        downloadStatus: VideoDownloadStatus.notDownloaded,
        isVerifiedGuidance: true,
      );

      expect(content.downloadStatus, VideoDownloadStatus.notDownloaded);

      final downloading = content.copyWith(
        downloadStatus: VideoDownloadStatus.downloading,
        downloadProgress: 0.5,
      );
      expect(downloading.downloadStatus, VideoDownloadStatus.downloading);
      expect(downloading.downloadProgress, 0.5);

      final downloaded = downloading.copyWith(
        downloadStatus: VideoDownloadStatus.downloaded,
        downloadProgress: 1.0,
        localFilePath: '/data/app/vid-01.mp4',
      );
      expect(downloaded.downloadStatus, VideoDownloadStatus.downloaded);
      expect(downloaded.localFilePath, isNotNull);
    });

    test('UserRole isolated authorization permissions', () {
      expect(UserRole.asha.value, 'asha');
      expect(UserRole.doctor.value, 'doctor');
      expect(UserRole.patient.value, 'patient');

      expect(UserRoleExtension.fromString('doctor'), UserRole.doctor);
      expect(UserRoleExtension.fromString('asha'), UserRole.asha);
      expect(UserRoleExtension.fromString('patient'), UserRole.patient);
    });
  });
}
