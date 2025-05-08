import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const String _expensesKey = 'cached_expenses';
  static const String _groupsKey = 'cached_groups';
  static const String _settlementsKey = 'cached_settlements';
  static const String _lastSyncKey = 'last_sync';
  static const Duration _syncInterval = Duration(minutes: 5);

  final SharedPreferences _prefs;

  CacheManager(this._prefs);

  Future<void> cacheData(String key, dynamic data) async {
    await _prefs.setString(key, jsonEncode(data));
    await _updateLastSync();
  }

  Future<dynamic> getCachedData(String key) async {
    final String? dataJson = _prefs.getString(key);
    if (dataJson == null) return null;
    return jsonDecode(dataJson);
  }

  Future<void> cacheExpenses(List<Map<String, dynamic>> expenses) async {
    await cacheData(_expensesKey, expenses);
  }

  Future<void> cacheGroups(List<Map<String, dynamic>> groups) async {
    await cacheData(_groupsKey, groups);
  }

  Future<List<Map<String, dynamic>>?> getCachedExpenses() async {
    final data = await getCachedData(_expensesKey);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>?> getCachedGroups() async {
    final data = await getCachedData(_groupsKey);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> cacheSettlements(List<Map<String, dynamic>> settlements) async {
    await cacheData(_settlementsKey, settlements);
  }

  Future<List<Map<String, dynamic>>?> getCachedSettlements() async {
    final data = await getCachedData(_settlementsKey);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(data);
  }

  Future<DateTime?> getLastSyncTime() async {
    final lastSync = _prefs.getInt(_lastSyncKey) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(lastSync);
  }

  Future<bool> shouldSync() async {
    final lastSync = _prefs.getInt(_lastSyncKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - lastSync > _syncInterval.inMilliseconds;
  }

  Future<void> _updateLastSync() async {
    await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearCache() async {
    await _prefs.remove(_expensesKey);
    await _prefs.remove(_groupsKey);
    await _prefs.remove(_settlementsKey);
    await _prefs.remove(_lastSyncKey);
  }
} 