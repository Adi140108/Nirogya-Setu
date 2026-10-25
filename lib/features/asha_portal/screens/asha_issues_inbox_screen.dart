import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/issue_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';

class AshaIssuesInboxScreen extends StatefulWidget {
  const AshaIssuesInboxScreen({super.key});

  @override
  State<AshaIssuesInboxScreen> createState() => _AshaIssuesInboxScreenState();
}

class _AshaIssuesInboxScreenState extends State<AshaIssuesInboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _playingIssueId;
  Timer? _audioPlaybackTimer;
  int _audioPlaybackSeconds = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _audioPlaybackTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleAudioPlayback(IssueModel issue) {
    if (_playingIssueId == issue.id) {
      _audioPlaybackTimer?.cancel();
      setState(() {
        _playingIssueId = null;
        _audioPlaybackSeconds = 0;
      });
    } else {
      _audioPlaybackTimer?.cancel();
      setState(() {
        _playingIssueId = issue.id;
        _audioPlaybackSeconds = 0;
      });

      final totalDuration = issue.voiceDurationSeconds > 0 ? issue.voiceDurationSeconds : 5;
      _audioPlaybackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _audioPlaybackSeconds++;
          if (_audioPlaybackSeconds >= totalDuration) {
            _playingIssueId = null;
            _audioPlaybackSeconds = 0;
            timer.cancel();
          }
        });
      });
    }
  }

  Future<void> _markIssueCompleted(BuildContext context, IssueModel issue) async {
    final repo = Provider.of<HealthRepository>(context, listen: false);
    await repo.resolveIssue(issue.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Issue by ${issue.citizenName} marked as completed & saved to records.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            repo.unresolveIssue(issue.id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ashaUser = context.watch<AuthService>().currentUser;
    final repo = context.watch<HealthRepository>();
    final allIssues = List<IssueModel>.from(repo.getIssuesForAsha(ashaUser));

    // Sort according to timing (newest first)
    allIssues.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final pendingIssues = allIssues.where((i) => !i.isResolved).toList();
    final completedIssues = allIssues.where((i) => i.isResolved).toList();

    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF4E8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Citizen Issues Inbox',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${pendingIssues.length} pending • click ✓ to complete and record',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_unread_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Pending (${pendingIssues.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Completed (${completedIssues.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 760 : double.infinity),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildIssuesList(pendingIssues, isPendingList: true),
              _buildIssuesList(completedIssues, isPendingList: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssuesList(List<IssueModel> issues, {required bool isPendingList}) {
    if (issues.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isPendingList ? Color(0xFFE4E6CC) : Color(0xFFE4E6CC),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPendingList
                      ? Icons.task_alt_rounded
                      : Icons.archive_outlined,
                  size: 54,
                  color: isPendingList ? AppColors.primaryGreen : Color(0xFF3B6634),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isPendingList ? 'All Citizen Issues Attended!' : 'No Completed Records Yet',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                isPendingList
                    ? 'When citizens in your village raise a problem or send a voice note, it will appear here in order of timing.'
                    : 'Whenever you click the small tick (✓) beside a notification, it is preserved here as a permanent completion record.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B5443)),
              ),
            ],
          ),
        ),
      );
    }

    final timeFormatter = DateFormat('dd MMM, hh:mm a');

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: issues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final issue = issues[index];
        return _buildIssueCard(issue, timeFormatter, isPending: isPendingList);
      },
    );
  }

  Widget _buildIssueCard(
    IssueModel issue,
    DateFormat timeFormatter, {
    required bool isPending,
  }) {
    final isUrgent = issue.urgency == 'Urgent';
    final isPlaying = _playingIssueId == issue.id;

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFBF4E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? Color(0xFFB23A22)
              : (isPending ? Color(0xFFE8D6B8) : Color(0xFFE4E6CC)),
          width: isUrgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? Color(0xFFB23A22).withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category badge, Urgency, Timestamp, and SMALL TICK (✓)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Urgency / Category Tag
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isUrgent ? Color(0xFFF4D6C8) : Color(0xFFE4E6CC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isUrgent ? Color(0xFFB23A22) : Color(0xFFE4E6CC),
                          ),
                        ),
                        child: Text(
                          isUrgent ? '🚨 URGENT' : 'Routine',
                          style: TextStyle(
                            color: isUrgent ? Color(0xFFB23A22) : Color(0xFF3B6634),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(0xFFF3E8D5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          issue.category,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Timing
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF9A8571)),
                        const SizedBox(width: 4),
                        Text(
                          timeFormatter.format(issue.createdAt),
                          style: TextStyle(fontSize: 11, color: Color(0xFF6B5443)),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(width: 10),

                // THE CRITICAL SMALL TICK (✓) BUTTON:
                // "until not clicked on a small tick beside the particular notification it wont go so that she can keep a record which all is done"
                if (isPending)
                  Tooltip(
                    message: 'Click small tick (✓) to mark done & save to records',
                    child: InkWell(
                      onTap: () => _markIssueCompleted(context, issue),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryGreen,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(0xFFF3E8D5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.done_all_rounded,
                      color: Color(0xFF3B6634),
                      size: 18,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Citizen info & household
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
                  child: Text(
                    issue.citizenName.isNotEmpty ? issue.citizenName[0] : 'C',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.citizenName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF33200F),
                        ),
                      ),
                      Text(
                        '${issue.villageName} • Household: ${issue.householdId}',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B5443)),
                      ),
                    ],
                  ),
                ),
                if (issue.contactNumber.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFE4E6CC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFE4E6CC)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_rounded, size: 14, color: AppColors.primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          issue.contactNumber,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Issue Description text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFBF4E8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFE8D6B8)),
              ),
              child: Text(
                issue.description,
                style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
              ),
            ),

            // Voice Note Player if recorded
            if (issue.hasVoiceNote) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFF3DCC4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFF3DCC4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: Color(0xFF7E3019),
                            size: 32,
                          ),
                          onPressed: () => _toggleAudioPlayback(issue),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPlaying ? 'Playing Voice Dictation...' : 'Citizen Voice Note',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF7E3019),
                                ),
                              ),
                              Text(
                                isPlaying
                                    ? '00:${_audioPlaybackSeconds.toString().padLeft(2, '0')} / 00:${issue.voiceDurationSeconds.toString().padLeft(2, '0')}'
                                    : '${issue.voiceDurationSeconds} seconds voice recorded',
                                style: TextStyle(fontSize: 11, color: Color(0xFF7E3019)),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.graphic_eq_rounded, color: Color(0xFF7E3019), size: 24),
                      ],
                    ),
                    if (issue.voiceTranscription != null &&
                        issue.voiceTranscription!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Transcription: "${issue.voiceTranscription}"',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF7E3019),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Resolved Status tag for history tab
            if (!isPending && issue.resolvedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF3B6634)),
                  const SizedBox(width: 4),
                  Text(
                    'Resolved & recorded on: ${timeFormatter.format(issue.resolvedAt!)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF3B6634), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
