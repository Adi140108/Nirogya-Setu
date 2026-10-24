import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/admin_models.dart';
import '../../../../core/services/admin_repository.dart';
import '../../../awareness_hub/widgets/youtube_thumbnail.dart';
import '../../widgets/admin_ui.dart';

/// Add or edit a Health Hub video. Each language has its own title,
/// description and YouTube link; citizens switch between them in the player.
class VideoFormScreen extends StatefulWidget {
  final HealthVideoModel? existing;

  const VideoFormScreen({super.key, this.existing});

  @override
  State<VideoFormScreen> createState() => _VideoFormScreenState();
}

class _LanguageBlock {
  String? language;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController link;

  _LanguageBlock({this.language, String title = '', String description = '', String link = ''})
      : title = TextEditingController(text: title),
        description = TextEditingController(text: description),
        link = TextEditingController(text: link);

  void dispose() {
    title.dispose();
    description.dispose();
    link.dispose();
  }
}

class _VideoFormScreenState extends State<VideoFormScreen> {
  static const List<String> _topicSuggestions = [
    'Maternal & Child Health',
    'Vector-borne Disease',
    'Nutrition',
    'Sanitation & Hygiene',
    'Non-Communicable Diseases',
    'Vaccination',
    'Summer Safety',
    'Mental Health',
    'First Aid',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _topic;
  final List<_LanguageBlock> _blocks = [];
  bool _isBusy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _topic = TextEditingController(text: e?.topic ?? '');
    if (e != null) {
      for (final v in e.variants) {
        _blocks.add(_LanguageBlock(
          language: v.language,
          title: v.title,
          description: v.description,
          link: v.youtubeUrl,
        ));
      }
    }
    if (_blocks.isEmpty) _blocks.add(_LanguageBlock(language: 'Hindi'));
    for (final b in _blocks) {
      b.link.addListener(_onLinkChanged);
    }
  }

  void _onLinkChanged() => setState(() {});

  @override
  void dispose() {
    _topic.dispose();
    for (final b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  List<String> _languagesFor(_LanguageBlock block) {
    final taken = _blocks.where((b) => b != block).map((b) => b.language).toSet();
    final options = AdminRepository.supportedVideoLanguages.where((l) => !taken.contains(l)).toList();
    if (block.language != null && !options.contains(block.language)) options.insert(0, block.language!);
    return options;
  }

  void _addBlock() {
    final used = _blocks.map((b) => b.language).toSet();
    final next = AdminRepository.supportedVideoLanguages.firstWhere((l) => !used.contains(l), orElse: () => '');
    if (next.isEmpty) {
      showAdminSnack(context, 'All supported languages have been added.', isError: true);
      return;
    }
    setState(() => _blocks.add(_LanguageBlock(language: next)..link.addListener(_onLinkChanged)));
  }

  void _removeBlock(_LanguageBlock block) {
    setState(() => _blocks.remove(block));
    block.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<AdminRepository>();
    final variants = _blocks
        .map((b) => VideoLanguageVariant(
              language: b.language!,
              title: b.title.text.trim(),
              description: b.description.text.trim(),
              youtubeUrl: b.link.text.trim(),
              youtubeId: AdminRepository.parseYoutubeId(b.link.text)!,
            ))
        .toList();

    setState(() => _isBusy = true);
    try {
      if (_isEdit) {
        await repo.updateVideo(widget.existing!.copyWith(topic: _topic.text.trim(), variants: variants));
        if (!mounted) return;
        showAdminSnack(context, 'Video updated in Health Hub');
      } else {
        await repo.addVideo(topic: _topic.text.trim(), variants: variants);
        if (!mounted) return;
        showAdminSnack(context, 'Video published to the citizen Health Hub');
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showAdminSnack(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AdminColors.ink,
        title: Text(_isEdit ? 'Edit Video' : 'Add Video', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminFormSection(
              title: 'Topic',
              icon: Icons.topic_outlined,
              children: [
                AdminField(
                  child: TextFormField(
                    controller: _topic,
                    textCapitalization: TextCapitalization.words,
                    decoration: adminInput('Health topic *', icon: Icons.label_outline_rounded, hint: 'e.g. Nutrition'),
                    validator: (v) => (v ?? '').trim().length < 3 ? 'Enter the health topic' : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in _topicSuggestions)
                        ActionChip(
                          label: Text(t, style: const TextStyle(fontSize: 11.5)),
                          onPressed: () => setState(() => _topic.text = t),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            for (var i = 0; i < _blocks.length; i++) _buildLanguageBlock(i, _blocks[i]),
            OutlinedButton.icon(
              onPressed: _addBlock,
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminColors.video,
                side: const BorderSide(color: AdminColors.video),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.translate_rounded, size: 18),
              label: const Text('Add another language', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),
            AdminPrimaryButton(
              label: _isEdit ? 'Save Changes' : 'Publish Video',
              icon: _isEdit ? Icons.check_rounded : Icons.publish_rounded,
              isBusy: _isBusy,
              onPressed: _save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageBlock(int index, _LanguageBlock block) {
    final youtubeId = AdminRepository.parseYoutubeId(block.link.text);
    final languages = _languagesFor(block);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AdminCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.translate_rounded, size: 18, color: AdminColors.video),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    index == 0 ? 'Language version 1 (default)' : 'Language version ${index + 1}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AdminColors.ink),
                  ),
                ),
                if (_blocks.length > 1)
                  IconButton(
                    tooltip: 'Remove this language',
                    icon: const Icon(Icons.close_rounded, color: AdminColors.muted),
                    onPressed: () => _removeBlock(block),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            AdminField(
              child: TextFormField(
                controller: block.title,
                textCapitalization: TextCapitalization.sentences,
                decoration: adminInput('Title in this language *', icon: Icons.title_rounded),
                validator: (v) => (v ?? '').trim().length < 3 ? 'Enter the video title' : null,
              ),
            ),
            AdminField(
              child: TextFormField(
                controller: block.description,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                decoration: adminInput('Description in this language *', icon: Icons.notes_rounded),
                validator: (v) => (v ?? '').trim().length < 10 ? 'Add a short description (10+ characters)' : null,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 128,
                  child: AdminField(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('lang-${identityHashCode(block)}-${languages.length}'),
                      value: block.language,
                      isExpanded: true,
                      decoration: adminInput('Language *'),
                      items: languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      validator: (v) => v == null ? 'Required' : null,
                      onChanged: (v) => setState(() => block.language = v),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminField(
                    child: TextFormField(
                      controller: block.link,
                      keyboardType: TextInputType.url,
                      decoration: adminInput('YouTube link *', icon: Icons.link_rounded, hint: 'https://youtu.be/…'),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return 'Paste the YouTube link';
                        return AdminRepository.parseYoutubeId(v!) == null ? 'Not a valid YouTube link' : null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (youtubeId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        YoutubeThumbnail(youtubeId: youtubeId),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: AdminChip(
                            label: 'YouTube ID • $youtubeId',
                            icon: Icons.check_circle_rounded,
                            color: Colors.white,
                            surface: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
