import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyPatients = 'aarogya_patients_cache_v1';
  static const String _keyScreenings = 'aarogya_screenings_cache_v1';
  static const String _keyReferrals = 'aarogya_referrals_cache_v1';
  static const String _keyUserSession = 'aarogya_active_user_session_v1';
  static const String _keyOfflineVideos = 'aarogya_offline_videos_metadata_v1';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  // --- Patients Cache ---
  Future<void> savePatients(List<Map<String, dynamic>> patients) async {
    await init();
    await _prefs.setString(_keyPatients, jsonEncode(patients));
  }

  Future<List<Map<String, dynamic>>> loadPatients() async {
    await init();
    final data = _prefs.getString(_keyPatients);
    if (data == null || data.isEmpty) return [];
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Screenings Cache ---
  Future<void> saveScreenings(List<Map<String, dynamic>> screenings) async {
    await init();
    await _prefs.setString(_keyScreenings, jsonEncode(screenings));
  }

  Future<List<Map<String, dynamic>>> loadScreenings() async {
    await init();
    final data = _prefs.getString(_keyScreenings);
    if (data == null || data.isEmpty) return [];
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Referrals Cache ---
  Future<void> saveReferrals(List<Map<String, dynamic>> referrals) async {
    await init();
    await _prefs.setString(_keyReferrals, jsonEncode(referrals));
  }

  Future<List<Map<String, dynamic>>> loadReferrals() async {
    await init();
    final data = _prefs.getString(_keyReferrals);
    if (data == null || data.isEmpty) return [];
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- User Session ---
  Future<void> saveUserSession(Map<String, dynamic>? userMap) async {
    await init();
    if (userMap == null) {
      await _prefs.remove(_keyUserSession);
    } else {
      await _prefs.setString(_keyUserSession, jsonEncode(userMap));
    }
  }

  Future<Map<String, dynamic>?> loadUserSession() async {
    await init();
    final data = _prefs.getString(_keyUserSession);
    if (data == null || data.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  // --- Offline Videos Metadata Cache ---
  Future<void> saveVideosMetadata(List<Map<String, dynamic>> videos) async {
    await init();
    await _prefs.setString(_keyOfflineVideos, jsonEncode(videos));
  }

  Future<List<Map<String, dynamic>>> loadVideosMetadata() async {
    await init();
    final data = _prefs.getString(_keyOfflineVideos);
    if (data == null || data.isEmpty) return [];
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Admin Portal Records (generic JSON lists keyed by collection) ---
  static const String keyAdminAshaWorkers = 'aarogya_admin_asha_workers_v1';
  static const String keyAdminDoctors = 'aarogya_admin_doctors_v1';
  static const String keyAdminHospitals = 'aarogya_admin_hospitals_v1';
  static const String keyHealthVideos = 'aarogya_admin_health_videos_v1';
  static const String keyAdminPasswordHash = 'aarogya_admin_password_hash_v1';
  static const String keyHealthVideoDownloads = 'aarogya_health_video_downloads_v1';

  Future<void> saveJsonList(String key, List<Map<String, dynamic>> items) async {
    await init();
    await _prefs.setString(key, jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> loadJsonList(String key) async {
    await init();
    final data = _prefs.getString(key);
    if (data == null || data.isEmpty) return [];
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveValue(String key, String? value) async {
    await init();
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }

  Future<String?> loadValue(String key) async {
    await init();
    return _prefs.getString(key);
  }

  Future<void> clearAll() async {
    await init();
    await _prefs.clear();
  }
}
