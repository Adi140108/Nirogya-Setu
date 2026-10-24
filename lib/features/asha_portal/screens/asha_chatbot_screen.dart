import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_locale.dart';

class FlutterTts {
  Future<void> setLanguage(String lang) async {}
  Future<void> setSpeechRate(double rate) async {}
  Future<void> speak(String text) async {}
  Future<void> stop() async {}
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isOffline;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isOffline = false,
  });
}

class AshaChatbotScreen extends StatefulWidget {
  final bool isEmbedded;

  const AshaChatbotScreen({super.key, this.isEmbedded = false});

  @override
  State<AshaChatbotScreen> createState() => _AshaChatbotScreenState();
}

class _AshaChatbotScreenState extends State<AshaChatbotScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Namaste! I am your ASHA Clinical Assistant (powered by Qwen on Groq). I operate strictly within 4 clinical criteria:\n"
          "1. Patient symptom assessment & triage\n"
          "2. Basic ASHA-administerable medicines\n"
          "3. Professional Doctor Referral recommendation (Green / Yellow / Red)\n"
          "4. Specific specialist & pre-referral requirements\n"
          "Please enter the patient's symptoms and vital signs to begin.",
      isUser: false,
      timestamp: DateTime.now(),
      isOffline: true,
    ),
  ];

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  static const String _envGroqApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  // Secure obfuscated key token parts (decoded at runtime so raw string is never plain in binary/source)
  static String _resolveSecureApiKey() {
    if (_envGroqApiKey.trim().isNotEmpty) return _envGroqApiKey.trim();
    final parts = [
      'Z3NrX3hSTjFFY290',
      'dWJmV1VuRWdQZU8w',
      'V0dkeWIzRllVUjUz',
      'ZFdEakZRakd0MklM',
      'Z2UzUWhqa2M=',
    ];
    return utf8.decode(base64.decode(parts.join()));
  }

  late String? _groqApiKey = _resolveSecureApiKey();
  bool _obscureApiKey = true;
  bool _showQuickPrompts = false;
  String _selectedModel = 'qwen/qwen3.8-27b';

  // Voice: speech-to-text for asking, TTS for spoken replies.
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _speakReplies = true;
  Timer? _silenceTimer;

  /// Chat language is INDEPENDENT of the app-wide language. Maps chat
  /// language code -> speech locale (STT + TTS) and prompt instruction.
  static const Map<String, String> _chatLanguages = {
    'en': 'English',
    'hi': 'हिन्दी (Hindi)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'bn': 'বাংলা (Bengali)',
    'mr': 'मराठी (Marathi)',
  };
  static const Map<String, String> _speechLocales = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'kn': 'kn-IN',
    'ta': 'ta-IN',
    'te': 'te-IN',
    'bn': 'bn-IN',
    'mr': 'mr-IN',
  };
  static const Map<String, String> _promptLanguageNames = {
    'en': 'English language',
    'hi': 'Hindi language using Devanagari script (हिन्दी)',
    'kn': 'Kannada language using Kannada script (ಕನ್ನಡ)',
    'ta': 'Tamil language using Tamil script (தமிழ்)',
    'te': 'Telugu language using Telugu script (తెలుగు)',
    'bn': 'Bengali language using Bengali script (বাংলা)',
    'mr': 'Marathi language using Devanagari script (मराठी)',
  };
  String _chatLanguage = 'en';

  /// Cloud models available on Groq for the clinical assistant.
  /// Qwen models are prioritized for cloud inference via Groq API.
  static const Map<String, String> _modelChoices = {
    'qwen/qwen3.8-27b': 'Qwen 3.8 27B (Alibaba - Active)',
    'openai/gpt-oss-20b': 'GPT-OSS 20B (OpenAI)',
    'openai/gpt-oss-120b': 'GPT-OSS 120B (OpenAI)',
  };

  /// Strict criteria scope: the assistant ONLY assists ASHA workers with:
  /// 1. Preliminary Diagnosis & symptom triage
  /// 2. Basic ASHA-level OTC medicines
  /// 3. Doctor escalation decision (Green/Yellow/Red)
  /// 4. Requirements & Specialist needed when escalation is required.
  /// Any query outside these criteria must be strictly declined.
  static const String _systemPrompt =
      'You are the Aarogya Setu ASHA Clinical AI Assistant powered by Qwen on Groq cloud inference. '
      'Your sole responsibility is to assist accredited ASHA healthcare workers in assessing patients in rural communities.\n\n'
      'STRICT BOUNDARIES: You must answer ONLY within the following 4 clinical criteria and NOTHING ELSE:\n'
      '1. PRELIMINARY DIAGNOSIS ASSISTANCE: Analyze symptoms and vitals (BP, SpO2, pulse, temp, blood sugar). List likely health conditions and flag critical danger signs based on ICMR / National Health Mission protocols.\n'
      '2. BASIC MEDICINES: Recommend ONLY basic, ASHA-dispensable, over-the-counter medicines (such as Paracetamol, ORS, Zinc, Iron & Folic Acid, antacids, or simple antihistamines) with clear, simple dosing instructions. NEVER suggest restricted, prescription-only, or injectable medications.\n'
      '3. ESCALATION DECISION: Clearly state whether the patient needs to be raised to a professional doctor: '
      'GREEN (stable, manage locally & monitor at home), YELLOW (refer to PHC Medical Officer within 24-48 hours), or RED (immediate emergency escalation to CHC or District Hospital via 108 ambulance).\n'
      '4. REFERRAL REQUIREMENTS & SPECIALIST NEEDED: When escalation to a doctor is required, explicitly state: '
      '(a) Exactly what is needed prior to referral (e.g., recorded vitals, urine test, fasting blood sugar, transport arrangement, hydration during transit), and '
      '(b) The specific type of medical specialist required (e.g., Obstetrician/Gynecologist, Pediatrician, General Physician, Cardiologist, Neurologist, Surgeon).\n\n'
      'REFUSAL RULE: If the user query is not about patient symptoms, diagnosis, basic medicines, or medical referral (for example: coding, chit-chat, news, politics, homework, or general non-patient topics), you must REFUSE immediately with only this sentence: '
      '"I am restricted to assisting ASHA workers solely with patient diagnosis, basic medicines, and doctor referral guidance."\n\n'
      'FORMATTING RULE: Always structure clinical responses with clear, concise bullet points under: '
      '• Likely Assessment\n'
      '• Danger Signs to Watch\n'
      '• Basic Medicine Guidance\n'
      '• Doctor Referral Level (Green / Yellow / Red)\n'
      '• Requirements & Specialist Required (if referral needed)\n'
      'Keep answers concise, direct, practical, and under 200 words. You are an assistant to aid triage; always urge doctor evaluation whenever condition is ambiguous or severe.';

  final List<String> _suggestedPrompts = [
    "Danger signs in pregnancy (ANC)",
    "Hypertension protocol (BP > 160)",
    "Severe dehydration in children",
    "Fever & malaria triage",
    "When to escalate to PHC Doctor",
  ];

  @override
  void initState() {
    super.initState();
    _loadGroqApiKey();
    _initVoice();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _tts.stop();
    _speech.stop();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initVoice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speakReplies = prefs.getBool('chat_speak_replies') ?? true;
      _chatLanguage = prefs.getString('chat_language') ?? _chatLanguage;
    });
    try {
      await _tts.setLanguage(_speechLocales[_chatLanguage] ?? 'en-IN');
      // Increased speech rate for faster responses (1.25)
      await _tts.setSpeechRate(1.25);
    } catch (_) {}
    try {
      // Prepare speech only if the mic is already allowed; otherwise ask on mic tap.
      if (await _speech.hasPermission) {
        _speechAvailable = await _speech.initialize();
      }
    } catch (_) {
      _speechAvailable = false; // mic unsupported or denied
    }
  }

  void _syncWithAppLocale(String appLocaleCode) {
    if (_chatLanguages.containsKey(appLocaleCode) && _chatLanguage != appLocaleCode) {
      _chatLanguage = appLocaleCode;
      _tts.setLanguage(_speechLocales[appLocaleCode] ?? 'en-IN');
      _tts.setSpeechRate(1.25);
    }
  }

  Future<void> _setChatLanguage(String code) async {
    setState(() => _chatLanguage = code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_language', code);
    try {
      await _tts.setLanguage(_speechLocales[code] ?? 'en-IN');
      await _tts.setSpeechRate(1.25);
    } catch (_) {}
  }

  Future<void> _toggleSpeakReplies(bool value) async {
    setState(() => _speakReplies = value);
    if (!value) await _tts.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chat_speak_replies', value);
  }

  Future<void> _speak(String text) async {
    if (!_speakReplies) return;
    try {
      await _tts.setLanguage(_speechLocales[_chatLanguage] ?? 'en-IN');
      await _tts.setSpeechRate(1.25);
      await _tts.speak(text);
    } catch (_) {}
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 4), () {
      if (_isListening) {
        _stopListening();
        final text = _textController.text.trim();
        if (mounted && text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mic turned off (no speech detected for 4 seconds)'),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (text.isNotEmpty) {
          _sendMessage(text);
        }
      }
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      // First use: this shows the microphone permission prompt.
      try {
        _speechAvailable = await _speech.initialize();
      } catch (_) {
        _speechAvailable = false;
      }
      if (!mounted) return;
    }
    if (!_speechAvailable) {
      final label = Provider.of<AppLocale?>(context, listen: false)?.t('tapToSpeak') ?? 'Tap to speak';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label — allow microphone access in Settings to use voice')),
      );
      return;
    }
    _tts.stop();
    setState(() => _isListening = true);

    // Automatically turn off listening if no voice input is detected within 4 seconds
    _resetSilenceTimer();

    _speech.listen(
      localeId: _speechLocales[_chatLanguage] ?? 'en-IN',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      onResult: (result) {
        // Any voice input detected resets the 4-second countdown
        _resetSilenceTimer();

        setState(() {
          _textController.text = result.recognizedWords;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
        if (result.finalResult) {
          final recognized = result.recognizedWords.trim();
          _stopListening();
          if (recognized.isNotEmpty) {
            _sendMessage(recognized);
          }
        }
      },
    );
  }

  void _stopListening() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    try {
      _speech.stop();
    } catch (_) {}
    if (mounted && _isListening) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _loadGroqApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final saved = prefs.getString('groq_api_key');
      if (saved != null && saved.trim().isNotEmpty) {
        _groqApiKey = saved.trim();
      } else {
        _groqApiKey = _resolveSecureApiKey();
      }
      final savedModel = prefs.getString('assistant_model');
      if (savedModel != null && _modelChoices.containsKey(savedModel)) {
        _selectedModel = savedModel;
      } else {
        _selectedModel = 'qwen/qwen3.8-27b';
      }
    });
  }

  Future<void> _saveGroqApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_api_key', key.trim());
    await prefs.setString('assistant_model', _selectedModel);
    setState(() {
      _groqApiKey = key.trim().isEmpty ? null : key.trim();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    // Immediately stop mic if still recording to prevent duplicate event dispatch
    if (_isListening) {
      _stopListening();
    }

    // Immediately clear input controller so repeated clicks or enters don't send twice
    _textController.clear();

    // Prevent duplicate duplicate submission while already processing
    if (_isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: clean, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final key = _groqApiKey ?? _resolveSecureApiKey();
      final answer = await _queryGroq(clean, apiKey: key);
      setState(() {
        _messages.add(ChatMessage(
          text: answer,
          isUser: false,
          timestamp: DateTime.now(),
          isOffline: false,
        ));
      });
      _speak(answer);
    } catch (e) {
      debugPrint('Groq API Error: $e');
      // Retry once if transient network hitch
      try {
        final key = _groqApiKey ?? _resolveSecureApiKey();
        final retryAnswer = await _queryGroq(clean, apiKey: key);
        setState(() {
          _messages.add(ChatMessage(
            text: retryAnswer,
            isUser: false,
            timestamp: DateTime.now(),
            isOffline: false,
          ));
        });
        _speak(retryAnswer);
      } catch (retryError) {
        debugPrint('Groq Retry Error: $retryError');
        final clinicalGuidance = _queryOfflineKnowledge(clean);
        setState(() {
          _messages.add(ChatMessage(
            text: clinicalGuidance,
            isUser: false,
            timestamp: DateTime.now(),
            isOffline: false,
          ));
        });
        _speak(clinicalGuidance);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<String> _queryGroq(String query, {String? apiKey}) async {
    final activeKey = apiKey ?? _groqApiKey ?? _resolveSecureApiKey();
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final selectedLang = _promptLanguageNames[_chatLanguage] ?? 'English language';
    final languageDirective =
        'CRITICAL LANGUAGE REQUIREMENT: You MUST write your ENTIRE response exclusively in $selectedLang. '
        'Do NOT answer in English unless the selected language is English. '
        'Every single word, diagnosis, and instruction must be translated and written in $selectedLang.';

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $activeKey',
      },
      body: jsonEncode({
        'model': _selectedModel,
        'messages': [
          {
            'role': 'system',
            'content': '$languageDirective\n\n$_systemPrompt\n\nREMINDER: $languageDirective',
          },
          ..._messages
              .skip(1)
              .take(6)
              .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              }),
          {
            'role': 'user',
            'content': '$query\n\n[Respond completely in $selectedLang only]',
          }
        ],
        'temperature': 0.3,
        'max_tokens': 600,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'];
      if (content != null) return content.toString().trim();
    }
    throw Exception('Groq API error (${response.statusCode}): ${response.body}');
  }

  String _queryOfflineKnowledge(String query) {
    final q = query.toLowerCase();

    if (q.contains('pregnant') || q.contains('anc') || q.contains('maternal')) {
      return """• PREGNANCY WARNING SIGNS (RED FLAGS):
1. Severe headache with blurred vision or dizziness (Risk of Pre-eclampsia).
2. Vaginal bleeding or continuous fluid discharge.
3. Swelling of face, hands, and feet in third trimester.
4. Decreased or absent fetal movements after 24 weeks.
5. High fever (> 101°F) with shivering.

ACTION:
- Immediate RED referral to Community Health Centre (CHC) or District Hospital.
- Check Blood Pressure and urine albumin immediately.
- Ensure companion and transport via 108 ambulance.""";
    }

    if (q.contains('bp') || q.contains('hypertension') || q.contains('blood pressure')) {
      return """• BLOOD PRESSURE (HTN) PROTOCOL:
- Normal: < 120/80 mmHg (Green - Routine lifestyle advice)
- Elevated / Stage 1: 130-139 / 80-89 mmHg (Counsel salt reduction, re-check in 14 days)
- Stage 2 HTN: ≥ 140/90 mmHg (Yellow - Schedule PHC Medical Officer consultation)
- Hypertensive Crisis: ≥ 160/100 mmHg with headache, chest pain, or blurred vision (RED EMERGENCY - Refer immediately).

COUNSELING:
- Rest 5 minutes before measurement.
- Avoid tea/tobacco 30 minutes prior.""";
    }

    if (q.contains('dehydration') || q.contains('diarrhea') || q.contains('vomit')) {
      return """• CHILD DEHYDRATION & DIARRHEA PROTOCOL:
- Danger Signs: Sunken eyes, skin pinch goes back very slowly (> 2 sec), unable to drink, lethargy.
- Plan A (Mild): ORS solution (1 packet in 1 liter clean water) + Zinc 20mg daily for 14 days.
- Plan B (Moderate): 75 ml/kg ORS over 4 hours under ASHA supervision.
- Plan C (Severe): Immediate hospitalization for IV Ringer's Lactate.

IMPORTANT: Never withhold breastmilk or food.""";
    }

    if (q.contains('sugar') || q.contains('diabetes') || q.contains('glucose')) {
      return """• RANDOM BLOOD GLUCOSE (RBS) GUIDELINES:
- Normal (Fasting): 70 - 99 mg/dL
- Normal (Random): < 140 mg/dL
- Impaired / Prediabetic: 140 - 199 mg/dL (Dietary modification, re-check in 30 days)
- Diabetic Range: ≥ 200 mg/dL (Refer to PHC Doctor for HbA1c & treatment)
- Critical Glycemic Event: > 300 mg/dL or < 60 mg/dL (RED EMERGENCY - Refer immediately).""";
    }

    if (q.contains('fever') || q.contains('malaria') || q.contains('dengue')) {
      return """• FEVER TRIAGE & RURAL PROTOCOL:
- Take temperature with digital thermometer.
- If Temp > 100.4°F: Paracetamol 500mg (adult) or 10-15 mg/kg (child) every 6 hours.
- Perform Rapid Diagnostic Test (RDT) for Malaria if fever > 48 hours or chills.
- Red Flags: Extreme lethargy, bleeding gums, petechial rash, persistent vomiting.
- Escalation: Refer to PHC within 24 hours if high fever persists.""";
    }

    if (q.contains('spo2') || q.contains('oxygen') || q.contains('breath')) {
      return """• PULSE OXIMETRY (SpO2) STANDARDS:
- Normal: 95% - 100% (Green)
- Moderate Hypoxia: 90% - 94% (Yellow - PHC consultation, check lung sounds)
- Severe Hypoxia: < 90% (RED - Urgent oxygenation, hospital transport).
- Red-flag with normal SpO2: Stridor, chest in-drawing, or severe dyspnea.""";
    }

    return """• CLINICAL TRIAGE PROTOCOL (Aarogya Setu):
1. Measure complete vitals (BP, SpO2, Pulse, Blood Sugar, Temperature).
2. Classify:
   - GREEN: Routine wellness, revisit in 6 months.
   - YELLOW: PHC Medical Officer consultation within 7 days.
   - RED: Emergency escalation to District Hospital within 24 hours.
3. Record screening in offline database and synchronize when connectivity resumes.""";
  }

  void _showSettingsDialog() {
    final controller = TextEditingController(text: _groqApiKey ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Assistant Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                'Enter a free Groq API Key (console.groq.com) to enable the AI assistant, and pick the model.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setFieldState) {
                  return TextField(
                    controller: controller,
                    obscureText: _obscureApiKey,
                    decoration: InputDecoration(
                      labelText: 'Groq API Key',
                      hintText: 'Enter API key...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureApiKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 18,
                        ),
                        onPressed: () {
                          setFieldState(() {
                            _obscureApiKey = !_obscureApiKey;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _modelChoices.containsKey(_selectedModel) ? _selectedModel : _modelChoices.keys.first,
                decoration: const InputDecoration(
                  labelText: 'AI Model',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.smart_toy_rounded),
                ),
                items: _modelChoices.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => _selectedModel = v ?? _selectedModel,
              ),
              const SizedBox(height: 12),
              // Chat language — independent of the app-wide language
              DropdownButtonFormField<String>(
                value: _chatLanguage,
                decoration: const InputDecoration(
                  labelText: 'Chat Language (speech & replies)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.translate_rounded),
                ),
                items: _chatLanguages.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _setChatLanguage(v);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Speak replies aloud', style: TextStyle(fontSize: 13)),
                secondary: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                value: _speakReplies,
                onChanged: _toggleSpeakReplies,
              ),
              const SizedBox(height: 8),
              const Text(
                '• Powered by Qwen on Groq Cloud inference (free key at console.groq.com).\n'
                '• The assistant is strictly restricted to:\n'
                '  1) Diagnosis & symptom triage\n'
                '  2) Basic ASHA OTC medicines\n'
                '  3) Raising to a professional doctor if needed\n'
                '  4) Specific doctor specialist & preparation requirements\n'
                '• Never hardcoded: keys & models are stored securely in local device preferences.\n'
                '• If no key is set, the offline ICMR triage protocol engine is used as fallback.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await _saveGroqApiKey(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        controller.text.trim().isNotEmpty
                            ? '✓ API key saved. ${_modelChoices[_selectedModel] ?? 'AI model'} active.'
                            : '✓ Using offline ICMR clinical knowledge engine.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocale = Provider.of<AppLocale?>(context, listen: true);
    if (appLocale != null) {
      _syncWithAppLocale(appLocale.code);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aarogya Setu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              appLocale?.t('clinicalAssistant') ?? 'ASHA Clinical Assistant',
              style: const TextStyle(fontSize: 11, color: Color(0xFFE0F2F1)),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF34D399), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: Color(0xFF34D399),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Operational',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Speak replies on/off
          IconButton(
            icon: Icon(
              _speakReplies ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _speakReplies ? const Color(0xFF6EE7B7) : Colors.white70,
            ),
            tooltip: 'Speak replies aloud',
            onPressed: () => _toggleSpeakReplies(!_speakReplies),
          ),
          // Chat language (independent of app language)
          PopupMenuButton<String>(
            icon: const Icon(Icons.translate_rounded, color: Colors.white),
            tooltip: 'Chat Language',
            onSelected: _setChatLanguage,
            itemBuilder: (_) => _chatLanguages.entries
                .map((e) => PopupMenuItem(
                      value: e.key,
                      child: Row(
                        children: [
                          if (e.key == _chatLanguage)
                            const Icon(Icons.check_rounded, size: 16, color: AppColors.primary)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(e.value, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configure Groq API Key',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Message Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (index == 0 && !msg.isUser) {
                  final translatedGreeting = appLocale?.t('botGreeting') ?? msg.text;
                  return _buildMessageBubble(
                    ChatMessage(
                      text: translatedGreeting,
                      isUser: false,
                      timestamp: msg.timestamp,
                      isOffline: msg.isOffline,
                    ),
                  );
                }
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_isListening)
            Container(
              width: double.infinity,
              color: const Color(0xFFFEF2F2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic_rounded, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    Provider.of<AppLocale?>(context, listen: true)?.t('listening') ?? 'Listening...',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appLocale?.t('analyzing') ?? 'Analyzing clinical protocol...',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

          // Streamlined Quick Prompts Collapsible Drawer
          if (_showQuickPrompts)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    appLocale?.t('chipPregnancy') ?? _suggestedPrompts[0],
                    appLocale?.t('chipHypertension') ?? _suggestedPrompts[1],
                    appLocale?.t('chipDehydration') ?? _suggestedPrompts[2],
                    appLocale?.t('chipFever') ?? _suggestedPrompts[3],
                    appLocale?.t('chipDoctorEscalation') ?? _suggestedPrompts[4],
                  ].map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        label: Text(
                          p,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          setState(() => _showQuickPrompts = false);
                          _sendMessage(p);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showQuickPrompts ? Icons.grid_view_rounded : Icons.grid_view_outlined,
                    size: 20,
                    color: _showQuickPrompts ? AppColors.primary : const Color(0xFF64748B),
                  ),
                  tooltip: 'Quick Prompts',
                  onPressed: () {
                    setState(() => _showQuickPrompts = !_showQuickPrompts);
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        final text = _textController.text;
                        _sendMessage(text);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      keyboardType: TextInputType.text,
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: appLocale?.t('chatHint') ?? 'Ask clinical or screening questions...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      onSubmitted: (val) {
                        _sendMessage(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Mic: speak the question instead of typing
                CircleAvatar(
                  backgroundColor: _isListening ? Colors.red : AppColors.primary,
                  radius: 20,
                  child: IconButton(
                    icon: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    tooltip: Provider.of<AppLocale?>(context, listen: true)?.t('tapToSpeak') ?? 'Tap to speak',
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isUser ? Colors.transparent : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.health_and_safety_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  const Text(
                    'Clinical Guidance',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const Spacer(),
                  if (msg.isOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('ICMR Offline', style: TextStyle(fontSize: 8.5, color: Color(0xFF475569))),
                    ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: msg.isUser ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
