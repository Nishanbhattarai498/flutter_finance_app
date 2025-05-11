import 'package:flutter/foundation.dart';
import 'package:flutter_finance_app/models/settlement.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:flutter_finance_app/utils/cache_manager.dart';

class SettlementProvider with ChangeNotifier {
  final CacheManager _cacheManager;
  List<Settlement> _settlements = [];
  bool _isLoading = false;
  String? _error;

  SettlementProvider(this._cacheManager);

  List<Settlement> get settlements => _settlements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get errorMessage => _error ?? 'An error occurred';

  Future<void> fetchUserSettlements() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Try to get cached data first
      final cachedSettlements = await _cacheManager.getCachedSettlements();
      if (cachedSettlements != null) {
        _settlements =
            cachedSettlements.map((s) => Settlement.fromJson(s)).toList();
        notifyListeners();
      }

      // Check if we need to sync
      if (await _cacheManager.shouldSync()) {
        final response = await SupabaseService.getUserSettlements();
        _settlements = response.map((s) => Settlement.fromJson(s)).toList();
        await _cacheManager.cacheSettlements(response);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSettlement(Map<String, dynamic> settlementData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
          'SettlementProvider: Creating settlement with data: $settlementData');

      final response = await SupabaseService.createSettlement(settlementData);
      print('SettlementProvider: Settlement creation response: $response');

      final newSettlement = Settlement.fromJson(response);
      _settlements.insert(0, newSettlement);

      // Update cache
      final cachedSettlements =
          await _cacheManager.getCachedSettlements() ?? [];
      cachedSettlements.insert(0, response);
      await _cacheManager.cacheSettlements(cachedSettlements);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('SettlementProvider: Error creating settlement: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSettlement(
      String settlementId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response =
          await SupabaseService.updateSettlement(settlementId, data);
      final updatedSettlement = Settlement.fromJson(response);
      final index = _settlements.indexWhere((s) => s.id == settlementId);
      if (index != -1) {
        _settlements[index] = updatedSettlement;
      }

      // Update cache
      final cachedSettlements =
          await _cacheManager.getCachedSettlements() ?? [];
      final cacheIndex =
          cachedSettlements.indexWhere((s) => s['id'] == settlementId);
      if (cacheIndex != -1) {
        cachedSettlements[cacheIndex] = response;
        await _cacheManager.cacheSettlements(cachedSettlements);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSettlement(String settlementId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await SupabaseService.deleteSettlement(settlementId);
      _settlements.removeWhere((s) => s.id == settlementId);

      // Update cache
      final cachedSettlements =
          await _cacheManager.getCachedSettlements() ?? [];
      cachedSettlements.removeWhere((s) => s['id'] == settlementId);
      await _cacheManager.cacheSettlements(cachedSettlements);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markSettlementAsPaid(String settlementId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      final response = await SupabaseService.updateSettlement(
        settlementId,
        {'status': 'paid'},
      );
      final updatedSettlement = Settlement.fromJson(response);
      final index = _settlements.indexWhere((s) => s.id == settlementId);
      if (index != -1) {
        _settlements[index] = updatedSettlement;
      }

      // Update cache
      final cachedSettlements =
          await _cacheManager.getCachedSettlements() ?? [];
      final cacheIndex =
          cachedSettlements.indexWhere((s) => s['id'] == settlementId);
      if (cacheIndex != -1) {
        cachedSettlements[cacheIndex] = response;
        await _cacheManager.cacheSettlements(cachedSettlements);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<Settlement> getPendingSettlements() {
    return _settlements.where((s) => s.status == 'pending').toList();
  }

  List<Settlement> getCompletedSettlements() {
    return _settlements.where((s) => s.status == 'completed').toList();
  }

  List<Settlement> getSettlementsByGroup(String groupId) {
    return _settlements.where((s) => s.groupId == groupId).toList();
  }

  List<Settlement> getSettlementsByUser(String userId) {
    return _settlements
        .where((s) => s.payerId == userId || s.receiverId == userId)
        .toList();
  }
}
