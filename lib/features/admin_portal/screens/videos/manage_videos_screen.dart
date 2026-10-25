import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/admin_models.dart';
import '../../../../core/services/admin_repository.dart';
import '../../widgets/admin_ui.dart';
import '../../../awareness_hub/widgets/youtube_thumbnail.dart';
import 'video_form_screen.dart';

/// Lists Health Hub videos shown to citizens; add, edit or delete them here.
class ManageVideosScreen extends StatelessWidget {
  const ManageVideosScreen({super.key});

  Future<void> _delete(BuildContext context, AdminRepository repo, HealthVideoModel video) async {
    final confirmed = await showAdminConfirm(
      context,
      title: 'Delete this video?',
      message: '"${video.variants.first.title}" and all ${video.variants.length} language version(s) '
          'will be removed from the citizen Health Hub.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await repo.deleteVideo(video.id);
    if (context.mounted) showAdminSnack(context, 'Video removed from Health Hub');
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AdminRepository>();
    final videos = repo.videos;

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B6634),
        foregroundColor: const Color(0xFFFBF4E8),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Videos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text('Citizen Health Hub', style: TextStyle(fontSize: 11, color: Color(0xFFE4E6CC))),
          ],
        ),
      ),
      floatingActionButton: videos.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AdminColors.video,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoFormScreen())),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Video', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
      body: videos.isEmpty
          ? AdminEmptyState(
              icon: Icons.video_library_outlined,
              title: 'No Health Hub videos yet',
              message: 'Add a YouTube link for each language. Citizens can watch, switch language and download '
                  'videos to watch offline.',
              actionLabel: 'Add Video',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoFormScreen())),
            )
          : RefreshIndicator(
              onRefresh: () => repo.syncWithCloud(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
                itemCount: videos.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminColors.videoSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AdminColors.video, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${videos.length} video(s) in ${repo.availableVideoLanguages.length} language(s) '
                              'are live in the citizen Health Hub.',
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A2B18), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final video = videos[index - 1];
                  return _VideoCard(
                    video: video,
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VideoFormScreen(existing: video)),
                    ),
                    onDelete: () => _delete(context, repo, video),
                  );
                },
              ),
            ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final HealthVideoModel video;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VideoCard({required this.video, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final primary = video.variants.first;
    return AdminCard(
      padding: EdgeInsets.zero,
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  YoutubeThumbnail(youtubeId: primary.youtubeId),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: AdminChip(label: video.topic, color: Colors.white, surface: Colors.black.withOpacity(0.55)),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(primary.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AdminColors.ink)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final lang in video.languages)
                            AdminChip(
                              label: lang,
                              icon: Icons.translate_rounded,
                              color: AdminColors.video,
                              surface: AdminColors.videoSurface,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AdminSyncChip(status: video.syncStatus),
                          const SizedBox(width: 8),
                          Text('Updated ${DateFormat('dd MMM yyyy').format(video.updatedAt)}',
                              style: const TextStyle(fontSize: 11, color: AdminColors.muted)),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AdminColors.muted),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit video')),
                    PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Color(0xFFB23A22)))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
