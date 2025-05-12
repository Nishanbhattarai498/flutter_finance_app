import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/expense.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:flutter_finance_app/utils/cache_manager.dart';
import 'package:intl/intl.dart';

class ExpenseProvider with ChangeNotifier {
  final CacheManager _cacheManager;
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  ExpenseProvider(this._cacheManager);

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get errorMessage => _error ?? 'An error occurred';

  // Clear all expenses - use before fetching a different user's expenses
  void clearExpenses() {
    _expenses = [];
    notifyListeners();
  }

  Future<void> fetchUserExpenses(String userId) async {
    try {
      _isLoading = true;
      _error = null;

      // Clear any existing expenses to prevent mixing data between users
      _expenses = [];
      notifyListeners();

      // Only use cache if the current user matches the requested user ID
      final currentUser = SupabaseService.currentUser;
      final isSameUser = currentUser != null && currentUser.id == userId;

      if (isSameUser) {
        // Try to get cached data only for the current user
        final cachedExpenses = await _cacheManager.getCachedExpenses();
        if (cachedExpenses != null) {
          // Filter expenses to ensure they belong to the current user
          final filteredExpenses =
              cachedExpenses.where((e) => e['user_id'] == userId).toList();

          _expenses = filteredExpenses.map((e) => Expense.fromJson(e)).toList();
          notifyListeners();
        }

        // Check if we need to sync with the server
        if (await _cacheManager.shouldSync()) {
          final response = await SupabaseService.getUserExpenses();
          _expenses = response.map((e) => Expense.fromJson(e)).toList();
          await _cacheManager.cacheExpenses(response);
        }
      } else {
        // For non-current users, we should have a different method that gets expenses by user ID
        // This would require a new Supabase service method
        _expenses = []; // Clear expenses if not the current user
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

      final response = await SupabaseService.createExpense(expenseData);
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

  Future<bool> updateExpense(
      String expenseId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await SupabaseService.updateExpense(expenseId, data);
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

      await SupabaseService.deleteExpense(expenseId);
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

    return _expenses.where((expense) {
      final expenseDate = expense.date;
      return !expense.isMonthly &&
          expenseDate.isAfter(firstDayOfMonth) &&
          expenseDate.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
    }).fold(0, (sum, expense) => sum + expense.amount);
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
        'amount': _expenses.where((expense) {
          final expenseDate = expense.date;
          return !expense.isMonthly &&
              expenseDate.year == date.year &&
              expenseDate.month == date.month;
        }).fold(0.0, (sum, expense) => sum + expense.amount),
      };
    }).reversed.toList();

    return months;
  }

  /// Returns a list of expenses grouped by category for the current month
  List<Map<String, dynamic>> getCurrentMonthExpensesByCategory() {
    final now = DateTime.now();
    final Map<String, double> categoryTotals = {};

    // Filter expenses for the current month
    final currentMonthExpenses = _expenses.where((expense) {
      return expense.date.month == now.month && expense.date.year == now.year;
    }).toList();

    // Group by category
    for (var expense in currentMonthExpenses) {
      final category = expense.category;
      if (categoryTotals.containsKey(category)) {
        categoryTotals[category] = categoryTotals[category]! + expense.amount;
      } else {
        categoryTotals[category] = expense.amount;
      }
    }

    // Convert to list of maps
    return categoryTotals.entries.map((entry) {
      return {
        'category': entry.key,
        'amount': entry.value,
      };
    }).toList();
  }

  String formatAmountNPR(double amount) {
    return NumberFormat.currency(symbol: 'NPR ').format(amount);
  }
}
