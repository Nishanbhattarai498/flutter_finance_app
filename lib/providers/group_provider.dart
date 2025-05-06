import 'package:flutter/material.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:flutter_finance_app/models/group.dart';
import 'package:flutter_finance_app/models/settlement.dart';

class GroupProvider extends ChangeNotifier {
  List<Group> _groups = [];
  List<Settlement> _settlements = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  List<Group> get groups => _groups;
  List<Settlement> get settlements => _settlements;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  Future<void> fetchUserGroups(String userId) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final groupsData = await SupabaseService.getUserGroups(userId);
      _groups = groupsData.map((g) => Group.fromJson(g)).toList();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load groups: ${e.toString()}';
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSettlements(String userId) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final settlementsData = await SupabaseService.getSettlements(userId);
      _settlements = settlementsData
          .map((s) => Settlement.fromJson(s))
          .toList();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load settlements: ${e.toString()}';
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> createGroup(
    Map<String, dynamic> groupData,
    List<String> memberIds,
  ) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      // Create the group
      final groupId = await SupabaseService.createGroup(groupData);

      // Add creator as a member
      await SupabaseService.addMemberToGroup({
        'group_id': groupId,
        'user_id': groupData['created_by'],
        'role': 'admin',
      });

      // Add other members
      for (var memberId in memberIds) {
        await SupabaseService.addMemberToGroup({
          'group_id': groupId,
          'user_id': memberId,
          'role': 'member',
        });
      }

      // Refresh groups after creating a new one
      await fetchUserGroups(groupData['created_by']);

      return {'success': true, 'group_id': groupId};
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to create group: ${e.toString()}';
      debugPrint(_errorMessage);

      _isLoading = false;
      notifyListeners();

      return {'success': false, 'message': _errorMessage};
    }
  }

  Future<bool> addSettlement(Map<String, dynamic> settlementData) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      await SupabaseService.addSettlement(settlementData);

      // Refresh settlements after adding a new one
      if (SupabaseService.currentUser != null) {
        await fetchSettlements(SupabaseService.currentUser!.id);
      }

      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to add settlement: ${e.toString()}';
      debugPrint(_errorMessage);

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  // Calculate balances between users in a group
  Map<String, Map<String, double>> calculateGroupBalances(int groupId) {
    final Map<String, Map<String, double>> balances = {};
    final group = _groups.firstWhere((g) => g.id == groupId);

    // Initialize balances for all members
    for (var member in group.members) {
      balances[member.userId] = {};

      for (var otherMember in group.members) {
        if (member.userId != otherMember.userId) {
          balances[member.userId]![otherMember.userId] = 0;
        }
      }
    }

    // Calculate balances based on expenses
    for (var expense in group.expenses) {
      final payerId = expense.userId;
      final amount = expense.amount;
      final participants = expense.participants;

      if (participants.isEmpty) continue;

      final splitAmount = amount / participants.length;

      for (var participantId in participants) {
        if (participantId == payerId) continue;

        balances[payerId]![participantId] =
            (balances[payerId]![participantId] ?? 0) + splitAmount;
        balances[participantId]![payerId] =
            (balances[participantId]![payerId] ?? 0) - splitAmount;
      }
    }

    return balances;
  }

  // Get simplified debts (optimized settlement plan)
  List<Map<String, dynamic>> getSimplifiedDebts(int groupId) {
    final balances = calculateGroupBalances(groupId);
    final List<Map<String, dynamic>> settlements = [];

    // Convert balances to a list of credits/debits
    final List<Map<String, dynamic>> debts = [];

    balances.forEach((userId, userBalances) {
      userBalances.forEach((otherUserId, amount) {
        if (amount > 0) {
          debts.add({'from': otherUserId, 'to': userId, 'amount': amount});
        }
      });
    });

    // Sort debts by amount (descending)
    debts.sort(
      (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
    );

    // Simplify debts
    while (debts.isNotEmpty) {
      final highestDebt = debts.removeAt(0);

      // Find if there's a reverse debt
      final reverseDebtIndex = debts.indexWhere(
        (debt) =>
            debt['from'] == highestDebt['to'] &&
            debt['to'] == highestDebt['from'],
      );

      if (reverseDebtIndex != -1) {
        final reverseDebt = debts[reverseDebtIndex];

        if (reverseDebt['amount'] > highestDebt['amount']) {
          // Reduce reverse debt by highest debt amount
          reverseDebt['amount'] -= highestDebt['amount'];

          // Add settlement
          settlements.add({
            'payer': highestDebt['from'],
            'receiver': highestDebt['to'],
            'amount': highestDebt['amount'],
          });
        } else {
          // Remove reverse debt
          debts.removeAt(reverseDebtIndex);

          // Add settlement for reverse debt amount
          settlements.add({
            'payer': highestDebt['from'],
            'receiver': highestDebt['to'],
            'amount': reverseDebt['amount'],
          });

          // If there's remaining debt, add it back to the list
          final remainingAmount = highestDebt['amount'] - reverseDebt['amount'];
          if (remainingAmount > 0.01) {
            debts.add({
              'from': highestDebt['from'],
              'to': highestDebt['to'],
              'amount': remainingAmount,
            });

            // Re-sort debts
            debts.sort(
              (a, b) =>
                  (b['amount'] as double).compareTo(a['amount'] as double),
            );
          }
        }
      } else {
        // No reverse debt, just add the settlement
        settlements.add({
          'payer': highestDebt['from'],
          'receiver': highestDebt['to'],
          'amount': highestDebt['amount'],
        });
      }
    }

    return settlements;
  }
}
