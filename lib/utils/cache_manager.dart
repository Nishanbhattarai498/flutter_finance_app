import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';

class CacheManager {
  static const String _expensesKey = 'cached_expenses';
  static const String _groupsKey = 'cached_groups';
  static const String _settlementsKey = 'cached_settlements';
  static const String _lastSyncKey = 'last_sync';
  static const Duration _syncInterval = Duration(minutes: 5);

  final SharedPreferences _prefs;

  CacheManager(this._prefs);

  // Get the user-specific key for better caching
  String _getUserSpecificKey(String baseKey) {
    final user = SupabaseService.currentUser;
    return user != null ? '${baseKey}_${user.id}' : baseKey;
  }

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
    final key = _getUserSpecificKey(_expensesKey);
    await cacheData(key, expenses);
  }

  Future<void> cacheGroups(List<Map<String, dynamic>> groups) async {
    final key = _getUserSpecificKey(_groupsKey);
    await cacheData(key, groups);
  }

  Future<List<Map<String, dynamic>>?> getCachedExpenses() async {
    final key = _getUserSpecificKey(_expensesKey);
    final data = await getCachedData(key);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>?> getCachedGroups() async {
    final key = _getUserSpecificKey(_groupsKey);
    final data = await getCachedData(key);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> cacheSettlements(List<Map<String, dynamic>> settlements) async {
    final key = _getUserSpecificKey(_settlementsKey);
    await cacheData(key, settlements);
  }

  Future<List<Map<String, dynamic>>?> getCachedSettlements() async {
    final key = _getUserSpecificKey(_settlementsKey);
    final data = await getCachedData(key);
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
