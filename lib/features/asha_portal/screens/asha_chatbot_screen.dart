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
      text: "Hello! I am your Aarogya Setu health assistant. Ask me about danger signs in pregnancy, child health, triage rules, or when to refer a citizen to the doctor.",
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
      debugPrint('Online assistant failed, using offline guide: $e');
      final fallback = _queryOfflineKnowledge(clean);
      setState(() {
        _messages.add(ChatMessage(
          text: "$fallback\n\n(Online answer could not load, so this is from the offline guide.)",
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
        final textTheme = Theme.of(ctx).textTheme;
        return AlertDialog(
          icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
          title: const Text('Assistant settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a key to get online answers when you have internet.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Groq API key',
                    hintText: 'gsk_...',
                    prefixIcon: Icon(Icons.key_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Leave it empty to use the offline guide. The offline guide works without internet.',
                  style: textTheme.bodySmall,
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
              onPressed: () async {
                await _saveGroqApiKey(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        controller.text.trim().isNotEmpty
                            ? 'Key saved. Online answers are on.'
                            : 'Using the offline guide.',
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
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        title: const Text('Health assistant'),
      ),
      body: Column(
        children: [
          _buildTopPanel(context),

          // Message stream
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: AppSpacing.screen,
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text('Finding an answer…', style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),

          _buildInputBar(),
        ],
      ),
    );
  }

  /// Mode status (online/offline) with a settings action, then suggested questions.
  Widget _buildTopPanel(BuildContext context) {
    final online = _groqApiKey != null;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  online ? Icons.cloud_done_outlined : Icons.offline_pin_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    online ? 'Online answers' : 'Offline guide, works without internet',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Settings'),
                  onPressed: _showSettingsDialog,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: _suggestedPrompts.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ActionChip(
                    label: Text(p),
                    onPressed: () => _sendMessage(p),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Type your question'),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                icon: const Icon(Icons.send_rounded),
                tooltip: 'Send',
                onPressed: () => _sendMessage(_textController.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary : AppColors.surface,
          borderRadius: AppRadius.card,
          border: msg.isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!msg.isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.health_and_safety_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      msg.isOffline ? 'Assistant · offline guide' : 'Assistant',
                      style: textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              msg.text,
              style: textTheme.bodyMedium?.copyWith(
                color: msg.isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
