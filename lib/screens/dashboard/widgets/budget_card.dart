import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_finance_app/providers/budget_provider.dart';
import 'package:flutter_finance_app/screens/budget/budget_setting_screen.dart';
import 'package:provider/provider.dart';

class BudgetCard extends StatelessWidget {
  final double? spent;
  final double? monthlyRecurring;

  const BudgetCard({
    Key? key,
    this.spent,
    this.monthlyRecurring,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final currentBudget = budgetProvider.currentBudget;

    // Use the passed spent value if provided, otherwise use the one from provider
    final totalExpenses = spent ?? budgetProvider.totalExpenses;
    final double budgetAmount = budgetProvider.budgetAmount;
    final double remainingBudget = budgetAmount - totalExpenses;
    final double budgetUsedPercentage = budgetAmount > 0
        ? (totalExpenses / budgetAmount * 100).clamp(0.0, 200.0)
        : 0.0;
        
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BudgetSettingScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
            width: 1,
          ),
          color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Budget',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentBudget?.monthName ?? ''} ${currentBudget?.year ?? DateTime.now().year}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (budgetProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (currentBudget == null)
                    const Text('Set your monthly budget to track expenses')
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${budgetUsedPercentage.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: remainingBudget >= 0 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                            Text(
                              'of ${budgetProvider.formatAmountNPR(budgetAmount)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: budgetUsedPercentage / 100,
                            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                            color: remainingBudget >= 0 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).colorScheme.error,
                            minHeight: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBudgetInfoItem(
                              context, 
                              'Spent', 
                              budgetProvider.formatAmountNPR(totalExpenses),
                              isDark,
                            ),
                            _buildBudgetInfoItem(
                              context, 
                              'Remaining', 
                              budgetProvider.formatAmountNPR(remainingBudget),
                              isDark,
                              valueColor: remainingBudget >= 0 
                                  ? Theme.of(context).colorScheme.primary 
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ],
                        ),
                        if (remainingBudget < 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 16, color: Theme.of(context).colorScheme.error),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Budget exceeded!',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetInfoItem(BuildContext context, String label, String value, bool isDark, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
