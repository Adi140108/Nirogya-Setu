import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/services/health_repository.dart';

class RaiseIssueScreen extends StatefulWidget {
  final PatientModel? patient;

  const RaiseIssueScreen({super.key, this.patient});

  @override
  State<RaiseIssueScreen> createState() => _RaiseIssueScreenState();
}

class _RaiseIssueScreenState extends State<RaiseIssueScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  late String _citizenName;
  late String _contactNumber;
  late String _householdId;
  late String _villageName;
  late String _citizenId;

  String _selectedCategory = 'Fever / Illness';
  String _urgency = 'Normal';

  // Voice recording & dictation state
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordTimer;
  bool _hasRecordedVoice = false;
  String? _recordedTranscription;
  bool _isPlayingPreview = false;
  Timer? _playbackTimer;
  int _playbackProgress = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _categories = [
    'Fever / Illness',
    'Medicine Refill',
    'Maternal Care',
    'Elderly Care',
    'Emergency Assistance',
    'Vaccination Query',
    'Other Problem',
  ];

  final List<String> _simulatedTranscripts = [
    'नमस्ते दीदी, मुझे पिछले दो दिनों से तेज़ बुखार और शरीर में दर्द है। कृपया दवा भिजवा दीजिए।',
    'आशा दीदी, मेरे बीपी की गोली ख़त्म हो गई है। कृपया नई पर्ची या दवा उपलब्ध कराएं।',
    'दीदी, बच्चे को कल रात से उल्टी और दस्त हो रहे हैं। क्या करना चाहिए बताएं।',
    'ASHA Didi, patient is having severe headache and nausea since yesterday. Please visit our household.',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _citizenId = p?.id ?? 'p-001';
    _citizenName = p?.fullName ?? 'Ramesh Kumar';
    _contactNumber = p?.contactNumber ?? '+91 98765 43210';
    _householdId = p?.householdId ?? 'HH-042';
    _villageName = p?.villageName ?? 'Rampura';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playbackTimer?.cancel();
    _pulseController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
      _hasRecordedVoice = false;
      _recordedTranscription = null;
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration++;
        });
        // Auto-transcribe sample voice snippet after a few seconds
        if (_recordingDuration == 4 && _descriptionController.text.trim().isEmpty) {
          final sample = _simulatedTranscripts[
              DateTime.now().microsecond % _simulatedTranscripts.length];
          _recordedTranscription = sample;
        }
      }
    });
  }

  void _stopRecording() {
    _recordTimer?.cancel();
    if (_recordingDuration < 1) {
      _recordingDuration = 2; // minimum realistic recording
    }

    if (_recordedTranscription == null) {
      final sample = _simulatedTranscripts[
          DateTime.now().microsecond % _simulatedTranscripts.length];
      _recordedTranscription = sample;
    }

    setState(() {
      _isRecording = false;
      _hasRecordedVoice = true;
      if (_descriptionController.text.trim().isEmpty && _recordedTranscription != null) {
        _descriptionController.text = _recordedTranscription!;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Voice recorded (${_recordingDuration}s). Speech dictated to text!',
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _togglePlayback() {
    if (_isPlayingPreview) {
      _playbackTimer?.cancel();
      setState(() {
        _isPlayingPreview = false;
        _playbackProgress = 0;
      });
    } else {
      setState(() {
        _isPlayingPreview = true;
        _playbackProgress = 0;
      });
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!mounted) return;
        setState(() {
          _playbackProgress++;
          if (_playbackProgress >= (_recordingDuration * 2)) {
            _isPlayingPreview = false;
            _playbackProgress = 0;
            timer.cancel();
          }
        });
      });
    }
  }

  void _deleteVoiceNote() {
    _playbackTimer?.cancel();
    setState(() {
      _hasRecordedVoice = false;
      _recordingDuration = 0;
      _recordedTranscription = null;
      _isPlayingPreview = false;
    });
  }

  Future<void> _submitIssue() async {
    final text = _descriptionController.text.trim();
    if (text.isEmpty && !_hasRecordedVoice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your issue or record a voice note before sending.'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
      return;
    }

    final repo = Provider.of<HealthRepository>(context, listen: false);

    final finalDescription = text.isNotEmpty
        ? text
        : (_recordedTranscription ?? 'Voice note recorded for ASHA worker');

    await repo.raiseIssue(
      citizenId: _citizenId,
      citizenName: _citizenName,
      contactNumber: _contactNumber,
      villageId: widget.patient?.villageId ?? 'vil-01',
      villageName: _villageName,
      householdId: _householdId,
      category: _selectedCategory,
      description: finalDescription,
      urgency: _urgency,
      hasVoiceNote: _hasRecordedVoice,
      voiceDurationSeconds: _recordingDuration,
      voiceTranscription: _recordedTranscription,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 28),
            SizedBox(width: 10),
            Text('Issue Sent to ASHA', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your health issue has been directly sent to your village ASHA worker (Shanti Devi).',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category: $_selectedCategory',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text('Priority: $_urgency', style: const TextStyle(fontSize: 12)),
                  if (_hasRecordedVoice) ...[
                    const SizedBox(height: 4),
                    const Text('🎙️ Voice Note Attached',
                        style: TextStyle(fontSize: 12, color: AppColors.primaryGreen)),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Back to Home', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Raise Issue to ASHA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 680 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ASHA Assignment info banner
                  _buildAshaBanner(),
                  const SizedBox(height: 20),

                  // Category selection
                  const Text(
                    'Select Issue Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        selectedColor: AppColors.primaryGreen.withOpacity(0.18),
                        labelStyle: TextStyle(
                          color: selected ? AppColors.primaryGreen : Colors.black87,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primaryGreen
                                : Colors.grey.shade300,
                          ),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Urgency Selector
                  const Text(
                    'Urgency Level',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _urgency = 'Normal'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _urgency == 'Normal'
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _urgency == 'Normal'
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: _urgency == 'Normal' ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: _urgency == 'Normal' ? Colors.blue : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Normal Routine',
                                  style: TextStyle(
                                    fontWeight: _urgency == 'Normal'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _urgency == 'Normal'
                                        ? Colors.blue.shade900
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _urgency = 'Urgent'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _urgency == 'Urgent'
                                  ? Colors.red.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _urgency == 'Urgent'
                                    ? Colors.red
                                    : Colors.grey.shade300,
                                width: _urgency == 'Urgent' ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: _urgency == 'Urgent' ? Colors.red : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Urgent 🚨',
                                  style: TextStyle(
                                    fontWeight: _urgency == 'Urgent'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _urgency == 'Urgent'
                                        ? Colors.red.shade900
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Mic Dictation & Voice Note Area
                  _buildDictateMicCard(),
                  const SizedBox(height: 20),

                  // Description Text Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Describe in Words',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Type or dictate with mic',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Explain what you or your family member are experiencing, symptoms, medicines needed...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Active Patient Details Card
                  _buildCitizenProfileSummary(),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isRecording ? null : _submitIssue,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: const Text(
                        'Send Issue to ASHA Worker',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAshaBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primaryGreen,
            radius: 22,
            child: Icon(Icons.support_agent_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Village ASHA Worker: Shanti Devi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Assigned to $_villageName • Household: $_householdId',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDictateMicCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isRecording ? Colors.red.shade50 : Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRecording ? Colors.red.shade300 : Colors.blue.shade200,
          width: _isRecording ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mic_none_rounded,
                    color: _isRecording ? Colors.red : AppColors.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isRecording ? 'Recording Voice...' : 'Dictate with Mic / Record Voice',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _isRecording ? Colors.red.shade900 : Colors.black87,
                    ),
                  ),
                ],
              ),
              if (_isRecording)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '00:${_recordingDuration.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Central Animated Mic Button
          Center(
            child: Column(
              children: [
                ScaleTransition(
                  scale: _isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                  child: Material(
                    shape: const CircleBorder(),
                    elevation: _isRecording ? 6 : 2,
                    color: _isRecording ? Colors.red : AppColors.primaryGreen,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isRecording
                      ? 'Tap STOP when finished speaking'
                      : 'Tap to speak & dictate your problem',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isRecording ? Colors.red.shade800 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Voice note preview if recorded
          if (_hasRecordedVoice) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlayingPreview
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: AppColors.primaryGreen,
                          size: 32,
                        ),
                        onPressed: _togglePlayback,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Voice Note Recorded',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${_recordingDuration}s audio • ready for ASHA',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        tooltip: 'Delete Voice Note',
                        onPressed: _deleteVoiceNote,
                      ),
                    ],
                  ),
                  if (_recordedTranscription != null) ...[
                    const Divider(height: 14),
                    Text(
                      'Dictation Transcript:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"$_recordedTranscription"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCitizenProfileSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_pin_rounded, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Raised for: $_citizenName (${_contactNumber.isEmpty ? "No phone" : _contactNumber})',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
