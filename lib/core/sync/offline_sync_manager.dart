import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/health_repository.dart';

class OfflineSyncManager extends ChangeNotifier {
  final HealthRepository _repository;
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  StreamSubscription? _subscription;

  OfflineSyncManager(this._repository) {
    _init();
  }

  bool get isOnline => _isOnline;
  bool get isSyncing => _repository.isSyncing;
  int get pendingCount => _repository.pendingSyncCount;
  DateTime? get lastSyncTimestamp => _repository.lastSyncTimestamp;
  String? get lastSyncError => _repository.lastSyncError;

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = !results.contains(ConnectivityResult.none);
    } catch (_) {
      _isOnline = true;
    }
    notifyListeners();

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (_isOnline != online) {
        _isOnline = online;
        notifyListeners();
        if (_isOnline && _repository.pendingSyncCount > 0) {
          // Automatic synchronization when internet becomes available
          _repository.syncAllPending();
        }
      }
    });
  }

  Future<void> triggerManualSync() async {
    if (!_isOnline) {
      throw Exception('Device is currently offline. Connect to Wi-Fi or mobile data to sync.');
    }
    await _repository.syncAllPending();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
