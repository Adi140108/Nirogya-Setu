enum VideoDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  waitingForInternet,
  updateAvailable,
}

extension VideoDownloadStatusExtension on VideoDownloadStatus {
  String get displayName {
    switch (this) {
      case VideoDownloadStatus.notDownloaded:
        return 'Online Only';
      case VideoDownloadStatus.downloading:
        return 'Downloading...';
      case VideoDownloadStatus.downloaded:
        return 'Available Offline';
      case VideoDownloadStatus.waitingForInternet:
        return 'Waiting for Internet';
      case VideoDownloadStatus.updateAvailable:
        return 'Update Available';
    }
  }

  String get value {
    switch (this) {
      case VideoDownloadStatus.notDownloaded:
        return 'not_downloaded';
      case VideoDownloadStatus.downloading:
        return 'downloading';
      case VideoDownloadStatus.downloaded:
        return 'downloaded';
      case VideoDownloadStatus.waitingForInternet:
        return 'waiting_internet';
      case VideoDownloadStatus.updateAvailable:
        return 'update_available';
    }
  }

  static VideoDownloadStatus fromString(String? val) {
    switch (val) {
      case 'downloading':
        return VideoDownloadStatus.downloading;
      case 'downloaded':
        return VideoDownloadStatus.downloaded;
      case 'waiting_internet':
        return VideoDownloadStatus.waitingForInternet;
      case 'update_available':
        return VideoDownloadStatus.updateAvailable;
      case 'not_downloaded':
      default:
        return VideoDownloadStatus.notDownloaded;
    }
  }
}

class AwarenessContentModel {
  final String id;
  final String title;
  final String topic;
  final String description;
  final String language;
  final String source;
  final String reviewDate;
  final int version;
  final String remoteVideoUrl;
  final String? localFilePath;
  final VideoDownloadStatus downloadStatus;
  final double downloadProgress; // 0.0 to 1.0
  final bool isVerifiedGuidance;
  final String? bundledAssetPath; // For immediate offline demonstration
  final int? fileSizeKb;

  const AwarenessContentModel({
    required this.id,
    required this.title,
    required this.topic,
    required this.description,
    required this.language,
    required this.source,
    required this.reviewDate,
    required this.version,
    required this.remoteVideoUrl,
    this.localFilePath,
    this.downloadStatus = VideoDownloadStatus.notDownloaded,
    this.downloadProgress = 0.0,
    required this.isVerifiedGuidance,
    this.bundledAssetPath,
    this.fileSizeKb,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'topic': topic,
      'description': description,
      'language': language,
      'source': source,
      'reviewDate': reviewDate,
      'version': version,
      'remoteVideoUrl': remoteVideoUrl,
      'localFilePath': localFilePath,
      'downloadStatus': downloadStatus.value,
      'downloadProgress': downloadProgress,
      'isVerifiedGuidance': isVerifiedGuidance,
      'bundledAssetPath': bundledAssetPath,
      'fileSizeKb': fileSizeKb,
    };
  }

  factory AwarenessContentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return AwarenessContentModel(
      id: id ?? map['id'] ?? '',
      title: map['title'] ?? '',
      topic: map['topic'] ?? 'General Health',
      description: map['description'] ?? '',
      language: map['language'] ?? 'Hindi',
      source: map['source'] ?? 'Ministry of Health and Family Welfare',
      reviewDate: map['reviewDate'] ?? 'October 2026',
      version: (map['version'] as num?)?.toInt() ?? 1,
      remoteVideoUrl: map['remoteVideoUrl'] ?? '',
      localFilePath: map['localFilePath'],
      downloadStatus: VideoDownloadStatusExtension.fromString(map['downloadStatus']),
      downloadProgress: (map['downloadProgress'] as num?)?.toDouble() ?? 0.0,
      isVerifiedGuidance: map['isVerifiedGuidance'] == true,
      bundledAssetPath: map['bundledAssetPath'],
      fileSizeKb: (map['fileSizeKb'] as num?)?.toInt(),
    );
  }

  AwarenessContentModel copyWith({
    String? id,
    String? title,
    String? topic,
    String? description,
    String? language,
    String? source,
    String? reviewDate,
    int? version,
    String? remoteVideoUrl,
    String? localFilePath,
    VideoDownloadStatus? downloadStatus,
    double? downloadProgress,
    bool? isVerifiedGuidance,
    String? bundledAssetPath,
    int? fileSizeKb,
  }) {
    return AwarenessContentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      language: language ?? this.language,
      source: source ?? this.source,
      reviewDate: reviewDate ?? this.reviewDate,
      version: version ?? this.version,
      remoteVideoUrl: remoteVideoUrl ?? this.remoteVideoUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isVerifiedGuidance: isVerifiedGuidance ?? this.isVerifiedGuidance,
      bundledAssetPath: bundledAssetPath ?? this.bundledAssetPath,
      fileSizeKb: fileSizeKb ?? this.fileSizeKb,
    );
  }
}
