import 'package:flutter/material.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:flutter_finance_app/models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  Future<void> fetchUserExpenses(String userId) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final expensesData = await SupabaseService.getUserExpenses(userId);
      _expenses = expensesData.map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load expenses: ${e.toString()}';
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addExpense(Map<String, dynamic> expenseData) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      await SupabaseService.addExpense(expenseData);

      // Refresh expenses after adding a new one
      if (SupabaseService.currentUser != null) {
        await fetchUserExpenses(SupabaseService.currentUser!.id);
      }

      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to add expense: ${e.toString()}';
      debugPrint(_errorMessage);

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  Future<bool> updateExpense(int id, Map<String, dynamic> expenseData) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      await SupabaseService.updateExpense(id, expenseData);

      // Refresh expenses after updating
      if (SupabaseService.currentUser != null) {
        await fetchUserExpenses(SupabaseService.currentUser!.id);
      }

      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to update expense: ${e.toString()}';
      debugPrint(_errorMessage);

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      await SupabaseService.deleteExpense(id);

      // Remove the expense from the local list
      _expenses.removeWhere((expense) => expense.id == id);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to delete expense: ${e.toString()}';
      debugPrint(_errorMessage);

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  // Get total expenses for the current month
  double getCurrentMonthTotal() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    return _expenses
        .where((expense) {
          final expenseDate = expense.createdAt;
          return expenseDate.isAfter(currentMonth) &&
              expenseDate.isBefore(nextMonth);
        })
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  // Get monthly expenses totals for chart
  Map<String, double> getMonthlyExpenseTotals({int monthsCount = 6}) {
    final Map<String, double> monthlyTotals = {};
    final now = DateTime.now();

    for (int i = 0; i < monthsCount; i++) {
      final month = DateTime(now.year, now.month - i);
      final monthName = _getMonthName(month.month);

      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = (month.month < 12)
          ? DateTime(month.year, month.month + 1, 0)
          : DateTime(month.year + 1, 1, 0);

      final total = _expenses
          .where((expense) {
            final date = expense.createdAt;
            return date.isAfter(startOfMonth) &&
                date.isBefore(endOfMonth.add(const Duration(days: 1)));
          })
          .fold(0.0, (sum, expense) => sum + expense.amount);

      monthlyTotals[monthName] = total;
    }

    return monthlyTotals;
  }

  // Get expense categories distribution
  Map<String, double> getCategoryDistribution() {
    final Map<String, double> categories = {};

    for (var expense in _expenses) {
      if (categories.containsKey(expense.category)) {
        categories[expense.category] =
            categories[expense.category]! + expense.amount;
      } else {
        categories[expense.category] = expense.amount;
      }
    }

    return categories;
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return monthNames[month - 1];
  }
}
