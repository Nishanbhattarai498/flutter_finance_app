import 'package:flutter/material.dart';
import 'package:flutter_finance_app/providers/budget_provider.dart';
import 'package:flutter_finance_app/screens/budget/budget_setting_screen.dart';
import 'package:provider/provider.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final currentBudget = budgetProvider.currentBudget;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BudgetSettingScreen()),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Budget',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${currentBudget?.monthName ?? ''} ${currentBudget?.year ?? DateTime.now().year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (budgetProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (currentBudget == null)
                const Text('Set your monthly budget to track expenses')
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Budget progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: budgetProvider.budgetUsedPercentage / 100,
                        backgroundColor: Colors.grey[200],
                        color: budgetProvider.remainingBudget >= 0
                            ? Colors.green
                            : Colors.red,
                        minHeight: 8,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Budget'),
                            Text(
                              budgetProvider
                                  .formatAmountNPR(budgetProvider.budgetAmount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Spent'),
                            Text(
                              budgetProvider.formatAmountNPR(
                                  budgetProvider.totalExpenses),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (budgetProvider.budgetAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Remaining budget display
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Remaining'),
                              Text(
                                budgetProvider.formatAmountNPR(
                                    budgetProvider.remainingBudget),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: budgetProvider.remainingBudget >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          // Percentage used
                          Text(
                            '${budgetProvider.budgetUsedPercentage.toStringAsFixed(0)}% used',
                            style: TextStyle(
                              color: budgetProvider.remainingBudget >= 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Warning message when over budget
                      if (budgetProvider.remainingBudget < 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'You have exceeded your monthly budget!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to manage budget',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
