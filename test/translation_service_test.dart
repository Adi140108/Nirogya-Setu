import 'package:flutter_test/flutter_test.dart';
import 'package:aarogya_setu/core/services/translation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TranslationService Tests', () {
    test('translates common Hindi symptom to clinical English offline', () async {
      final res = await TranslationService.translateToEnglish('मुझे तेज़ बुखार है');
      expect(res, contains('Patient has high fever and body chills'));
    });

    test('translates Kannada symptom to clinical English offline', () async {
      final res = await TranslationService.translateToEnglish('ಜ್ವರ ಬಂದಿದೆ');
      expect(res, contains('Patient has fever'));
    });

    test('preserves English sentences intact', () async {
      final res = await TranslationService.translateToEnglish('Patient has severe headache and needs paracetamol');
      expect(res, equals('Patient has severe headache and needs paracetamol'));
    });
  });
}
