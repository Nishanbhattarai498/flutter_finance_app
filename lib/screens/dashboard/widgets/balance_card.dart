import 'package:flutter/material.dart';
import 'package:flutter_finance_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class BalanceCard extends StatelessWidget {
  final double spent;
  final double budget;
  final double monthlyRecurring;

  const BalanceCard({
    Key? key,
    required this.spent,
    required this.budget,
    required this.monthlyRecurring,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remaining = budget - spent;
    final progress = spent / budget;
    final currencyFormat = NumberFormat.currency(symbol: 'NPR ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Budget',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountColumn(
                  context,
                  'Spent',
                  currencyFormat.format(spent),
                  AppTheme.errorColor,
                ),
                _buildAmountColumn(
                  context,
                  'Remaining',
                  currencyFormat.format(remaining),
                  AppTheme.successColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppTheme.primaryColorLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 1.0 ? AppTheme.errorColor : AppTheme.primaryColor,
                ),
                minHeight: 8,
              ),
            ),
            if (monthlyRecurring > 0) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.repeat,
                    size: 16,
                    color: AppTheme.textColorLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Monthly Recurring: ${currencyFormat.format(monthlyRecurring)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountColumn(
    BuildContext context,
    String label,
    String amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
