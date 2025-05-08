import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/expense.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:flutter_finance_app/utils/cache_manager.dart';
import 'package:intl/intl.dart';

class ExpenseProvider with ChangeNotifier {
  final SupabaseService _supabaseService;
  final CacheManager _cacheManager;
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  ExpenseProvider(this._supabaseService, this._cacheManager);

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get errorMessage => _error ?? 'An error occurred';

  Future<void> fetchUserExpenses(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Try to get cached data first
      final cachedExpenses = await _cacheManager.getCachedExpenses();
      if (cachedExpenses != null) {
        _expenses = cachedExpenses.map((e) => Expense.fromJson(e)).toList();
        notifyListeners();
      }

      // Check if we need to sync
      if (await _cacheManager.shouldSync()) {
        final response = await _supabaseService.getUserExpenses();
        _expenses = response.map((e) => Expense.fromJson(e)).toList();
        await _cacheManager.cacheExpenses(response);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(Map<String, dynamic> expenseData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabaseService.createExpense(expenseData);
      final newExpense = Expense.fromJson(response);
      _expenses.insert(0, newExpense);

      // Update cache
      final cachedExpenses = await _cacheManager.getCachedExpenses() ?? [];
      cachedExpenses.insert(0, response);
      await _cacheManager.cacheExpenses(cachedExpenses);

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

  Future<bool> updateExpense(String expenseId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabaseService.updateExpense(expenseId, data);
      final updatedExpense = Expense.fromJson(response);
      final index = _expenses.indexWhere((e) => e.id == expenseId);
      if (index != -1) {
        _expenses[index] = updatedExpense;
      }

      // Update cache
      final cachedExpenses = await _cacheManager.getCachedExpenses() ?? [];
      final cacheIndex = cachedExpenses.indexWhere((e) => e['id'] == expenseId);
      if (cacheIndex != -1) {
        cachedExpenses[cacheIndex] = response;
        await _cacheManager.cacheExpenses(cachedExpenses);
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

  Future<bool> deleteExpense(String expenseId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabaseService.deleteExpense(expenseId);
      _expenses.removeWhere((e) => e.id == expenseId);

      // Update cache
      final cachedExpenses = await _cacheManager.getCachedExpenses() ?? [];
      cachedExpenses.removeWhere((e) => e['id'] == expenseId);
      await _cacheManager.cacheExpenses(cachedExpenses);

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

  double getCurrentMonthTotal() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return _expenses
        .where((expense) {
          final expenseDate = expense.date;
          return !expense.isMonthly &&
              expenseDate.isAfter(firstDayOfMonth) &&
              expenseDate.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
        })
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double getTotalMonthlyRecurring() {
    return _expenses
        .where((expense) => expense.isMonthly)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  List<Map<String, dynamic>> getMonthlyExpenseTotals() {
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      return {
        'date': date,
        'amount': _expenses
            .where((expense) {
              final expenseDate = expense.date;
              return !expense.isMonthly &&
                  expenseDate.year == date.year &&
                  expenseDate.month == date.month;
            })
            .fold(0.0, (sum, expense) => sum + expense.amount),
      };
    }).reversed.toList();

    return months;
  }

  String formatAmountNPR(double amount) {
    return NumberFormat.currency(symbol: 'NPR ').format(amount);
  }
}
