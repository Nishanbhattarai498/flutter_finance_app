import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const String _expensesKey = 'cached_expenses';
  static const String _groupsKey = 'cached_groups';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const Duration _syncInterval = Duration(minutes: 5);

  static Future<void> cacheData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
    await _updateLastSync();
  }

  static Future<dynamic> getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataJson = prefs.getString(key);
    if (dataJson == null) return null;

    return jsonDecode(dataJson);
  }

  static Future<void> cacheExpenses(List<Map<String, dynamic>> expenses) async {
    await cacheData(_expensesKey, expenses);
  }

  static Future<void> cacheGroups(List<Map<String, dynamic>> groups) async {
    await cacheData(_groupsKey, groups);
  }

  static Future<List<Map<String, dynamic>>?> getCachedExpenses() async {
    final data = await getCachedData(_expensesKey);
    if (data == null) return null;

    final List<dynamic> decoded = data;
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>?> getCachedGroups() async {
    final data = await getCachedData(_groupsKey);
    if (data == null) return null;

    final List<dynamic> decoded = data;
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timestamp = prefs.getString(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.parse(timestamp);
  }

  static Future<bool> shouldSync() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;

    final now = DateTime.now();
    return now.difference(lastSync) > _syncInterval;
  }

  static Future<void> _updateLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expensesKey);
    await prefs.remove(_groupsKey);
    await prefs.remove(_lastSyncKey);
  }
} 