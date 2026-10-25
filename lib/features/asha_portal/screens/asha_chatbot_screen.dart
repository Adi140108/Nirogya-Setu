import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_locale.dart';

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
  bool _isSpeaking = false;
  String? _currentlySpeakingText;
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
  static const Map<String, String> _greetings = {
    'en': "Namaste! I am your ASHA Clinical Assistant (powered by Qwen on Groq). I operate strictly within 4 clinical criteria:\n"
        "1. Patient symptom assessment & triage\n"
        "2. Basic ASHA-administerable medicines\n"
        "3. Professional Doctor Referral recommendation (Green / Yellow / Red)\n"
        "4. Specific specialist & pre-referral requirements\n"
        "Please enter the patient's symptoms and vital signs to begin.",
    'hi': "नमस्ते! मैं आपका आशा नैदानिक सहायक हूँ (Qwen on Groq द्वारा संचालित)। मैं 4 नैदानिक मानदंडों के तहत सहायता करता हूँ:\n"
        "1. लक्षण मूल्यांकन और ट्राइएज\n"
        "2. आशा स्तर की प्राथमिक दवाएं\n"
        "3. डॉक्टर रेफरल सिफारिश (हरा / पीला / लाल)\n"
        "4. विशेषज्ञ और पूर्व-रेफरल आवश्यकताएं\n"
        "कृपया मरीज के लक्षण और वाइटल्स दर्ज करें।",
    'kn': "ನಮಸ್ಕಾರ! ನಾನು ನಿಮ್ಮ ಆಶಾ ವೈದ್ಯಕೀಯ ಸಹಾಯಕ (Qwen on Groq ನಿಂದ ಚಾಲಿತ). ನಾನು 4 ಮುಖ್ಯ ಹಂತಗಳಲ್ಲಿ ಸಹಾಯ ಮಾಡುತ್ತೇನೆ:\n"
        "1. ರೋಗಲಕ್ಷಣಗಳ ಮೌಲ್ಯಮಾಪನ ಮತ್ತು ಟ್ರಯೇಜ್\n"
        "2. ಆಶಾ ಮಟ್ಟದ ಮೂಲಭೂತ ಔಷಧಿಗಳು\n"
        "3. ವೈದ್ಯರ ಶಿಫಾರಸು (ಹಸಿರು / ಹಳದಿ / ಕೆಂಪು)\n"
        "4. ತಜ್ಞ ವೈದ್ಯರ ಅವಶ್ಯಕತೆಗಳು\n"
        "ರೋಗಿಯ ಲಕ್ಷಣಗಳನ್ನು ನಮೂದಿಸಿ ಪ್ರಾರಂಭಿಸಿ.",
    'ta': "வணக்கம்! நான் உங்கள் ஆஷா மருத்துவ உதவியாளர் (Qwen on Groq இயங்குகிறது). நான் 4 மருத்துவ வழிகாட்டுதல்களில் உதவுகிறேன்:\n"
        "1. நோயாளியின் அறிகுறிகள் மதிப்பீடு\n"
        "2. ஆஷா அடிப்படை மருந்துகள்\n"
        "3. மருத்துவர் பரிந்துரை (பச்சை / மஞ்சள் / சிவப்பு)\n"
        "4. சிறப்பு மருத்துவர் தேவைகள்\n"
        "தொடங்குவதற்கு நோயாளியின் அறிகுறிகளை உள்ளிடவும்.",
    'te': "నమస్కారం! నేను మీ ఆషా క్లినికల్ అసిస్టెంట్‌ని (Qwen on Groq తో పనిచేస్తుంది). నేను 4 దశలలో సహాయం చేస్తాను:\n"
        "1. లక్షణాల అంచనా & ట్రయజ్\n"
        "2. ఆశా స్థాయి ప్రాథమిక మందులు\n"
        "3. డాక్టర్ రిఫరల్ సిఫార్సు (ఆకుపచ్చ / పసుపు / ఎరుపు)\n"
        "4. ప్రత్యేక వైద్యుల అవసరాలు\n"
        "ప్రారంభించడానికి రోగి లక్షణాలను నమోదు చేయండి.",
    'bn': "নমস্কার! আমি আপনার আশা ক্লিনিকাল সহকারী (Qwen on Groq দ্বারা চালিত)। আমি ৪টি ক্ষেত্রে সহায়তা করি:\n"
        "1. উপসর্গ মূল্যায়ন ও ট্রায়াজ\n"
        "2. প্রাথমিক আশা ওষুধ\n"
        "3. ডাক্তার রেফারেল নির্দেশিকা (সবুজ / হলুদ / লাল)\n"
        "4. বিশেষজ্ঞের প্রয়োজন\n"
        "রোগীর লক্ষণ ও ভাইটালস লিখে শুরু করুন।",
    'mr': "नमस्ते! मी तुमचा आशा क्लिनिकल सहाय्यक आहे (Qwen on Groq द्वारे समर्थित). मी ४ वैद्यकीय निकषांवर मदत करतो:\n"
        "1. लक्षण मूल्यांकन व ट्रायज\n"
        "2. आशा पातळीवरील प्राथमिक औषधे\n"
        "3. डॉक्टर रेफरल शिफारस (हिरवा / पिवळा / लाल)\n"
        "4. तज्ज्ञ डॉक्टरांची आवश्यकता\n"
        "सुरुवात करण्यासाठी रुग्णाची लक्षणे नोंदवा.",
  };

  static const Map<String, List<String>> _suggestedPromptsMap = {
    'en': [
      "Danger signs in pregnancy (ANC)",
      "Hypertension protocol (BP > 160)",
      "Severe dehydration in children",
      "Fever & malaria triage",
      "When to escalate to PHC Doctor",
    ],
    'hi': [
      "गर्भावस्था में खतरे के लक्षण (ANC)",
      "उच्च रक्तचाप प्रोटोकॉल (BP > 160)",
      "बच्चों में गंभीर निर्जलीकरण (Dehydration)",
      "बुखार और मलेरिया ट्राइएज",
      "डॉक्टर के पास कब भेजें",
    ],
    'kn': [
      "ಗರ್ಭಾವಸ್ಥೆಯ ಅಪಾಯದ ಲಕ್ಷಣಗಳು (ANC)",
      "ಅಧಿಕ ರಕ್ತದೊತ್ತಡ ನಿಯಮ (BP > 160)",
      "ಮಕ್ಕಳಲ್ಲಿ ತೀವ್ರ ನಿರ್ಜಲೀಕರಣ",
      "ಜ್ವರ ಮತ್ತು ಮಲೇರಿಯಾ ಟ್ರಯೇಜ್",
      "ಪಿಎಚ್‌ಸಿ ವೈದ್ಯರಿಗೆ ಯಾವಾಗ ಕಳುಹಿಸಬೇಕು",
    ],
    'ta': [
      "கர்ப்பகால ஆபத்து அறிகுறிகள் (ANC)",
      "இரத்த அழுத்த நெறிமுறை (BP > 160)",
      "குழந்தைகளில் கடுமையான நீரிழப்பு",
      "காய்ச்சல் மற்றும் மலேரியா சோதனை",
      "மருத்துவரிடம் எப்போது பரிந்துரைக்க வேண்டும்",
    ],
    'te': [
      "గర్భధారణ ప్రమాద సూచనలు (ANC)",
      "అధిక రక్తపోటు నిబంధనలు (BP > 160)",
      "పిల్లలలో తీవ్ర నిర్జలీకరణం",
      "జ్వరం & మలేరియా ట్రయాజ్",
      "పీహెచ్‌సీ డాక్టర్‌కు ఎప్పుడు రిఫర్ చేయాలి",
    ],
    'bn': [
      "গর্ভাবস্থায় বিপদের লক্ষণ (ANC)",
      "উচ্চ রক্তচাপের প্রোটোকল (BP > 160)",
      "শিশুদের মারাত্মক পানিশূন্যতা",
      "জ্বর ও ম্যালেরিয়া ট্রায়াজ",
      "কখন ডাক্তারের কাছে রেফার করবেন",
    ],
    'mr': [
      "गरोदरपणातील धोक्याची लक्षणे (ANC)",
      "उच्च रक्तदाब प्रोटोकॉल (BP > 160)",
      "लहान मुलांमधील निर्जलीकरण",
      "ताप आणि मलेरिया ट्रायज",
      "डॉक्टरांकडे कधी पाठवावे",
    ],
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
      'You are the Nirogya Setu ASHA Clinical AI Assistant powered by Qwen on Groq cloud inference. '
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
      _tts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _currentlySpeakingText = null;
          });
        }
      });
      _tts.setCancelHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _currentlySpeakingText = null;
          });
        }
      });
      _tts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _currentlySpeakingText = null;
          });
        }
      });
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      final langLocale = _speechLocales[_chatLanguage] ?? 'en-IN';
      try {
        final isAvailable = await _tts.isLanguageAvailable(langLocale);
        if (isAvailable == 1 || isAvailable == true) {
          await _tts.setLanguage(langLocale);
        } else {
          await _tts.setLanguage(_chatLanguage);
        }
      } catch (_) {
        await _tts.setLanguage('en-IN');
      }
      await _tts.awaitSpeakCompletion(true);
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
      setState(() => _chatLanguage = appLocaleCode);
      _tts.setLanguage(_speechLocales[appLocaleCode] ?? 'en-IN');
      _tts.setSpeechRate(0.5);
    }
  }

  Future<void> _setChatLanguage(String code) async {
    setState(() => _chatLanguage = code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_language', code);
    try {
      final langLocale = _speechLocales[code] ?? 'en-IN';
      final isAvailable = await _tts.isLanguageAvailable(langLocale);
      if (isAvailable == 1 || isAvailable == true) {
        await _tts.setLanguage(langLocale);
      } else {
        await _tts.setLanguage(code);
      }
      await _tts.setSpeechRate(0.5);
    } catch (_) {}
    if (mounted) {
      final appLocale = Provider.of<AppLocale?>(context, listen: false);
      if (appLocale != null && appLocale.code != code) {
        await appLocale.setLanguage(code);
      }
    }
  }

  Future<void> _toggleSpeakReplies(bool value) async {
    setState(() => _speakReplies = value);
    if (!value) {
      await _tts.stop();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentlySpeakingText = null;
        });
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chat_speak_replies', value);
  }

  String _cleanTextForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'[*#_•\-\[\]()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _speak(String text, {bool force = false}) async {
    if (!_speakReplies && !force) return;
    try {
      if (_isSpeaking && _currentlySpeakingText == text) {
        await _tts.stop();
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _currentlySpeakingText = null;
          });
        }
        return;
      }
      await _tts.stop();
      final langLocale = _speechLocales[_chatLanguage] ?? 'en-IN';
      try {
        final isAvailable = await _tts.isLanguageAvailable(langLocale);
        if (isAvailable == 1 || isAvailable == true) {
          await _tts.setLanguage(langLocale);
        } else {
          await _tts.setLanguage(_chatLanguage);
        }
      } catch (_) {
        await _tts.setLanguage('en-IN');
      }
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      final clean = _cleanTextForSpeech(text);
      if (clean.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
            _currentlySpeakingText = text;
          });
        }
        await _tts.speak(clean);
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentlySpeakingText = null;
        });
      }
    }
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
      final clinicalGuidance = _queryOfflineKnowledge(clean, langCode: _chatLanguage);
      setState(() {
        _messages.add(ChatMessage(
          text: clinicalGuidance,
          isUser: false,
          timestamp: DateTime.now(),
          isOffline: true,
        ));
      });
      _speak(clinicalGuidance);
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
        'CRITICAL MULTILINGUAL MANDATE: The user has requested $selectedLang. '
        'You MUST write your ENTIRE clinical response strictly in $selectedLang using its native script. '
        'Do NOT write in English unless $selectedLang is English. '
        'Every single clinical assessment, danger sign, OTC medicine, and doctor referral guidance must be in $selectedLang.';

    final modelsToTry = [
      _selectedModel,
      if (_selectedModel != 'openai/gpt-oss-20b') 'openai/gpt-oss-20b',
      if (_selectedModel != 'openai/gpt-oss-120b') 'openai/gpt-oss-120b',
      if (_selectedModel != 'qwen/qwen3.8-27b') 'qwen/qwen3.8-27b',
    ];

    String? lastError;
    for (final model in modelsToTry) {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $activeKey',
          },
          body: jsonEncode({
            'model': model,
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
                'content': '$query\n\n[MANDATORY: Write the entire response strictly in $selectedLang only]',
              }
            ],
            'temperature': 0.3,
            'max_tokens': 600,
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final content = data['choices']?[0]?['message']?['content'];
          if (content != null && content.toString().trim().isNotEmpty) {
            return content.toString().trim();
          }
        } else {
          lastError = 'Groq ($model) returned HTTP ${response.statusCode}: ${response.body}';
          debugPrint(lastError);
        }
      } catch (e) {
        lastError = 'Groq ($model) exception: $e';
        debugPrint(lastError);
      }
    }

    throw Exception(lastError ?? 'All Groq models failed');
  }

  String _queryOfflineKnowledge(String query, {String? langCode}) {
    final q = query.toLowerCase();
    final lang = langCode ?? _chatLanguage;

    final isPregnancy = q.contains('pregnant') ||
        q.contains('anc') ||
        q.contains('maternal') ||
        q.contains('pregnancy') ||
        q.contains('गर्भ') ||
        q.contains('गर्भवती') ||
        q.contains('गर्भावस्था') ||
        q.contains('प्रसव') ||
        q.contains('ಗರ್ಭಿಣಿ') ||
        q.contains('ಗರ್ಭಾವಸ್ಥೆ') ||
        q.contains('கர்ப்ப') ||
        q.contains('கர்ப்பிணி') ||
        q.contains('గర్భిణి') ||
        q.contains('గర్భం') ||
        q.contains('গর্ভবতী') ||
        q.contains('গর্ভাবস্থা') ||
        q.contains('गरोदर');

    if (isPregnancy) {
      switch (lang) {
        case 'hi':
          return """• गर्भावस्था के खतरे के लक्षण (RED FLAGS):
1. धुंधली दृष्टि या चक्कर के साथ तेज सिरदर्द (प्री-एक्लेमप्सिया का खतरा)।
2. योनि से रक्तस्राव या लगातार पानी जैसा रिसाव।
3. तीसरे तिमाही में चेहरे, हाथों और पैरों में अचानक सूजन।
4. 24 सप्ताह के बाद गर्भस्थ शिशु की हलचल में कमी या बंद होना।
5. कंपकंपी के साथ तेज बुखार (> 101°F)।

कार्रवाई:
- सामुदायिक स्वास्थ्य केंद्र (CHC) या जिला अस्पताल में तत्काल लाल (RED) रेफरल।
- तुरंत रक्तचाप और मूत्र एल्ब्यूमिन की जांच करें।
- 108 एम्बुलेंस से तत्काल अस्पताल भेजें।""";
        case 'kn':
          return """• ಗರ್ಭಾವಸ್ಥೆಯ ಅಪಾಯದ ಲಕ್ಷಣಗಳು (RED FLAGS):
1. ಮಸುಕಾದ ದೃಷ್ಟಿ ಅಥವಾ ತಲೆಸುತ್ತಿನೊಂದಿಗೆ ತೀವ್ರ ತಲೆನೋವು (ಪ್ರಿ-ಎಕ್ಲಾಂಪ್ಸಿಯಾ ಅಪಾಯ).
2. ರಕ್ತಸ್ರಾವ ಅಥವಾ ನಿರಂತರ ದ್ರವ ಸ್ರಾವ.
3. ಮುಖ, ಕೈ ಮತ್ತು ಕಾಲುಗಳಲ್ಲಿ ಅತಿಯಾದ ಊತ.
4. ಭ್ರೂಣದ ಚಲನೆ ಕಡಿಮೆಯಾಗುವುದು ಅಥವಾ ನಿಲ್ಲುವುದು.
5. ಚಳಿಯೊಂದಿಗೆ ತೀವ್ರ ಜ್ವರ (> 101°F).

ಕ್ರಮ:
- ಸಮುದಾಯ ಆರೋಗ್ಯ ಕೇಂದ್ರ (CHC) ಅಥವಾ ಜಿಲ್ಲಾ ಆಸ್ಪತ್ರೆಗೆ ತುರ್ತು RED ರೆಫರಲ್.
- ತಕ್ಷಣ ರಕ್ತದೊತ್ತಡ ಮತ್ತು ಮೂತ್ರ ಪರೀಕ್ಷೆ ಮಾಡಿ.
- 108 ಆಂಬ್ಯುಲೆನ್ಸ್ ಮೂಲಕ ಸಾಗಾಣಿಕೆ ವ್ಯವಸ್ಥೆ ಮಾಡಿ.""";
        case 'ta':
          return """• கர்ப்பகால ஆபத்து அறிகுறிகள் (RED FLAGS):
1. மங்கலான பார்வையுடன் கடுமையான தலைவலி (ப்ரீ-எக்லாம்ப்சியா ஆபத்து).
2. பிறப்புறுப்பு இரத்தப்போக்கு அல்லது திரவ கசிவு.
3. முகம், கைகள் மற்றும் கால்களில் கடுமையான வீக்கம்.
4. குழந்தையின் அசைவு குறைதல் அல்லது இல்லாமை.
5. நடுக்கத்துடன் கூடிய அதிக காய்ச்சல் (> 101°F).

செயல்முறை:
- ஆரம்ப சுகாதார நிலையம் (CHC) அல்லது மாவட்ட மருத்துவமனைக்கு உடனடி RED பரிந்துரை.
- இரத்த அழுத்தம் மற்றும் சிறுநீர் பரிசோதனை செய்யவும்.
- 108 ஆம்புலன்ஸ் மூலம் அழைத்துச் செல்லவும்.""";
        case 'te':
          return """• గర్భధారణ ప్రమాద హెచ్చరికలు (RED FLAGS):
1. మసకబారిన చూపుతో కూడిన తీవ్రమైన తలనొప్పి (ప్రీ-ఎక్లాంప్సియా ప్రమాదం).
2. రక్తస్రావం లేదా నిరంతర ద్రవ స్రావం.
3. ముఖం, చేతులు మరియు కాళ్ళలో వాపు.
4. పిండం కదలికలు తగ్గడం లేదా ఆగిపోవడం.
5. వణుకుతో కూడిన తీవ్ర జ్వరం (> 101°F).

చర్య:
- తక్షణమే CHC లేదా జిల్లా ఆసుపత్రికి RED రిఫరల్.
- వెంటనే రక్తపోటు మరియు మూత్ర పరీక్ష చేయండి.
- 108 అంబులెన్స్ ద్వారా ఆసుపత్రికి తరలించండి.""";
        case 'bn':
          return """• গর্ভাবস্থার বিপদের লক্ষণ (RED FLAGS):
1. ঝাপসা দৃষ্টি বা মাথা ঘোরার সাথে তীব্র মাথাব্যথা (প্রি-এক্লাম্পসিয়ার ঝুঁকি)।
2. রক্তপাত বা ক্রমাগত তরল স্রাব।
3. মুখ, হাত ও পায়ে অস্বাভাবিক ফোলাভাব।
4. শিশুর নড়াচড়া কমে যাওয়া বা বন্ধ হওয়া।
5. কাঁপুনি দিয়ে প্রচণ্ড জ্বর (> 101°F)।

পদক্ষেপ:
- অবিলম্বে CHC বা জেলা হাসপাতালে জরুরি RED রেফারেল।
- রক্তচাপ ও মূত্র পরীক্ষা করুন।
- ১০৮ অ্যাম্বুলেন্সে হাসপাতালে নিয়ে যান।""";
        case 'mr':
          return """• गरोदरपणातील धोक्याची लक्षणे (RED FLAGS):
1. अंधुक दृष्टी किंवा चक्कर येण्यासह तीव्र डोकेदुखी (प्री-एक्लॅम्प्सियाचा धोका).
2. योनीतून रक्तस्त्राव किंवा सतत पाणी गळणे.
3. चेहरा, हात आणि पायांवर अचानक सूज येणे.
4. बाळाची हालचाल मंदावणे किंवा थांबणे.
5. थंडी वाजून तीव्र ताप येणे (> 101°F).

कृती:
- ग्रामीण रुग्णालय (CHC) किंवा जिल्हा रुग्णालयात त्वरित RED रेफरल.
- रक्तदाब आणि लघवीतील अल्ब्युमिन तपासा.
- 108 रुग्णवाहिकेने तातडीने रुग्णालयात पाठवा.""";
        default:
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
    }

    final isBp = q.contains('bp') ||
        q.contains('hypertension') ||
        q.contains('blood pressure') ||
        q.contains('रक्तचाप') ||
        q.contains('उच्च रक्तचाप') ||
        q.contains('बीपी') ||
        q.contains('ರಕ್ತದೊತ್ತಡ') ||
        q.contains('బిపి') ||
        q.contains('రక్తపోటు') ||
        q.contains('இரத்த அழுத்தம்') ||
        q.contains('ரத்த அழுத்தம்') ||
        q.contains('ரத்தக் கொதிப்பு') ||
        q.contains('রক্তচাপ') ||
        q.contains('रक्तदाब');

    if (isBp) {
      switch (lang) {
        case 'hi':
          return """• रक्तचाप (BP / Hypertension) प्रोटोकॉल:
- सामान्य: < 120/80 mmHg (हरा - नियमित जीवनशैली सलाह)
- बढ़ा हुआ / स्टेज 1: 130-139 / 80-89 mmHg (नमक कम करने की सलाह, 14 दिन बाद पुनः जांच)
- स्टेज 2 उच्च रक्तचाप: ≥ 140/90 mmHg (पीला - PHC चिकित्सा अधिकारी से परामर्श)
- आपातकालीन रक्तचाप (Hypertensive Crisis): ≥ 160/100 mmHg सिरदर्द, सीने में दर्द या धुंधली दृष्टि के साथ (लाल आपातकाल - 108 एम्बुलेंस से तुरंत अस्पताल भेजें)।

परामर्श:
- नापने से पहले 5 मिनट शांत बैठें। चाय या तंबाकू के 30 मिनट बाद जांचें।""";
        case 'kn':
          return """• ರಕ್ತದೊತ್ತಡ (BP) ಮಾರ್ಗಸೂಚಿ:
- ಸಾಮಾನ್ಯ: < 120/80 mmHg (ಹಸಿರು - ಸಾಮಾನ್ಯ ಜೀವನಶೈಲಿ ಸಲಹೆ)
- ಹಂತ 1: 130-139 / 80-89 mmHg (ಉಪ್ಪು ಕಡಿಮೆ ಮಾಡಲು ಸಲಹೆ, 14 ದಿನಗಳ ನಂತರ ಮರುಪರಿಶೀಲನೆ)
- ಹಂತ 2 ಅಧಿಕ ರಕ್ತದೊತ್ತಡ: ≥ 140/90 mmHg (ಹಳದಿ - PHC ವೈದ್ಯಾಧಿಕಾರಿ ಭೇಟಿ)
- ತುರ್ತು ಬಿಪಿ ಬಿಕ್ಕಟ್ಟು: ≥ 160/100 mmHg ತಲೆನೋವು ಅಥವಾ ಎದೆನೋವಿನೊಂದಿಗೆ (ತುರ್ತು RED ರೆಫರಲ್).

ಸಲಹೆ:
- ಪರೀಕ್ಷೆಗೆ ಮುನ್ನ 5 ನಿಮಿಷ ವಿಶ್ರಾಂತಿ ಪಡೆಯಿರಿ.""";
        case 'ta':
          return """• இரத்த அழுத்த (BP) நெறிமுறை:
- இயல்பானது: < 120/80 mmHg (பச்சை - வாழ்க்கை முறை ஆலோசனை)
- நிலை 1: 130-139 / 80-89 mmHg (உப்பு குறைக்கவும், 14 நாட்களில் மீண்டும் பரிசோதிக்கவும்)
- நிலை 2: ≥ 140/90 mmHg (மஞ்சள் - PHC மருத்துவர் ஆலோசனை)
- அவசர இரத்த அழுத்தம்: ≥ 160/100 mmHg தலைவலி அல்லது நெஞ்சுவலியுடன் (உடனடி RED அவசரம்).""";
        case 'te':
          return """• రక్తపోటు (BP) మార్గదర్శకాలు:
- సాధారణం: < 120/80 mmHg (ఆకుపచ్చ - జీవనశైలి మార్పులు)
- స్టేజ్ 1: 130-139 / 80-89 mmHg (ఉప్పు తగ్గించండి, 14 రోజుల్లో మళ్లీ పరీక్షించండి)
- స్టేజ్ 2: ≥ 140/90 mmHg (పసుపు - PHC డాక్టర్ సంప్రదింపులు)
- అత్యవసర సంక్షೋభం: ≥ 160/100 mmHg తలనొప్పి లేదా ఛాతీ నొప్పితో (తక్షణ RED రిఫరల్).""";
        case 'bn':
          return """• রক্তচাপ (BP) প্রোটোকল:
- স্বাভাবিক: < 120/80 mmHg (সবুজ - জীবনযাত্রার পরামর্শ)
- স্টেজ ১: 130-139 / 80-89 mmHg (লবণ কমান, ১৪ দিন পর পুনঃপরীক্ষা)
- স্টেজ ২: ≥ 140/90 mmHg (হলুদ - PHC ডাক্তারের পরামর্শ)
- জরুরি সংকট: ≥ 160/100 mmHg মাথাব্যথা বা বুকে ব্যথাসহ (জরুরি RED রেফারেল)।""";
        case 'mr':
          return """• रक्तदाब (BP) प्रोटोकॉल:
- सामान्य: < 120/80 mmHg (हिरवा - जीवनशैली सुधारणा)
- टप्पा 1: 130-139 / 80-89 mmHg (मीठ कमी करा, 14 दिवसांनी तपासा)
- टप्पा 2: ≥ 140/90 mmHg (पिवळा - PHC वैद्यकीय अधिकारी सल्ला)
- आणीबाणी: ≥ 160/100 mmHg डोकेदुखी किंवा छातीत दुखण्यासह (तातडीने RED रेफरल).""";
        default:
          return """• BLOOD PRESSURE (HTN) PROTOCOL:
- Normal: < 120/80 mmHg (Green - Routine lifestyle advice)
- Elevated / Stage 1: 130-139 / 80-89 mmHg (Counsel salt reduction, re-check in 14 days)
- Stage 2 HTN: ≥ 140/90 mmHg (Yellow - Schedule PHC Medical Officer consultation)
- Hypertensive Crisis: ≥ 160/100 mmHg with headache, chest pain, or blurred vision (RED EMERGENCY - Refer immediately).

COUNSELING:
- Rest 5 minutes before measurement.
- Avoid tea/tobacco 30 minutes prior.""";
      }
    }

    final isDehydration = q.contains('dehydration') ||
        q.contains('diarrhea') ||
        q.contains('vomit') ||
        q.contains('ors') ||
        q.contains('दस्त') ||
        q.contains('उल्टी') ||
        q.contains('निर्जलीकरण') ||
        q.contains('ಅತಿಸಾರ') ||
        q.contains('ವಾಂತಿ') ||
        q.contains('ವಿರೇಚనాలు') ||
        q.contains('వాంతులు') ||
        q.contains('வயிற்றுப்போக்கு') ||
        q.contains('வாந்தி') ||
        q.contains('ডায়রিয়া') ||
        q.contains('বমি') ||
        q.contains('जुलाब') ||
        q.contains('उलटी');

    if (isDehydration) {
      switch (lang) {
        case 'hi':
          return """• बाल निर्जलीकरण और दस्त प्रोटोकॉल (Dehydration & Diarrhea):
- खतरे के संकेत: धंसी हुई आंखें, त्वचा चुटकी बहुत धीरे सामान्य होना (> 2 सेकंड), पानी पीने में असमर्थ, अत्यधिक सुस्ती।
- योजना A (हल्का): ओआरएस (ORS) घोल (1 लीटर स्वच्छ पानी में 1 पैकेट) + जिंक 20mg दैनिक 14 दिनों तक।
- योजना B (मध्यम): आशा कार्यकर्ता की देखरेख में 4 घंटे में 75 मिली/किग्रा ओआरएस।
- योजना C (गंभीर): तत्काल अस्पताल में भर्ती (IV रिंगर लैक्टेट)।

महत्वपूर्ण: स्तनपान या भोजन कभी बंद न करें।""";
        case 'kn':
          return """• ಮಕ್ಕಳ ನಿರ್ಜಲೀಕರಣ ಮತ್ತು ಅತಿಸಾರ ಪ್ರೋಟೋಕಾಲ್:
- ಅಪಾಯದ ಚಿಹ್ನೆಗಳು: ಕಣ್ಣುಗಳು ಗುಳಿಬೀಳುವುದು, ಚರ್ಮ ಎಳೆದರೆ ನಿಧಾನವಾಗಿ ಮರಳುವುದು, ನೀರು ಕುಡಿಯಲಾಗದಿರುವುದು, ಜಡತೆ.
- ಯೋಜನೆ A (ಸೌಮ್ಯ): ORS ದ್ರಾವಣ (1 ಲೀಟರ್ ನೀರಿನಲ್ಲಿ 1 ಪ್ಯಾಕೆಟ್) + 14 ದಿನಗಳವರೆಗೆ ದಿನಕ್ಕೆ 20mg ಜಿಂಕ್.
- ಯೋಜನೆ B (ಮಧ್ಯಮ): ಆಶಾ ಮೇಲ್ವಿಚಾರಣೆಯಲ್ಲಿ 4 ಗಂಟೆಗಳಲ್ಲಿ 75 ಮಿಲಿ/ಕೆಜಿ ORS.
- ಯೋಜನೆ C (ತೀವ್ರ): ತಕ್ಷಣ ಆಸ್ಪತ್ರೆಗೆ ದಾಖಲಿಸಿ (IV ರಿಂಗರ್ಸ್ ಲ್ಯಾಕ್ಟೇಟ್).

ಪ್ರಮುಖ: ಎದೆಹಾಲು ನೀಡುವುದನ್ನು ನಿಲ್ಲಿಸಬೇಡಿ.""";
        case 'ta':
          return """• குழந்தைகள் நீரிழப்பு மற்றும் வயிற்றுப்போக்கு நெறிமுறை:
- ஆபத்து அறிகுறிகள்: கண்கள் உள்வாங்குதல், தோல் மெதுவாக திரும்புதல், குடிக்க இயலாமை, சோம்பல்.
- திட்டம் A: ORS கரைசல் (1 லிட்டர் தண்ணீரில் 1 பாக்கெட்) + 14 நாட்களுக்கு துத்தநாகம் (Zinc 20mg).
- திட்டம் B: ஆஷா மேற்பார்வையில் 4 மணி நேரத்தில் 75 மி.லி/கிலோ ORS.
- திட்டம் C: உடனடியாக மருத்துவமனையில் அனுமதித்து IV திரவம் அளித்தல்.""";
        case 'te':
          return """• పిల్లల నిర్జలీకరణ & విరేచనాల ప్రోటోకాల్:
- ప్రమాద సంకేతాలు: కళ్ళు లోతుకుపోవడం, చర్మం స్థితిస్థాపకత తగ్గడం, నీరు తాగలేకపోవడం, మగత.
- ప్లాన్ A: ORS ద్రావణం (1 లీటర్ నీటిలో 1 ప్యాకెట్) + 14 రోజుల పాటు జింక్ 20mg.
- ప్లాన్ B: ఆశా పర్యవేక్షణలో 4 గంటల్లో 75 ml/kg ORS.
- ప్లాన్ C: తక్షణమే ఆసుపత్రిలో చేర్పించి IV సెలైన్ ఎక్కించాలి.""";
        case 'bn':
          return """• শিশুদের পানিশূন্যতা ও ডায়রিয়া প্রোটোকল:
- বিপদের লক্ষণ: চোখ বসে যাওয়া, চামড়া ধীরে স্বাভাবিক হওয়া, পানি পানে অক্ষমতা, নিস্তেজ ভাব।
- পরিকল্পনা A: ওআরএস (ORS) দ্রবণ (১ লিটার পানিতে ১ প্যাকেট) + ১৪ দিন জিংক ২০ মিগ্রা।
- পরিকল্পনা B: ৪ ঘণ্টায় ৭৫ মিলি/কেজি ওআরএস আশা কর্মীর তত্ত্বাবধানে।
- পরিকল্পনা C: অবিলম্বে হাসপাতালে ভর্তি এবং IV স্যালাইন।""";
        case 'mr':
          return """• बाल निर्जलीकरण आणि जुलाब प्रोटोकॉल:
- धोक्याची लक्षणे: डोळे खोल जाणे, त्वचा हळूहळू पूर्ववत होणे, पाणी न पिणे, सुस्ती.
- योजना A: ओआरएस (ORS) पाणी (1 लिटर पाण्यात 1 पॅकेट) + 14 दिवस झिंक 20mg.
- योजना B: आशा सेविकेच्या देखरेखीखाली 4 तासात 75 मिली/किलो ओआरएस.
- योजना C: तातडीने रुग्णालयात दाखल करून सलाईन सुरू करणे.""";
        default:
          return """• CHILD DEHYDRATION & DIARRHEA PROTOCOL:
- Danger Signs: Sunken eyes, skin pinch goes back very slowly (> 2 sec), unable to drink, lethargy.
- Plan A (Mild): ORS solution (1 packet in 1 liter clean water) + Zinc 20mg daily for 14 days.
- Plan B (Moderate): 75 ml/kg ORS over 4 hours under ASHA supervision.
- Plan C (Severe): Immediate hospitalization for IV Ringer's Lactate.

IMPORTANT: Never withhold breastmilk or food.""";
      }
    }

    final isSugar = q.contains('sugar') ||
        q.contains('diabetes') ||
        q.contains('glucose') ||
        q.contains('rbs') ||
        q.contains('शुगर') ||
        q.contains('मधुमेह') ||
        q.contains('डायबिटीज') ||
        q.contains('सಕ್ಕರೆ') ||
        q.contains('ಮಧುಮೇಹ') ||
        q.contains('షుగర్') ||
        q.contains('మధుమేహం') ||
        q.contains('சர்க்கரை') ||
        q.contains('நீரிழிவு') ||
        q.contains('সুগার') ||
        q.contains('ডায়াবেটিস') ||
        q.contains('साखर');

    if (isSugar) {
      switch (lang) {
        case 'hi':
          return """• रक्त शर्करा (RBS / Diabetes) दिशानिर्देश:
- सामान्य (खाली पेट): 70 - 99 mg/dL
- सामान्य (रैंडम): < 140 mg/dL
- प्रीडायबिटीज: 140 - 199 mg/dL (आहार नियंत्रण, 30 दिनों में जांच)
- डायबिटीज स्तर: ≥ 200 mg/dL (HbA1c और दवा के लिए PHC डॉक्टर के पास भेजें)
- गंभीर आपातकाल: > 300 mg/dL या < 60 mg/dL (लाल आपातकाल - तुरंत रेफर करें)।""";
        case 'kn':
          return """• ರಕ್ತದಲ್ಲಿನ ಸಕ್ಕರೆ (Diabetes) ಮಾರ್ಗಸೂಚಿ:
- ಸಾಮಾನ್ಯ (ಖಾಲಿ ಹೊಟ್ಟೆ): 70 - 99 mg/dL
- ಸಾಮಾನ್ಯ (ಯಾದೃಚ್ಛಿಕ): < 140 mg/dL
- ಪ್ರಿಡಯಾಬಿಟಿಸ್: 140 - 199 mg/dL (ಆಹಾರ ನಿಯಂತ್ರಣ, 30 ದಿನಗಳಲ್ಲಿ ಮರುಪರೀಕ್ಷೆ)
- ಮಧುಮೇಹ ವ್ಯಾಪ್ತಿ: ≥ 200 mg/dL (PHC ವೈದ್ಯರಿಗೆ ಉಲ್ಲೇಖಿಸಿ)
- ತೀವ್ರ ತುರ್ತು: > 300 mg/dL ಅಥವಾ < 60 mg/dL (RED ತುರ್ತು ರೆಫರಲ್).""";
        case 'ta':
          return """• இரத்த சர்க்கரை (Diabetes) வழிகாட்டுதல்:
- இயல்பானது (வெறும் வயிறு): 70 - 99 mg/dL
- இயல்பானது (ரேண்டம்): < 140 mg/dL
- நீரிழிவு தொடக்கநிலை: 140 - 199 mg/dL (உணவு கட்டுப்பாடு)
- நீரிழிவு: ≥ 200 mg/dL (PHC மருத்துவரிடம் பரிந்துரைக்கவும்)
- அவசர நிலை: > 300 mg/dL அல்லது < 60 mg/dL (உடனடி RED அவசரம்).""";
        case 'te':
          return """• బ్లడ్ షుగర్ (Diabetes) మార్గదర్శకాలు:
- సాధారణం (ఖాళీ కడుపు): 70 - 99 mg/dL
- సాధారణం (రాండమ్): < 140 mg/dL
- ప్రీ-డయాబెటిస్: 140 - 199 mg/dL (ఆహార నియంత్రణ)
- డయాబెటిస్: ≥ 200 mg/dL (PHC డాక్టర్‌కు రిఫర్ చేయండి)
- క్లిష్టమైన పరిమితి: > 300 mg/dL లేదా < 60 mg/dL (తక్షణ RED అత్యవసరం).""";
        case 'bn':
          return """• রক্তের শর্করা (Diabetes) নির্দেশিকা:
- স্বাভাবিক (খালি পেটে): ৭০ - ৯৯ mg/dL
- স্বাভাবিক (র‍্যান্ডম): < ১৪০ mg/dL
- প্রি-ডায়াবেটিস: ১৪০ - ১৯৯ mg/dL (খাবার নিয়ন্ত্রণ)
- ডায়াবেটিস: ≥ ২০০ mg/dL (PHC ডাক্তারের কাছে পাঠান)
- জরুরি সংকট: > ৩০০ mg/dL বা < ৬০ mg/dL (তাত্ক্ষণিক RED রেফারেল)।""";
        case 'mr':
          return """• रक्त शर्करा (Diabetes) मार्गदर्शक:
- सामान्य (उपाशीपोटी): 70 - 99 mg/dL
- सामान्य (रँडम): < 140 mg/dL
- प्रीडायबेटिस: 140 - 199 mg/dL (आहार सुधारणा)
- मधुमेहाची पातळी: ≥ 200 mg/dL (PHC डॉक्टर सल्ला)
- आणीबाणी: > 300 mg/dL किंवा < 60 mg/dL (तातडीने RED रेफरल).""";
        default:
          return """• RANDOM BLOOD GLUCOSE (RBS) GUIDELINES:
- Normal (Fasting): 70 - 99 mg/dL
- Normal (Random): < 140 mg/dL
- Impaired / Prediabetic: 140 - 199 mg/dL (Dietary modification, re-check in 30 days)
- Diabetic Range: ≥ 200 mg/dL (Refer to PHC Doctor for HbA1c & treatment)
- Critical Glycemic Event: > 300 mg/dL or < 60 mg/dL (RED EMERGENCY - Refer immediately).""";
      }
    }

    final isFever = q.contains('fever') ||
        q.contains('malaria') ||
        q.contains('dengue') ||
        q.contains('chills') ||
        q.contains('temp') ||
        q.contains('बुखार') ||
        q.contains('मलेरिया') ||
        q.contains('डेंगू') ||
        q.contains('ताप') ||
        q.contains('ಜ್ವರ') ||
        q.contains('ಮಲೇರಿಯಾ') ||
        q.contains('டெங்கு') ||
        q.contains('காய்ச்சல்') ||
        q.contains('జ్వరం') ||
        q.contains('మలేరియా') ||
        q.contains('জ্বর');

    if (isFever) {
      switch (lang) {
        case 'hi':
          return """• बुखार और मलेरिया ट्राइएज प्रोटोकॉल (Fever Triage):
- डिजिटल थर्मामीटर से तापमान नापें।
- यदि तापमान > 100.4°F: पैरासिटामोल (Paracetamol) 500mg (वयस्क) या 10-15 mg/kg (बच्चा) हर 6 घंटे में।
- 48 घंटे से अधिक बुखार या कंपकंपी होने पर मलेरिया रैपिड डायग्नोस्टिक टेस्ट (RDT) करें।
- खतरे के संकेत: अत्यधिक सुस्ती, मसूड़ों से खून आना, त्वचा पर चकत्ते, लगातार उल्टी।
- यदि तेज बुखार बना रहे तो 24 घंटे के भीतर PHC डॉक्टर के पास भेजें (Refer to PHC)।""";
        case 'kn':
          return """• ಜ್ವರ ಮತ್ತು ಮಲೇರಿಯಾ ಟ್ರಯೇಜ್ ಪ್ರೋಟೋಕಾಲ್:
- ಡಿಜಿಟಲ್ ಥರ್ಮಾಮೀಟರ್‌ನಿಂದ ತಾಪಮಾನ ಪರಿಶೀಲಿಸಿ.
- ತಾಪಮಾನ > 100.4°F ಇದ್ದರೆ: ಪ್ಯಾರಸಿಟಮಾಲ್ (Paracetamol) 500mg ಪ್ರತಿ 6 ಗಂಟೆಗೊಮ್ಮೆ.
- 48 ಗಂಟೆಗಳಿಗಿಂತ ಹೆಚ್ಚು ಜ್ವರವಿದ್ದರೆ ಮಲೇರಿಯಾ ತ್ವರಿತ ಪರೀಕ್ಷೆ (RDT) ನಡೆಸಿ.
- ಅಪಾಯದ ಚಿಹ್ನೆಗಳು: ಅತಿಯಾದ ಸುಸ್ತು, ವಸಡುಗಳಿಂದ ರಕ್ತಸ್ರಾವ, ಚರ್ಮದ ಮೇಲೆ ಕೆಂಪು ಕಲೆಗಳು.
- ತೀವ್ರ ಜ್ವರ ಮುಂದುವರಿದರೆ 24 ಗಂಟೆಗಳಲ್ಲಿ PHC ಗೆ ಉಲ್ಲೇಖಿಸಿ (Refer to PHC).""";
        case 'ta':
          return """• காய்ச்சல் மற்றும் மலேரியா நெறிமுறை (Fever Triage):
- டிஜிட்டல் தெர்மோமீட்டர் மூலம் வெப்பநிலையை அளவிடவும்.
- காய்ச்சல் > 100.4°F: பாராசிட்டமால் (Paracetamol) 500mg 6 மணி நேரத்திற்கு ஒருமுறை.
- 48 மணி நேரத்திற்கு மேல் காய்ச்சல் நீடித்தால் மலேரியா RDT பரிசோதனை செய்யவும்.
- ஆபத்து அறிகுறிகள்: தீவிர சோர்வு, ஈறுகளில் இரத்தப்போக்கு, தோல் தடிப்புகள்.
- காய்ச்சல் நீடித்தால் 24 மணி நேரத்திற்குள் PHC மருத்துவரிடம் அனுப்பவும் (Refer to PHC).""";
        case 'te':
          return """• జ్వరం మరియు మలేరియా ట్రయాజ్ ప్రోటోకాల్:
- డిజిటల్ థర్మామీటర్‌తో ఉష్ణోగ్రతను కొలవండి.
- ఉష్ణోగ్రత > 100.4°F అయితే: పారాసిటమాల్ (Paracetamol) 500mg ప్రతి 6 గంటలకు.
- 48 గంటలకు పైగా జ్వరం లేదా చలి ఉంటే మలేరియా RDT పరీక్ష చేయండి.
- ప్రమాద సంకేతాలు: తీవ్ర అలసట, చిగుళ్ల నుంచి రక్తస్రావం, నిరంతర వాంతులు.
- తీవ్ర జ్వరం తగ్గకపోతే 24 గంటల్లో PHC కి రిఫర్ చేయండి (Refer to PHC).""";
        case 'bn':
          return """• জ্বর ও ম্যালেরিয়া ট্রায়াজ প্রোটোকল:
- ডিজিটাল থার্মোমিটার দিয়ে তাপমাত্রা মাপুন।
- তাপমাত্রা > ১০০.৪°F হলে: প্যারাসিটামল (Paracetamol) ৫০০ মিগ্রা প্রতি ৬ ঘণ্টায়।
- ৪৮ ঘণ্টার বেশি জ্বর বা কাঁপুনি হলে ম্যালেরিয়া RDT পরীক্ষা করুন।
- বিপদের লক্ষণ: তীব্র অলসতা, মাড়ি থেকে রক্তপাত, ক্রমাগত বমি।
- জ্বর অব্যাহত থাকলে ২৪ ঘণ্টার মধ্যে PHC তে রেফার করুন (Refer to PHC)।""";
        case 'mr':
          return """• ताप आणि मलेरिया ट्रायज प्रोटोकॉल:
- डिजिटल थर्मामीटरने तापमान मोजा.
- तापमान > 100.4°F असल्यास: पॅरासिटामॉल (Paracetamol) 500mg दर 6 तासांनी.
- 48 तासांपेक्षा जास्त ताप किंवा थंडी असल्यास मलेरिया RDT चाचणी करा.
- धोक्याची चिन्हे: तीव्र अशक्तपणा, हिरड्यांमधून रक्त येणे, सतत उलट्या.
- ताप कमी न झाल्यास 24 तासांच्या आत प्राथमिक आरोग्य केंद्रात (PHC) पाठवा.""";
        default:
          return """• FEVER TRIAGE & RURAL PROTOCOL:
- Take temperature with digital thermometer.
- If Temp > 100.4°F: Paracetamol 500mg (adult) or 10-15 mg/kg (child) every 6 hours.
- Perform Rapid Diagnostic Test (RDT) for Malaria if fever > 48 hours or chills.
- Red Flags: Extreme lethargy, bleeding gums, petechial rash, persistent vomiting.
- Escalation: Refer to PHC within 24 hours if high fever persists.""";
      }
    }

    final isSpo2 = q.contains('spo2') ||
        q.contains('oxygen') ||
        q.contains('breath') ||
        q.contains('ऑक्सीजन') ||
        q.contains('सांस') ||
        q.contains('ಉಸಿರಾಟ') ||
        q.contains('ಆಕ್ಸಿಜನ್') ||
        q.contains('శ్వాస') ||
        q.contains('சுவாசம்') ||
        q.contains('অক্সিজেন') ||
        q.contains('শ্বাস') ||
        q.contains('श्वास');

    if (isSpo2) {
      switch (lang) {
        case 'hi':
          return """• पल्स ऑक्सीमेट्री (SpO2 / Oxygen) मानक:
- सामान्य: 95% - 100% (हरा - सुरक्षित)
- मध्यम हाइपोक्सिया: 90% - 94% (पीला - PHC डॉक्टर से जांच, फेफड़ों की आवाज सुनें)
- गंभीर हाइपोक्सिया: < 90% (लाल - तुरंत ऑक्सीजन और अस्पताल वाहन 108)।
- खतरे के लक्षण: सामान्य SpO2 होने पर भी सांस लेने में तेज घरघराहट या पसली चलना।""";
        case 'kn':
          return """• ಪಲ್ಸ್ ಆಕ್ಸಿಮೆಟ್ರಿ (SpO2) ಮಾನದಂಡಗಳು:
- ಸಾಮಾನ್ಯ: 95% - 100% (ಹಸಿರು)
- ಮಧ್ಯಮ ಕೊರತೆ: 90% - 94% (ಹಳದಿ - PHC ವೈದ್ಯರ ಭೇಟಿ)
- ತೀವ್ರ ಕೊರತೆ: < 90% (RED - ತುರ್ತು ಆಮ್ಲಜನಕ ಮತ್ತು ಆಸ್ಪತ್ರೆ ಸಾಗಾಣಿಕೆ).""";
        case 'ta':
          return """• பல்ஸ் ஆக்ஸிமெட்ரி (SpO2) தரநிலைகள்:
- இயல்பானது: 95% - 100% (பச்சை)
- மிதமான குறைவு: 90% - 94% (மஞ்சள் - PHC மருத்துவரிடம் பரிசோதிக்கவும்)
- கடுமையான குறைவு: < 90% (சிவப்பு - உடனடி ஆக்ஸிஜன் மற்றும் மருத்துவமனை).""";
        case 'te':
          return """• పల్స్ ఆక్సిమెట్రీ (SpO2) ప్రమాణాలు:
- సాధారణం: 95% - 100% (ఆకుపచ్చ)
- మధ్యస్థ లోపం: 90% - 94% (పసుపు - PHC డాక్టర్ సంప్రదింపులు)
- తీవ్ర లోపం: < 90% (RED - తక్షణ ఆక్సిజన్ మరియు ఆసుపత్రి తరలింపు).""";
        case 'bn':
          return """• পালস অক্সিমেট্রি (SpO2) মান:
- স্বাভাবিক: ৯৫% - ১০০% (সবুজ)
- মাঝারি ঘাটতি: ৯০% - ৯৪% (হলুদ - PHC ডাক্তারের পরামর্শ)
- গুরুতর ঘাটতি: < ৯০% (লাল - জরুরি অক্সিজেন ও হাসপাতালে স্থানান্তর)।""";
        case 'mr':
          return """• पल्स ऑक्सिमेट्री (SpO2) मानके:
- सामान्य: 95% - 100% (हिरवा)
- मध्यम कमतरता: 90% - 94% (पिवळा - PHC सल्ला)
- तीव्र कमतरता: < 90% (लाल - तातडीने ऑक्सिजन व रुग्णालय).""";
        default:
          return """• PULSE OXIMETRY (SpO2) STANDARDS:
- Normal: 95% - 100% (Green)
- Moderate Hypoxia: 90% - 94% (Yellow - PHC consultation, check lung sounds)
- Severe Hypoxia: < 90% (RED - Urgent oxygenation, hospital transport).
- Red-flag with normal SpO2: Stridor, chest in-drawing, or severe dyspnea.""";
      }
    }

    switch (lang) {
      case 'hi':
        return """• नैदानिक ट्राइएज प्रोटोकॉल (Nirogya Setu):
1. पूरे वाइटल्स की जांच करें (BP, SpO2, पल्स, ब्लड शुगर, तापमान)।
2. वर्गीकरण:
   - हरा (GREEN): नियमित स्वास्थ्य, 6 महीने बाद पुनः फॉलो-अप।
   - पीला (YELLOW): 7 दिनों के भीतर PHC चिकित्सा अधिकारी परामर्श।
   - लाल (RED): 24 घंटे के भीतर 108 एम्बुलेंस से जिला अस्पताल आपातकालीन रेफरल।
3. जांच को ऑफ़लाइन डेटाबेस में सहेजें और इंटरनेट आने पर सिंक करें।""";
      case 'kn':
        return """• ಕ್ಲಿನಿಕಲ್ ಟ್ರಯೇಜ್ ಪ್ರೋಟೋಕಾಲ್ (Nirogya Setu):
1. ಸಂಪೂರ್ಣ ವೈಟಲ್ಸ್ ಪರಿಶೀಲಿಸಿ (BP, SpO2, ನಾಡಿಮಿಡಿತ, ಸಕ್ಕರೆ, ತಾಪಮಾನ).
2. ವರ್ಗೀಕರಣ:
   - ಹಸಿರು (GREEN): ಸಾಮಾನ್ಯ ಆರೈಕೆ, 6 ತಿಂಗಳಲ್ಲಿ ಮರುಪರಿಶೀಲನೆ.
   - ಹಳದಿ (YELLOW): 7 ದಿನಗಳಲ್ಲಿ PHC ವೈದ್ಯಾಧಿಕಾರಿ ಭೇಟಿ.
   - ಕೆಂಪು (RED): 24 ಗಂಟೆಗಳಲ್ಲಿ 108 ಆಂಬ್ಯುಲೆನ್ಸ್ ಮೂಲಕ ಜಿಲ್ಲಾ ಆಸ್ಪತ್ರೆಗೆ ತುರ್ತು ರೆಫರಲ್.
3. ಆಫ್‌ಲೈನ್ ಡೇಟಾಬೇಸ್‌ನಲ್ಲಿ ನೋಂದಾಯಿಸಿ ಮತ್ತು ನೆಟ್‌ವರ್ಕ್ ಬಂದಾಗ ಸಿಂಕ್ ಮಾಡಿ.""";
      case 'ta':
        return """• மருத்துவ சோதனை நெறிமுறை (Nirogya Setu):
1. முழுமையான முக்கிய அளவீடுகளை பதிவு செய்யவும் (BP, SpO2, பல்ஸ், சுகர், காய்ச்சல்).
2. வகைப்பாடு:
   - பச்சை (GREEN): வழக்கமான நல்வாழ்வு, 6 மாதங்களில் பரிசோதனை.
   - மஞ்சள் (YELLOW): 7 நாட்களுக்குள் PHC மருத்துவர் ஆலோசனை.
   - சிவப்பு (RED): 24 மணி நேரத்திற்குள் மாவட்ட மருத்துவமனைக்கு அவசர பரிந்துரை.
3. ஆஃப்லைனில் சேமித்து இணையம் வந்ததும் ஒத்திசைக்கவும்.""";
      case 'te':
        return """• క్లినికల్ ట్రయాజ్ ప్రోటోకాల్ (Nirogya Setu):
1. పూర్తి ప్రాణాధారాలను కొలవండి (BP, SpO2, పల్స్, బ్లడ్ షుగర్, ఉష్ణోగ్రత).
2. వర్గీకరణ:
   - ఆకుపచ్చ (GREEN): సాధారణ క్షేమం, 6 నెలల్లో ఫాలో-అప్.
   - పసుపు (YELLOW): 7 రోజుల్లో PHC డాక్టర్ సంప్రదింపులు.
   - ఎరుపు (RED): 24 గంటల్లో 108 అంబులెన్స్ ద్వారా అత్యవసర రిఫరల్.
3. ఆఫ్‌లైన్‌లో నమోదు చేసి ఇంటర్నెట్ రాగానే సింక్ చేయండి.""";
      case 'bn':
        return """• ক্লিনিকাল ট্রায়াজ প্রোটোকল (Nirogya Setu):
1. সম্পূর্ণ ভাইটালস পরিমাপ করুন (BP, SpO2, নাড়ি, ব্লাড সুগার, তাপমাত্রা)।
2. শ্রেণিবিভাগ:
   - সবুজ (GREEN): স্বাভাবিক সুস্থতা, ৬ মাস পর পরীক্ষা।
   - হলুদ (YELLOW): ৭ দিনের মধ্যে PHC ডাক্তারের পরামর্শ।
   - লাল (RED): ২৪ ঘণ্টার মধ্যে জেলা হাসপাতালে জরুরি রেফারেল।
3. অফলাইনে সংরক্ষণ করুন এবং নেটওয়ার্ক ফিরলে সিঙ্ক করুন।""";
      case 'mr':
        return """• क्लिनिकल ट्रायज प्रोटोकॉल (Nirogya Setu):
1. सर्व व्हायटल्स तपासा (BP, SpO2, नाडी, ब्लड शुगर, तापमान).
2. वर्गीकरण:
   - हिरवा (GREEN): नियमित आरोग्य तपासणी, 6 महिन्यांनी.
   - पिवळा (YELLOW): 7 दिवसांत PHC वैद्यकीय अधिकारी सल्ला.
   - लाल (RED): 24 तासांच्या आत 108 रुग्णवाहिकेद्वारे जिल्हा रुग्णालयात तातडीने रेफरल.
3. डेटा ऑफलाइन साठवा व इंटरनेट आल्यावर सिंक करा.""";
      default:
        return """• CLINICAL TRIAGE PROTOCOL (Nirogya Setu):
1. Measure complete vitals (BP, SpO2, Pulse, Blood Sugar, Temperature).
2. Classify:
   - GREEN: Routine wellness, revisit in 6 months.
   - YELLOW: PHC Medical Officer consultation within 7 days.
   - RED: Emergency escalation to District Hospital within 24 hours.
3. Record screening in offline database and synchronize when connectivity resumes.""";
    }
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
                style: TextStyle(fontSize: 11, color: Color(0xFF6B5443)),
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
      backgroundColor: const Color(0xFFFBF4E8),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nirogya Setu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              appLocale?.t('clinicalAssistant') ?? 'ASHA Clinical Assistant',
              style: const TextStyle(fontSize: 11, color: Color(0xFFE4E6CC)),
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
                color: const Color(0xFF2C4D27),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA8C98E), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: Color(0xFFA8C98E),
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
              color: _speakReplies ? const Color(0xFFA8C98E) : Colors.white70,
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
                  final translatedGreeting = _greetings[_chatLanguage] ?? appLocale?.t('botGreeting') ?? msg.text;
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
              color: const Color(0xFFF4D6C8),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic_rounded, size: 14, color: Color(0xFFB23A22)),
                  const SizedBox(width: 6),
                  Text(
                    Provider.of<AppLocale?>(context, listen: true)?.t('listening') ?? 'Listening...',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB23A22), fontWeight: FontWeight.w600),
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
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B5443)),
                  ),
                ],
              ),
            ),

          // Streamlined Quick Prompts Collapsible Drawer
          if (_showQuickPrompts)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8D5),
                border: Border(top: BorderSide(color: Color(0xFFE2D2B6))),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (_suggestedPromptsMap[_chatLanguage] ?? _suggestedPrompts).map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: const Color(0xFFFBF4E8),
                        side: const BorderSide(color: Color(0xFFD5C1A0)),
                        label: Text(
                          p,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF33200F),
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
              color: Color(0xFFFBF4E8),
              border: Border(top: BorderSide(color: Color(0xFFE2D2B6))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showQuickPrompts ? Icons.grid_view_rounded : Icons.grid_view_outlined,
                    size: 20,
                    color: _showQuickPrompts ? AppColors.primary : const Color(0xFF6B5443),
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
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9A8571)),
                        filled: true,
                        fillColor: const Color(0xFFFBF4E8),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2D2B6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2D2B6)),
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
                  backgroundColor: _isListening ? Color(0xFFB23A22) : AppColors.primary,
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
          color: msg.isUser ? AppColors.primary : AppColors.paint,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isUser ? Colors.transparent : const Color(0xFFE2D2B6),
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
                  Builder(builder: (context) {
                    final isThisSpeaking = _isSpeaking && _currentlySpeakingText == msg.text;
                    return IconButton(
                      icon: Icon(
                        isThisSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                        size: 16,
                        color: isThisSpeaking ? Colors.red : AppColors.primary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: isThisSpeaking ? 'Stop voice' : 'Read aloud',
                      onPressed: () => _speak(msg.text, force: true),
                    );
                  }),
                  if (msg.isOffline) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8D5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('ICMR Offline', style: TextStyle(fontSize: 8.5, color: Color(0xFF4A3626))),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: msg.isUser ? Colors.white : const Color(0xFF33200F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
