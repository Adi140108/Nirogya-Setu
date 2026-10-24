import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aarogya_setu/features/asha_portal/screens/asha_chatbot_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ASHA Chatbot Screen & Qwen Configuration Tests', () {
    testWidgets('renders ASHA Clinical Assistant title and initial message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AshaChatbotScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Aarogya Setu'), findsOneWidget);
      expect(find.text('ASHA Clinical Assistant'), findsOneWidget);

      // Verify the 4 clinical criteria in initial welcome message
      expect(find.textContaining('Qwen on Groq'), findsOneWidget);
      expect(find.textContaining('1. Patient symptom assessment & triage'), findsOneWidget);
      expect(find.textContaining('2. Basic ASHA-administerable medicines'), findsOneWidget);
      expect(find.textContaining('3. Professional Doctor Referral recommendation'), findsOneWidget);
      expect(find.textContaining('4. Specific specialist & pre-referral requirements'), findsOneWidget);
    });

    testWidgets('activates Qwen model by default with default Groq API key', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AshaChatbotScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check badge displays "Qwen"
      expect(find.text('Qwen'), findsOneWidget);
    });

    testWidgets('offline clinical knowledge engine responds correctly to fever query', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AshaChatbotScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the TextField and type a symptom inquiry
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Patient has high fever and chills');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Check offline response contains fever triage & basic medicine (Paracetamol)
      expect(find.textContaining('FEVER TRIAGE & RURAL PROTOCOL'), findsOneWidget);
      expect(find.textContaining('Paracetamol'), findsOneWidget);
      expect(find.textContaining('Refer to PHC'), findsOneWidget);
    });

    testWidgets('offline clinical knowledge engine handles pregnancy warning query', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AshaChatbotScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Pregnant woman with severe headache');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Check for pregnancy danger flags and emergency referral
      expect(find.textContaining('PREGNANCY WARNING SIGNS (RED FLAGS)'), findsOneWidget);
      expect(find.textContaining('Immediate RED referral to Community Health Centre'), findsOneWidget);
      expect(find.textContaining('108 ambulance'), findsOneWidget);
    });

    testWidgets('opens Settings dialog and displays Qwen as recommended model choice', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AshaChatbotScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap settings button
      final settingsBtn = find.byIcon(Icons.settings_outlined);
      expect(settingsBtn, findsOneWidget);
      await tester.tap(settingsBtn);
      await tester.pumpAndSettle();

      // Verify dialog contents
      expect(find.text('Assistant Settings'), findsOneWidget);
      expect(find.textContaining('console.groq.com'), findsWidgets);
      expect(find.textContaining('Qwen 3.8 27B (Alibaba - Active)'), findsOneWidget);
      expect(find.textContaining('Never hardcoded'), findsOneWidget);

      // Verify Cancel closes the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Assistant Settings'), findsNothing);
    });

    testWidgets('saving Groq API key updates badge to AI model name', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AshaChatbotScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Open settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Enter mock Groq API Key
      final keyField = find.widgetWithText(TextField, 'Groq API Key');
      await tester.enterText(keyField, 'gsk_test_fake_api_key_1234567890');

      // Click Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Badge should switch from "Offline Engine" to "Qwen"
      expect(find.text('Offline Engine'), findsNothing);
      expect(find.text('Qwen'), findsOneWidget);
    });

    testWidgets('action chip automatically submits query and displays results', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AshaChatbotScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the first visible chip: 'Danger signs in pregnancy (ANC)'
      final chip = find.text('Danger signs in pregnancy (ANC)');
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      // Confirm pregnancy triage protocol output
      expect(find.textContaining('PREGNANCY WARNING SIGNS (RED FLAGS)'), findsOneWidget);
      expect(find.textContaining('Immediate RED referral to Community Health Centre'), findsOneWidget);
    });
  });
}
