import 'package:flutter/foundation.dart';
import 'package:flutter_finance_app/models/settlement.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:flutter_finance_app/utils/cache_manager.dart';

class SettlementProvider with ChangeNotifier {
  final SupabaseService _supabaseService;
  final CacheManager _cacheManager;
  List<Settlement> _settlements = [];
  bool _isLoading = false;
  String? _error;

  SettlementProvider(this._supabaseService, this._cacheManager);

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
      final cachedSettlements = await _cacheManager.getCachedData('user_settlements');
      if (cachedSettlements != null) {
        _settlements = (cachedSettlements as List)
            .map((s) => Settlement.fromJson(s))
            .toList();
        notifyListeners();
      }

      // Check if we need to sync
      if (await _cacheManager.shouldSync()) {
        final response = await _supabaseService.getUserSettlements();
        _settlements = response.map((s) => Settlement.fromJson(s)).toList();
        await _cacheManager.cacheData('user_settlements', response);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSettlement({
    required double amount,
    required String payerId,
    required String receiverId,
    String? groupId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabaseService.createSettlement(
        amount: amount,
        payerId: payerId,
        receiverId: receiverId,
        groupId: groupId,
      );
      final newSettlement = Settlement.fromJson(response);
      _settlements.add(newSettlement);

      // Update cache
      final cachedSettlements = await _cacheManager.getCachedData('user_settlements') ?? [];
      cachedSettlements.add(response);
      await _cacheManager.cacheData('user_settlements', cachedSettlements);

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

  Future<bool> updateSettlementStatus(String settlementId, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabaseService.updateSettlementStatus(settlementId, status);
      final updatedSettlement = Settlement.fromJson(response);
      _settlements = _settlements.map((s) => s.id == settlementId ? updatedSettlement : s).toList();

      // Update cache
      final cachedSettlements = await _cacheManager.getCachedData('user_settlements') ?? [];
      final cacheIndex = cachedSettlements.indexWhere((s) => s['id'] == settlementId);
      if (cacheIndex != -1) {
        cachedSettlements[cacheIndex] = response;
        await _cacheManager.cacheData('user_settlements', cachedSettlements);
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

      await _supabaseService.deleteSettlement(settlementId);
      _settlements.removeWhere((s) => s.id == settlementId);

      // Update cache
      final cachedSettlements = await _cacheManager.getCachedData('user_settlements') ?? [];
      cachedSettlements.removeWhere((s) => s['id'] == settlementId);
      await _cacheManager.cacheData('user_settlements', cachedSettlements);

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