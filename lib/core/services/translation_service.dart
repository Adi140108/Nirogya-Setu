import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Clinical translation service that converts patient complaints/symptoms from
/// any regional Indian language into clear, professional clinical English.
class TranslationService {
  static const String _defaultGroqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  /// Offline dictionary of common health phrases across Indian languages
  /// for instant, 100% reliable offline fallback.
  static final Map<String, String> _offlineDictionary = {
    // Hindi phrases
    'मुझे बुखार है': 'Patient has fever.',
    'मुझे तेज़ बुखार है': 'Patient has high fever and body chills.',
    'सिर में दर्द': 'Patient has headache.',
    'सिरदर्द': 'Patient reports headache.',
    'दवा चाहिए': 'Request for medicine refill.',
    'दवा खत्म हो गई है': 'Medicines have run out; requests refill.',
    'पेट में दर्द': 'Patient reports abdominal pain.',
    'उल्टी और दस्त': 'Patient suffering from vomiting and diarrhea.',
    'खांसी और जुकाम': 'Patient has cough and cold.',
    'सांस लेने में तकलीफ': 'Patient is experiencing difficulty in breathing.',
    'गर्भवती महिला': 'Pregnant woman needs maternal health checkup.',
    'चक्कर आ रहे हैं': 'Patient experiences dizziness/vertigo.',

    // Kannada phrases
    'ಜ್ವರ ಬಂದಿದೆ': 'Patient has fever.',
    'ತಲೆನೋವು': 'Patient has severe headache.',
    'ಔಷಧಿ ಮುಗಿದಿದೆ': 'Medicines have run out; refill needed.',
    'ಹೊಟ್ಟೆ ನೋವು': 'Patient reports abdominal pain.',
    'ಕೆಮ್ಮು ಮತ್ತು ಶೀತ': 'Patient suffering from cough and cold.',

    // Tamil phrases
    'எனக்கு காய்ச்சல்': 'Patient has fever.',
    'தலைவலி': 'Patient has headache.',
    'மருந்து வேண்டும்': 'Medicine refill requested.',
    'வயிற்று வலி': 'Patient has stomach pain.',

    // Telugu phrases
    'నాకు జ్వరం వచ్చింది': 'Patient has fever.',
    'తలనొప్పి': 'Patient has headache.',
    'మందులు అయిపోయాయి': 'Medicines depleted; refill required.',
    'కడుపు నొప్పి': 'Patient reports abdominal pain.',

    // Bengali phrases
    'আমার জ্বর হয়েছে': 'Patient has fever.',
    'মাথাব্যথা': 'Patient has headache.',
    'ঔষধ শেষ হয়ে গেছে': 'Medicines depleted; refill requested.',
    'পেট ব্যথা': 'Patient reports stomach ache.',

    // Marathi phrases
    'मला ताप आला आहे': 'Patient has fever.',
    'डोकेदुखी': 'Patient reports headache.',
    'औषध संपले आहे': 'Medicines depleted; refill requested.',
    'पोटदुखी': 'Patient reports stomach pain.',
  };

  /// Translate user query/transcription in any language to clinical English.
  static Future<String> translateToEnglish(String input) async {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return '';

    // If text already appears to be pure English ASCII with reasonable length, return it directly
    final isPureEnglish = RegExp(r'^[\x00-\x7F]+$').hasMatch(cleanInput) &&
        !cleanInput.toLowerCase().contains('didi') &&
        !cleanInput.toLowerCase().contains('namaste');
    if (isPureEnglish && cleanInput.split(' ').length > 2) {
      // Check if it's already English sentence
      final commonEnglishWords = ['patient', 'fever', 'headache', 'medicine', 'pain', 'have', 'the', 'is', 'for', 'need'];
      final containsEnglishWords = commonEnglishWords.any((w) => cleanInput.toLowerCase().contains(w));
      if (containsEnglishWords) {
        return cleanInput;
      }
    }

    // Try translating via Groq cloud AI if configured
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('groq_api_key');
      final apiKey = (savedKey != null && savedKey.trim().isNotEmpty)
          ? savedKey.trim()
          : _defaultGroqApiKey.trim();

      if (apiKey.isNotEmpty) {
        final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'qwen/qwen3.8-27b',
            'messages': [
              {
                'role': 'system',
                'content': 'You are a medical translator for rural Indian healthcare (Aarogya Setu). '
                    'Translate the patient health complaint or symptoms from any Indian language (Hindi, Kannada, Tamil, Telugu, Bengali, Marathi, Hinglish, etc.) into concise, professional, standard clinical English. '
                    'Keep important clinical facts, symptoms, duration, and urgency intact. '
                    'OUTPUT ONLY THE ENGLISH TRANSLATION. Do not include quotes, explanations, or introductory text.',
              },
              {
                'role': 'user',
                'content': cleanInput,
              }
            ],
            'temperature': 0.1,
            'max_tokens': 300,
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['choices']?[0]?['message']?['content']?.toString().trim();
          if (text != null && text.isNotEmpty) {
            return text.replaceAll('"', '').trim();
          }
        }
      }
    } catch (e) {
      debugPrint('Translation AI notice: $e');
    }

    // Offline rule-based translation fallback
    for (final entry in _offlineDictionary.entries) {
      if (cleanInput.contains(entry.key)) {
        return '${entry.value} (Original: "$cleanInput")';
      }
    }

    // If English or unmapped, provide cleanly formatted string
    if (isPureEnglish) {
      return cleanInput;
    }

    // Fallback descriptor indicating patient's message
    return 'Patient health report: "$cleanInput"';
  }
}
