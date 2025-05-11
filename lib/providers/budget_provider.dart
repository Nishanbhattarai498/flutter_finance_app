import 'package:flutter/foundation.dart';
import 'package:flutter_finance_app/models/budget.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:intl/intl.dart';

class BudgetProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  Budget? _currentBudget;
  List<Budget> _budgets = [];
  Map<String, dynamic> _currentSummary = {
    'budget': null,
    'totalExpenses': 0.0,
    'remaining': 0.0
  };

  BudgetProvider();

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Budget? get currentBudget => _currentBudget;
  List<Budget> get budgets => _budgets;
  Map<String, dynamic> get currentSummary => _currentSummary;

  double get totalExpenses => _currentSummary['totalExpenses'] ?? 0.0;
  double get budgetAmount => _currentBudget?.amount ?? 0.0;
  double get remainingBudget => _currentSummary['remaining'] ?? 0.0;

  // Percentage of budget used (0-100)
  double get budgetUsedPercentage {
    if (_currentBudget == null || _currentBudget!.amount <= 0) return 100.0;
    double percentage = (totalExpenses / _currentBudget!.amount) * 100;
    return percentage.clamp(0.0, 100.0);
  }

  // Format amount in NPR
  String formatAmountNPR(double amount) {
    return NumberFormat.currency(symbol: 'NPR ', decimalDigits: 2)
        .format(amount);
  }

  // Fetch current month's budget
  Future<void> fetchCurrentBudget() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      // Get the current month's budget data
      final budgetData = await SupabaseService.getCurrentMonthBudget();
      _currentBudget = Budget.fromMap(budgetData);

      // Get expense summary for this budget period
      await fetchBudgetSummary(_currentBudget!.monthString);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Fetch all user budgets
  Future<void> fetchAllBudgets() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final budgetsData = await SupabaseService.getUserBudgets();
      _budgets = budgetsData.map((data) => Budget.fromMap(data)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update budget amount
  Future<bool> updateBudget(String budgetId, double amount) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final budgetData = await SupabaseService.updateBudget(budgetId, amount);

      // Update current budget if it's the one being modified
      if (_currentBudget != null && _currentBudget!.id == budgetId) {
        _currentBudget = Budget.fromMap(budgetData);
        // Refresh summary with new budget amount
        await fetchBudgetSummary(_currentBudget!.monthString);
      }

      // Update the budget in the list if it exists
      final index = _budgets.indexWhere((b) => b.id == budgetId);
      if (index >= 0) {
        _budgets[index] = Budget.fromMap(budgetData);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Fetch budget summary for a specific month
  Future<void> fetchBudgetSummary(String month) async {
    try {
      _currentSummary = await SupabaseService.getBudgetSummary(month);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Set budget for current month
  Future<bool> setCurrentMonthBudget(double amount) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // If no current budget exists, fetch it first
      if (_currentBudget == null) {
        await fetchCurrentBudget();
      }

      // If we have a current budget, update it
      if (_currentBudget != null) {
        final result = await updateBudget(_currentBudget!.id, amount);
        _isLoading = false;
        notifyListeners();
        return result;
      } else {
        // This should rarely happen since fetchCurrentBudget creates a budget if none exists
        _isLoading = false;
        _errorMessage = 'Could not set budget: No budget record found';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
