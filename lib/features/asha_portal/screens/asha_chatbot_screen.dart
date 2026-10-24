import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';

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
      text: "Hello! I am your Aarogya Setu Clinical Assistant. I can guide you on ICMR rural triage rules, maternal warning signs, child health protocols, and emergency referrals. How can I assist your field screening today?",
      isUser: false,
      timestamp: DateTime.now(),
      isOffline: true,
    ),
  ];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _groqApiKey;

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
  }

  Future<void> _loadGroqApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _groqApiKey = prefs.getString('groq_api_key');
    });
  }

  Future<void> _saveGroqApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_api_key', key.trim());
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

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: clean, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      if (_groqApiKey != null && _groqApiKey!.isNotEmpty) {
        // Online inference via Groq
        final answer = await _queryGroq(clean);
        setState(() {
          _messages.add(ChatMessage(
            text: answer,
            isUser: false,
            timestamp: DateTime.now(),
            isOffline: false,
          ));
        });
      } else {
        // Offline clinical decision knowledge engine
        final answer = _queryOfflineKnowledge(clean);
        setState(() {
          _messages.add(ChatMessage(
            text: answer,
            isUser: false,
            timestamp: DateTime.now(),
            isOffline: true,
          ));
        });
      }
    } catch (e) {
      // Fallback to offline engine upon any network error
      final fallback = _queryOfflineKnowledge(clean);
      setState(() {
        _messages.add(ChatMessage(
          text: "$fallback\n\n*(Note: Switched to offline clinical protocols due to network)*",
          isUser: false,
          timestamp: DateTime.now(),
          isOffline: true,
        ));
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<String> _queryGroq(String query) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqApiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content': 'You are the Aarogya Setu ASHA Clinical Decision Assistant. You provide practical, evidence-based guidance for rural community health workers following National Health Mission and ICMR standards. Keep answers direct, bulleted, highlight red-flag emergency symptoms, and specify whether referral should be routine (Green), priority PHC (Yellow), or immediate emergency (Red).'
          },
          ..._messages.take(6).map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          }),
          {'role': 'user', 'content': query}
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
    throw Exception('Groq API error: ${response.statusCode}');
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Groq API Key for real-time cloud LLM responses (Llama 3.3 70B).',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Groq API Key',
                  hintText: 'gsk_...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• If empty, the assistant uses local ICMR offline protocols.\n• No internet required for offline clinical rules.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
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
                            ? '✓ Groq API Key saved. Online Llama 3.3 active.'
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aarogya Setu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              'ASHA Clinical Assistant',
              style: TextStyle(fontSize: 11, color: Color(0xFFE0F2F1)),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _groqApiKey != null ? const Color(0xFF065F46) : const Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6EE7B7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _groqApiKey != null ? Icons.bolt_rounded : Icons.offline_pin_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _groqApiKey != null ? 'Groq Llama' : 'Offline Engine',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
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
          // Suggested Query Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _suggestedPrompts.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: const Color(0xFFF1F5F9),
                      label: Text(p, style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                      onPressed: () => _sendMessage(p),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Message Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  SizedBox(width: 8),
                  Text('Analyzing clinical protocol...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
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
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Ask clinical or screening questions...',
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
                    onSubmitted: _sendMessage,
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
              color: Colors.black.withValues(alpha: 0.04),
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
