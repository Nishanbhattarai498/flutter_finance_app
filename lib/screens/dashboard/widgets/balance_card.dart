import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceCard extends StatelessWidget {
  final double spent;
  final double budget;

  const BalanceCard({Key? key, required this.spent, required this.budget})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final percentage = (spent / budget).clamp(0.0, 1.0);
    final remaining = budget - spent;

    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$monthName Budget',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spent', style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      currencyFormatter.format(spent),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      currencyFormatter.format(remaining),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: remaining < 0
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 0.9
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(percentage * 100).round()}% of budget used',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
