import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseServiceBudget {
  // Budget methods
  static Future<List<Map<String, dynamic>>> getUserBudgets() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      final response = await Supabase.instance.client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .order('month', ascending: false);

      return response;
    } catch (e) {
      throw 'Failed to get user budgets: $e';
    }
  }

  static Future<Map<String, dynamic>> getCurrentMonthBudget() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      // Get current month in YYYY-MM format
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      final monthString =
          '$currentYear-${currentMonth.toString().padLeft(2, '0')}';

      // Try to get the current month's budget or create a new one if it doesn't exist
      final response = await Supabase.instance.client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('month', monthString)
          .maybeSingle();

      if (response != null) {
        return response;
      }

      // If no budget exists for this month, create one
      final newBudget = {
        'user_id': userId,
        'month': monthString,
        'amount': 0.0,
        'currency': 'NPR',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final createdBudgetResponse = await Supabase.instance.client
          .from('budgets')
          .insert(newBudget)
          .select()
          .single();

      return createdBudgetResponse;
    } catch (e) {
      throw 'Failed to get/create current month budget: $e';
    }
  }

  static Future<Map<String, dynamic>> updateBudget(
      String budgetId, double amount) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      final response = await Supabase.instance.client
          .from('budgets')
          .update({
            'amount': amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', budgetId)
          .eq('user_id', userId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw 'Failed to update budget: $e';
    }
  }

  static Future<Map<String, dynamic>> getBudgetSummary(
      String monthString) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      // Parse month string to get year and month
      final parts = monthString.split('-');
      if (parts.length != 2) {
        throw 'Invalid month format. Expected YYYY-MM';
      }

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      // Determine start and end date of the month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of the month

      // Get budget for the specified month
      final budgetResponse = await Supabase.instance.client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('month', monthString)
          .maybeSingle();

      // Budget may not exist yet, create it if needed
      Map<String, dynamic> budget;
      if (budgetResponse == null) {
        final newBudget = {
          'user_id': userId,
          'month': monthString,
          'amount': 0.0,
          'currency': 'NPR',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        budget = await Supabase.instance.client
            .from('budgets')
            .insert(newBudget)
            .select()
            .single();
      } else {
        budget = budgetResponse;
      }

      // Calculate total expenses for the month using the transactions table
      final expensesResponse = await Supabase.instance.client
          .from('expenses')
          .select('amount')
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      // Sum up all expenses for the month
      double totalExpenses = 0.0;
      for (final expense in expensesResponse) {
        totalExpenses += (expense['amount'] ?? 0.0);
      }

      // Calculate remaining budget
      final budgetAmount = budget['amount'] ?? 0.0;
      final remaining = budgetAmount - totalExpenses;

      return {
        'budget': budget,
        'totalExpenses': totalExpenses,
        'remaining': remaining,
      };
    } catch (e) {
      print('Error creating budget in getBudgetSummary: $e');
      throw 'Failed to get budget summary: $e';
    }
  }
}
