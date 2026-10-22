import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/awareness_content_model.dart';
import 'storage_service.dart';

class OfflineVideoManager extends ChangeNotifier {
  final StorageService _storageService;
  final Connectivity _connectivity = Connectivity();

  List<AwarenessContentModel> _contents = [];
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;

  OfflineVideoManager(this._storageService) {
    _init();
  }

  List<AwarenessContentModel> get contents => _contents;
  bool get isOnline => _isOnline;

  Future<void> _init() async {
    // 1. Check initial connectivity
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = !results.contains(ConnectivityResult.none);
    } catch (_) {
      _isOnline = true;
    }

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final onlineNow = !results.contains(ConnectivityResult.none);
      if (_isOnline != onlineNow) {
        _isOnline = onlineNow;
        _handleConnectivityChange(onlineNow);
        notifyListeners();
      }
    });

    // 2. Load stored content catalog or initialize defaults
    await _loadCatalog();
  }

  void _handleConnectivityChange(bool online) {
    if (!online) {
      // Pause any ongoing downloads to waiting for internet
      for (int i = 0; i < _contents.length; i++) {
        if (_contents[i].downloadStatus == VideoDownloadStatus.downloading) {
          _contents[i] = _contents[i].copyWith(
            downloadStatus: VideoDownloadStatus.waitingForInternet,
          );
        }
      }
      notifyListeners();
    }
  }

  Future<void> _loadCatalog() async {
    final cached = await _storageService.loadVideosMetadata();
    if (cached.isNotEmpty) {
      _contents = cached.map((e) => AwarenessContentModel.fromMap(e)).toList();
    } else {
      _contents = _getDefaultHealthVideos();
    }

    // Verify existing offline files on local disk
    await _verifyLocalFiles();
    notifyListeners();
  }

  List<AwarenessContentModel> _getDefaultHealthVideos() {
    return [
      const AwarenessContentModel(
        id: 'vid-dengue-01',
        title: 'Dengue & Malaria Prevention in Monsoon',
        topic: 'Vector-borne Disease',
        description: 'How to eliminate standing water, recognize high fever warning signs, and prevent mosquito breeding in village water tanks.',
        language: 'Hindi / Regional',
        source: 'National Center for Vector Borne Diseases Control (NCVBDC)',
        reviewDate: 'October 2026',
        version: 1,
        remoteVideoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
        downloadStatus: VideoDownloadStatus.notDownloaded,
        isVerifiedGuidance: true,
        bundledAssetPath: 'assets/videos/sample_health_video.mp4',
        fileSizeKb: 788,
      ),
      const AwarenessContentModel(
        id: 'vid-maternal-02',
        title: 'Antenatal Care & Nutrition for Expectant Mothers',
        topic: 'Maternal & Child Health',
        description: 'Crucial iron-folic acid supplementation, danger signs during pregnancy, and institutional delivery preparation.',
        language: 'Hindi / English',
        source: 'Ministry of Health and Family Welfare (MoHFW)',
        reviewDate: 'September 2026',
        version: 1,
        remoteVideoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
        downloadStatus: VideoDownloadStatus.notDownloaded,
        isVerifiedGuidance: true,
        bundledAssetPath: 'assets/videos/sample_health_video.mp4',
        fileSizeKb: 788,
      ),
      const AwarenessContentModel(
        id: 'vid-summer-03',
        title: 'Heatstroke & Summer Dehydration First-Aid',
        topic: 'Summer Safety',
        description: 'Recognizing heat exhaustion in agricultural laborers, home preparation of ORS (Jeevan Jal), and hydration practices.',
        language: 'Hindi',
        source: 'Disaster Management & Rural Health Mission',
        reviewDate: 'August 2026',
        version: 1,
        remoteVideoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
        downloadStatus: VideoDownloadStatus.notDownloaded,
        isVerifiedGuidance: true,
        bundledAssetPath: 'assets/videos/sample_health_video.mp4',
        fileSizeKb: 788,
      ),
      const AwarenessContentModel(
        id: 'vid-hygiene-04',
        title: 'Safe Drinking Water & Cholera Prevention',
        topic: 'Sanitation & Hygiene',
        description: 'Proper boiling and chlorination of village well water, handwashing steps, and preventing waterborne diarrhea.',
        language: 'Hindi / English',
        source: 'Swachh Bharat Rural Health Taskforce',
        reviewDate: 'July 2026',
        version: 1,
        remoteVideoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
        downloadStatus: VideoDownloadStatus.notDownloaded,
        isVerifiedGuidance: true,
        bundledAssetPath: 'assets/videos/sample_health_video.mp4',
        fileSizeKb: 788,
      ),
      const AwarenessContentModel(
        id: 'vid-chronic-05',
        title: 'Managing Blood Pressure & Sugar in Elders',
        topic: 'Non-Communicable Diseases (NCD)',
        description: 'Salt reduction, daily morning walks, importance of taking regular ASHA vitals checks, and recognizing stroke symptoms.',
        language: 'Hindi',
        source: 'NPCDCS Health Advisory Board',
        reviewDate: 'October 2026',
        version: 1,
        remoteVideoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
        downloadStatus: VideoDownloadStatus.notDownloaded,
        isVerifiedGuidance: true,
        bundledAssetPath: 'assets/videos/sample_health_video.mp4',
        fileSizeKb: 788,
      ),
    ];
  }

  /// Verifies if video files actually exist in app documents directory or extracts bundled asset
  Future<void> _verifyLocalFiles() async {
    Directory? docDir;
    try {
      docDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      // On platforms without path_provider documents dir
    }

    for (int i = 0; i < _contents.length; i++) {
      final item = _contents[i];
      if (item.localFilePath != null) {
        final f = File(item.localFilePath!);
        if (await f.exists() && (await f.length()) > 1000) {
          _contents[i] = item.copyWith(
            downloadStatus: VideoDownloadStatus.downloaded,
            downloadProgress: 1.0,
          );
          continue;
        }
      }

      // If bundled asset is present, pre-seed the first item so offline playback works immediately!
      if (i == 0 && item.bundledAssetPath != null && docDir != null) {
        try {
          final targetFile = File('${docDir.path}/${item.id}_v${item.version}.mp4');
          if (!await targetFile.exists()) {
            final byteData = await rootBundle.load(item.bundledAssetPath!);
            final buffer = byteData.buffer;
            await targetFile.writeAsBytes(
              buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
            );
          }
          if (await targetFile.exists()) {
            _contents[i] = item.copyWith(
              localFilePath: targetFile.path,
              downloadStatus: VideoDownloadStatus.downloaded,
              downloadProgress: 1.0,
            );
          }
        } catch (_) {}
      }
    }
    await _saveCatalog();
  }

  /// Triggers a real network download of the video file
  Future<void> downloadVideo(String contentId) async {
    final index = _contents.indexWhere((c) => c.id == contentId);
    if (index == -1) return;

    if (!_isOnline) {
      _contents[index] = _contents[index].copyWith(
        downloadStatus: VideoDownloadStatus.waitingForInternet,
      );
      notifyListeners();
      return;
    }

    final item = _contents[index];
    _contents[index] = item.copyWith(
      downloadStatus: VideoDownloadStatus.downloading,
      downloadProgress: 0.05,
    );
    notifyListeners();

    try {
      Directory appDir;
      try {
        appDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        appDir = Directory.systemTemp;
      }

      final videosDir = Directory('${appDir.path}/aarogya_videos');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      final tempFile = File('${videosDir.path}/${item.id}_v${item.version}.part');
      final targetFile = File('${videosDir.path}/${item.id}_v${item.version}.mp4');

      final request = http.Request('GET', Uri.parse(item.remoteVideoUrl));
      final response = await http.Client().send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final contentLength = response.contentLength ?? 1000000;
        int received = 0;
        final sink = tempFile.openWrite();

        await response.stream.listen((chunk) {
          received += chunk.length;
          sink.add(chunk);
          final progress = (received / contentLength).clamp(0.05, 0.98);
          _contents[index] = _contents[index].copyWith(
            downloadProgress: progress,
          );
          notifyListeners();
        }).asFuture();

        await sink.flush();
        await sink.close();

        // Download completed and verified: atomically rename .part to .mp4
        if (await tempFile.exists() && (await tempFile.length()) > 5000) {
          // If previous version exists, replace it cleanly
          if (await targetFile.exists()) {
            await targetFile.delete();
          }
          await tempFile.rename(targetFile.path);

          _contents[index] = _contents[index].copyWith(
            localFilePath: targetFile.path,
            downloadStatus: VideoDownloadStatus.downloaded,
            downloadProgress: 1.0,
          );
          await _saveCatalog();
          notifyListeners();
        } else {
          throw Exception('Downloaded file size too small or corrupt');
        }
      } else {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }
    } catch (e) {
      // If error occurs, keep previous verified file if it exists
      final hasExisting = item.localFilePath != null && File(item.localFilePath!).existsSync();
      _contents[index] = _contents[index].copyWith(
        downloadStatus: hasExisting
            ? VideoDownloadStatus.downloaded
            : (_isOnline ? VideoDownloadStatus.notDownloaded : VideoDownloadStatus.waitingForInternet),
        downloadProgress: hasExisting ? 1.0 : 0.0,
      );
      notifyListeners();
    }
  }

  /// Removes local video file from device storage
  Future<void> removeDownloadedVideo(String contentId) async {
    final index = _contents.indexWhere((c) => c.id == contentId);
    if (index == -1) return;

    final item = _contents[index];
    if (item.localFilePath != null) {
      final f = File(item.localFilePath!);
      if (await f.exists()) {
        await f.delete();
      }
    }

    _contents[index] = item.copyWith(
      localFilePath: null,
      downloadStatus: VideoDownloadStatus.notDownloaded,
      downloadProgress: 0.0,
    );
    await _saveCatalog();
    notifyListeners();
  }

  Future<void> _saveCatalog() async {
    await _storageService.saveVideosMetadata(_contents.map((e) => e.toMap()).toList());
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
