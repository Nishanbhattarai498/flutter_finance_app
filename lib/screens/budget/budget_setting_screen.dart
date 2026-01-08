import 'package:flutter/material.dart';
import 'package:flutter_finance_app/providers/budget_provider.dart';
import 'package:flutter_finance_app/theme/app_theme.dart';
import 'package:flutter_finance_app/widgets/custom_button.dart';
import 'package:flutter_finance_app/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class BudgetSettingScreen extends StatefulWidget {
  const BudgetSettingScreen({Key? key}) : super(key: key);

  @override
  _BudgetSettingScreenState createState() => _BudgetSettingScreenState();
}

class _BudgetSettingScreenState extends State<BudgetSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  bool _isInitialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Initialize data after the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeData();
      });
      _isInitialized = true;
    }
  }

  Future<void> _initializeData() async {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    await budgetProvider.fetchCurrentBudget();

    // Set initial budget value
    if (budgetProvider.currentBudget != null) {
      _budgetController.text = budgetProvider.currentBudget!.amount.toString();
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      final budgetProvider =
          Provider.of<BudgetProvider>(context, listen: false);

      final amount = double.parse(_budgetController.text);
      final success = await budgetProvider.setCurrentMonthBudget(amount);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget updated successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(budgetProvider.errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final currentBudget = budgetProvider.currentBudget;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
              title: const Text('Monthly Budget'),
              backgroundColor: Colors.transparent,
              elevation: 0),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget for ${currentBudget?.monthName ?? ''} ${currentBudget?.year ?? DateTime.now().year}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          if (currentBudget != null)
                            LinearProgressIndicator(
                              value: budgetProvider.budgetUsedPercentage / 100,
                              backgroundColor: Colors.white.withOpacity(0.4),
                              color: budgetProvider.remainingBudget >= 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                              minHeight: 10,
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Current Budget:'),
                              Text(
                                budgetProvider.formatAmountNPR(
                                    budgetProvider.budgetAmount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Spent:'),
                              Text(
                                budgetProvider.formatAmountNPR(
                                    budgetProvider.totalExpenses),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Remaining:'),
                              Text(
                                budgetProvider.formatAmountNPR(
                                    budgetProvider.remainingBudget),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: budgetProvider.remainingBudget >= 0
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          if (budgetProvider.remainingBudget < 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'You have exceeded your budget by ${budgetProvider.formatAmountNPR(budgetProvider.remainingBudget.abs())}',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _budgetController,
                    label: 'Monthly Budget (NPR)',
                    hint: 'Enter your monthly budget',
                    prefixIcon: Icons.attach_money,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a budget amount';
                      }
                      try {
                        final amount = double.parse(value);
                        if (amount < 0) {
                          return 'Budget cannot be negative';
                        }
                      } catch (e) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget Tips',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Set a realistic monthly budget based on your income\n'
                            '• Track your expenses regularly\n'
                            '• Review and adjust your budget as needed\n'
                            '• Try to save at least 20% of your income',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: CustomButton(
                      text: 'Save Budget',
                      isLoading: budgetProvider.isLoading,
                      onPressed: _saveBudget,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
