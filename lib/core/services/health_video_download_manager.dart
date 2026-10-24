import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/admin_models.dart';
import '../models/awareness_content_model.dart';
import 'storage_service.dart';

/// Download state of one language version of one Health Hub video.
class HealthVideoDownload {
  final String key;
  final String youtubeId;
  final VideoDownloadStatus status;
  final double progress;
  final String? localPath;
  final int? sizeBytes;
  final String? error;

  const HealthVideoDownload({
    required this.key,
    required this.youtubeId,
    this.status = VideoDownloadStatus.notDownloaded,
    this.progress = 0,
    this.localPath,
    this.sizeBytes,
    this.error,
  });

  bool get isDownloaded => status == VideoDownloadStatus.downloaded && localPath != null;
  bool get isDownloading => status == VideoDownloadStatus.downloading;

  Map<String, dynamic> toMap() => {
        'key': key,
        'youtubeId': youtubeId,
        'status': status.value,
        'localPath': localPath,
        'sizeBytes': sizeBytes,
      };

  factory HealthVideoDownload.fromMap(Map<String, dynamic> map) => HealthVideoDownload(
        key: map['key'] ?? '',
        youtubeId: map['youtubeId'] ?? '',
        status: VideoDownloadStatusExtension.fromString(map['status']),
        progress: map['status'] == 'downloaded' ? 1 : 0,
        localPath: map['localPath'],
        sizeBytes: (map['sizeBytes'] as num?)?.toInt(),
      );

  HealthVideoDownload copyWith({
    VideoDownloadStatus? status,
    double? progress,
    String? localPath,
    bool clearLocalPath = false,
    int? sizeBytes,
    String? error,
    bool clearError = false,
  }) {
    return HealthVideoDownload(
      key: key,
      youtubeId: youtubeId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPath: clearLocalPath ? null : (localPath ?? this.localPath),
      sizeBytes: sizeBytes ?? this.sizeBytes,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Saves YouTube Health Hub videos to the device so citizens can watch them
/// with no internet. Each language version is stored as its own MP4 file.
class HealthVideoDownloadManager extends ChangeNotifier {
  final StorageService _storage;
  final Connectivity _connectivity = Connectivity();
  final Map<String, HealthVideoDownload> _downloads = {};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;

  HealthVideoDownloadManager(this._storage) {
    _init();
  }

  bool get isOnline => _isOnline;

  static String keyFor(String videoId, String language) => '$videoId|$language';

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = !results.contains(ConnectivityResult.none);
    } catch (_) {
      _isOnline = true;
    }
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });

    final stored = await _storage.loadJsonList(StorageService.keyHealthVideoDownloads);
    for (final map in stored) {
      final entry = HealthVideoDownload.fromMap(map);
      if (entry.localPath != null && await File(entry.localPath!).exists()) {
        _downloads[entry.key] = entry.copyWith(status: VideoDownloadStatus.downloaded, progress: 1);
      }
    }
    notifyListeners();
  }

  /// Download state for a video's language version. A download made for an
  /// older YouTube link (admin replaced the link) is treated as not downloaded.
  HealthVideoDownload stateFor(String videoId, VideoLanguageVariant variant) {
    final key = keyFor(videoId, variant.language);
    final entry = _downloads[key];
    if (entry == null || entry.youtubeId != variant.youtubeId) {
      return HealthVideoDownload(key: key, youtubeId: variant.youtubeId);
    }
    return entry;
  }

  int get downloadedCount => _downloads.values.where((d) => d.isDownloaded).length;

  Future<void> download(String videoId, VideoLanguageVariant variant) async {
    final key = keyFor(videoId, variant.language);
    if (_downloads[key]?.isDownloading == true) return;

    if (!_isOnline) {
      _downloads[key] = HealthVideoDownload(
        key: key,
        youtubeId: variant.youtubeId,
        status: VideoDownloadStatus.waitingForInternet,
        error: 'Connect to the internet to download this video.',
      );
      notifyListeners();
      return;
    }

    _downloads[key] = HealthVideoDownload(
      key: key,
      youtubeId: variant.youtubeId,
      status: VideoDownloadStatus.downloading,
      progress: 0.02,
    );
    notifyListeners();

    final yt = YoutubeExplode();
    File? partFile;
    try {
      final manifest = await yt.videos.streamsClient.getManifest(
        variant.youtubeId,
        ytClients: [YoutubeApiClient.androidVr, YoutubeApiClient.android],
      );
      if (manifest.muxed.isEmpty) {
        throw Exception('No downloadable version is available for this video.');
      }
      final streamInfo = manifest.muxed.withHighestBitrate();
      final totalBytes = streamInfo.size.totalBytes;

      final dir = await _videosDirectory();
      final safeLang = variant.language.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      final target = File('${dir.path}/${videoId}_${safeLang}_${variant.youtubeId}.mp4');
      partFile = File('${target.path}.part');
      if (await partFile.exists()) await partFile.delete();

      final sink = partFile.openWrite();
      var received = 0;
      var lastNotified = 0.0;
      try {
        await for (final chunk in yt.videos.streamsClient.get(streamInfo)) {
          sink.add(chunk);
          received += chunk.length;
          final progress = totalBytes > 0 ? (received / totalBytes).clamp(0.02, 0.99).toDouble() : 0.5;
          if (progress - lastNotified >= 0.01) {
            lastNotified = progress;
            _downloads[key] = _downloads[key]!.copyWith(progress: progress);
            notifyListeners();
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      if (received < 10000) throw Exception('Downloaded file is incomplete.');
      if (await target.exists()) await target.delete();
      await partFile.rename(target.path);

      _downloads[key] = _downloads[key]!.copyWith(
        status: VideoDownloadStatus.downloaded,
        progress: 1,
        localPath: target.path,
        sizeBytes: received,
        clearError: true,
      );
      await _persist();
    } catch (e) {
      debugPrint('Health video download failed: $e');
      if (partFile != null && await partFile.exists()) {
        await partFile.delete();
      }
      _downloads[key] = HealthVideoDownload(
        key: key,
        youtubeId: variant.youtubeId,
        status: _isOnline ? VideoDownloadStatus.notDownloaded : VideoDownloadStatus.waitingForInternet,
        error: 'Download failed. Please check your internet connection and try again.',
      );
    } finally {
      yt.close();
      notifyListeners();
    }
  }

  Future<void> removeDownload(String videoId, VideoLanguageVariant variant) async {
    final key = keyFor(videoId, variant.language);
    final entry = _downloads.remove(key);
    if (entry?.localPath != null) {
      final file = File(entry!.localPath!);
      if (await file.exists()) await file.delete();
    }
    await _persist();
    notifyListeners();
  }

  /// Deletes files of videos (or language versions) that no longer exist in the catalog.
  Future<void> pruneOrphans(List<HealthVideoModel> videos) async {
    final validKeys = <String, String>{
      for (final v in videos)
        for (final variant in v.variants) keyFor(v.id, variant.language): variant.youtubeId,
    };
    final orphans = _downloads.entries
        .where((e) => !e.value.isDownloading && validKeys[e.key] != e.value.youtubeId)
        .map((e) => e.key)
        .toList();
    if (orphans.isEmpty) return;
    for (final key in orphans) {
      final entry = _downloads.remove(key);
      if (entry?.localPath != null) {
        final file = File(entry!.localPath!);
        if (await file.exists()) await file.delete();
      }
    }
    await _persist();
    notifyListeners();
  }

  Future<Directory> _videosDirectory() async {
    Directory base;
    try {
      base = await getApplicationDocumentsDirectory();
    } catch (_) {
      base = Directory.systemTemp;
    }
    final dir = Directory('${base.path}/aarogya_health_hub_videos');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _persist() async {
    await _storage.saveJsonList(
      StorageService.keyHealthVideoDownloads,
      _downloads.values.where((d) => d.isDownloaded).map((d) => d.toMap()).toList(),
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
