import 'package:flutter/foundation.dart';
import 'package:flutter_finance_app/models/budget.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:intl/intl.dart';

class BudgetProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;

  bool _isLoading = false;
  String _errorMessage = '';
  Budget? _currentBudget;
  List<Budget> _budgets = [];
  Map<String, dynamic> _currentSummary = {
    'budget': null,
    'totalExpenses': 0.0,
    'remaining': 0.0
  };

  BudgetProvider(this._supabaseService);

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
      final budgetData = await _supabaseService.getCurrentMonthBudget();
      _currentBudget = Budget.fromMap(budgetData);

      await fetchBudgetSummary(_currentBudget!.month, _currentBudget!.year);

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
      final budgetsData = await _supabaseService.getUserBudgets();
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
      final budgetData = await _supabaseService.updateBudget(budgetId, amount);

      // Update current budget if it's the one being modified
      if (_currentBudget != null && _currentBudget!.id == budgetId) {
        _currentBudget = Budget.fromMap(budgetData);
        // Refresh summary with new budget amount
        await fetchBudgetSummary(_currentBudget!.month, _currentBudget!.year);
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

  // Fetch budget summary for a specific month/year
  Future<void> fetchBudgetSummary(int month, int year) async {
    try {
      _currentSummary = await _supabaseService.getBudgetSummary(month, year);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Set budget for current month
  Future<bool> setCurrentMonthBudget(double amount) async {
    if (_currentBudget == null) {
      await fetchCurrentBudget();
    }

    if (_currentBudget != null) {
      return await updateBudget(_currentBudget!.id, amount);
    }

    return false;
  }
}
