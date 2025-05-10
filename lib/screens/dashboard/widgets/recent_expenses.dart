import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/expense.dart';
import 'package:intl/intl.dart';
import 'package:flutter_finance_app/theme/app_theme.dart';

class RecentExpenseItem extends StatelessWidget {
  final Expense expense;

  const RecentExpenseItem({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'NPR ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(expense.category).withOpacity(0.1),
          child: Icon(
            _getCategoryIcon(expense.category),
            color: _getCategoryColor(expense.category),
          ),
        ),
        title: Text(
          expense.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              expense.category,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textColorLight,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, y').format(expense.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textColorLight,
                  ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(expense.amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (expense.isRecurring) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  expense.recurringFrequency ?? 'Monthly',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transportation':
        return Colors.blue;
      case 'shopping':
        return Colors.pink;
      case 'entertainment':
        return Colors.purple;
      case 'bills':
        return Colors.red;
      case 'health':
        return Colors.green;
      case 'education':
        return Colors.teal;
      default:
        return AppTheme.primaryColor;
    }
  }
}
