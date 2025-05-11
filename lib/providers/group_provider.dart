import 'package:flutter/foundation.dart';
import 'package:flutter_finance_app/models/group.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:flutter_finance_app/utils/cache_manager.dart';

class GroupProvider with ChangeNotifier {
  final CacheManager _cacheManager;
  List<Group> _groups = [];
  bool _isLoading = false;
  String? _error;

  GroupProvider(this._cacheManager);

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get errorMessage => _error ?? 'An error occurred';

  Future<void> fetchUserGroups() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Try to get cached data first
      final cachedGroups = await _cacheManager.getCachedGroups();
      if (cachedGroups != null) {
        _groups = cachedGroups.map((g) => Group.fromJson(g)).toList();
        notifyListeners();
      }

      // Check if we need to sync
      if (await _cacheManager.shouldSync()) {
        final response = await SupabaseService.getUserGroups();
        _groups = response.map((g) => Group.fromJson(g)).toList();
        await _cacheManager.cacheGroups(response);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(Map<String, dynamic> groupData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await SupabaseService.createGroup(groupData);
      final newGroup = Group.fromJson(response);
      _groups.insert(0, newGroup);

      // Update cache
      final cachedGroups = await _cacheManager.getCachedGroups() ?? [];
      cachedGroups.insert(0, response);
      await _cacheManager.cacheGroups(cachedGroups);

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

  Future<bool> updateGroup(String groupId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await SupabaseService.updateGroup(groupId, data);
      final updatedGroup = Group.fromJson(response);
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = updatedGroup;
      }

      // Update cache
      final cachedGroups = await _cacheManager.getCachedGroups() ?? [];
      final cacheIndex = cachedGroups.indexWhere((g) => g['id'] == groupId);
      if (cacheIndex != -1) {
        cachedGroups[cacheIndex] = response;
        await _cacheManager.cacheGroups(cachedGroups);
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

  Future<bool> deleteGroup(String groupId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await SupabaseService.deleteGroup(groupId);
      _groups.removeWhere((g) => g.id == groupId);

      // Update cache
      final cachedGroups = await _cacheManager.getCachedGroups() ?? [];
      cachedGroups.removeWhere((g) => g['id'] == groupId);
      await _cacheManager.cacheGroups(cachedGroups);

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

  Future<bool> addGroupMember(
      String groupId, String userId, String role) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response =
          await SupabaseService.addGroupMember(groupId, userId, role);
      final updatedGroup = Group.fromJson(response);
      _groups = _groups.map((g) => g.id == groupId ? updatedGroup : g).toList();

      // Update cache
      final cachedGroups = await _cacheManager.getCachedGroups() ?? [];
      final cacheIndex = cachedGroups.indexWhere((g) => g['id'] == groupId);
      if (cacheIndex != -1) {
        cachedGroups[cacheIndex] = response;
        await _cacheManager.cacheGroups(cachedGroups);
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

  Future<bool> removeGroupMember(String groupId, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await SupabaseService.removeGroupMember(groupId, userId);
      final updatedGroup = Group.fromJson(response);
      _groups = _groups.map((g) => g.id == groupId ? updatedGroup : g).toList();

      // Update cache
      final cachedGroups = await _cacheManager.getCachedGroups() ?? [];
      final cacheIndex = cachedGroups.indexWhere((g) => g['id'] == groupId);
      if (cacheIndex != -1) {
        cachedGroups[cacheIndex] = response;
        await _cacheManager.cacheGroups(cachedGroups);
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

  Map<String, Map<String, double>> calculateGroupBalances(String groupId) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    final balances = <String, Map<String, double>>{};

    // Initialize balances for all members
    for (final member in group.members) {
      balances[member.userId] = {
        'paid': 0.0,
        'owed': 0.0,
        'balance': 0.0,
      };
    }

    // Calculate balances
    for (final expense in group.expenses) {
      final paidBy = expense.userId;
      final amount = expense.amount;
      final perPerson = amount / expense.participants.length;

      // Update paid amount
      balances[paidBy]!['paid'] = (balances[paidBy]!['paid'] ?? 0) + amount;

      // Update owed amount for each participant
      for (final participantId in expense.participants) {
        if (participantId != paidBy) {
          balances[participantId]!['owed'] =
              (balances[participantId]!['owed'] ?? 0) + perPerson;
        }
      }
    }

    // Calculate final balance for each member
    for (final memberId in balances.keys) {
      final paid = balances[memberId]!['paid'] ?? 0;
      final owed = balances[memberId]!['owed'] ?? 0;
      balances[memberId]!['balance'] = paid - owed;
    }

    return balances;
  }

  List<Map<String, dynamic>> getSimplifiedDebts(String groupId) {
    final balances = calculateGroupBalances(groupId);
    final debtors = <String, double>{};
    final creditors = <String, double>{};

    // Separate debtors and creditors
    balances.forEach((memberId, balance) {
      final amount = balance['balance'] ?? 0;
      if (amount < 0) {
        debtors[memberId] = -amount;
      } else if (amount > 0) {
        creditors[memberId] = amount;
      }
    });

    final settlements = <Map<String, dynamic>>[];

    // Calculate simplified debts
    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      final debtor = debtors.entries.first;
      final creditor = creditors.entries.first;

      final amount =
          debtor.value < creditor.value ? debtor.value : creditor.value;

      settlements.add({
        'from': debtor.key,
        'to': creditor.key,
        'amount': amount,
      });

      if (debtor.value == amount) {
        debtors.remove(debtor.key);
      } else {
        debtors[debtor.key] = debtor.value - amount;
      }

      if (creditor.value == amount) {
        creditors.remove(creditor.key);
      } else {
        creditors[creditor.key] = creditor.value - amount;
      }
    }

    return settlements;
  }
}
