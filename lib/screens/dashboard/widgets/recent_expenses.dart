import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/expense.dart';
import 'package:flutter_finance_app/screens/expenses/expense_details_screen.dart';
import 'package:flutter_finance_app/providers/expense_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RecentExpenseItem extends StatelessWidget {
  final Expense expense;

  const RecentExpenseItem({Key? key, required this.expense}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final dateFormatter = DateFormat('MMM d');

    // Get category icon
    IconData categoryIcon = Icons.receipt_outlined;
    Color categoryColor = Colors.blue;

    switch (expense.category.toLowerCase()) {
      case 'food':
        categoryIcon = Icons.restaurant_outlined;
        categoryColor = Colors.orange;
        break;
      case 'transport':
        categoryIcon = Icons.directions_car_outlined;
        categoryColor = Colors.green;
        break;
      case 'shopping':
        categoryIcon = Icons.shopping_bag_outlined;
        categoryColor = Colors.purple;
        break;
      case 'entertainment':
        categoryIcon = Icons.movie_outlined;
        categoryColor = Colors.red;
        break;
      case 'bills':
        categoryIcon = Icons.receipt_outlined;
        categoryColor = Colors.blue;
        break;
      case 'healthcare':
        categoryIcon = Icons.medical_services_outlined;
        categoryColor = Colors.teal;
        break;
      case 'travel':
        categoryIcon = Icons.flight_outlined;
        categoryColor = Colors.amber;
        break;
      case 'other':
        categoryIcon = Icons.category_outlined;
        categoryColor = Colors.grey;
        break;
    }

    // Get user name (payer)
    final String payerName = expense.user?['full_name'] ?? 'You';

    // Get group name if it exists
    final String? groupName = expense.group?['name'];

    return ListTile(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExpenseDetailsScreen(expense: expense),
          ),
        );
      },
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: categoryColor.withOpacity(0.2),
            child: Icon(categoryIcon, color: categoryColor),
          ),
          if (expense.isMonthly)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.repeat,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              expense.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (expense.isMonthly)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Tooltip(
                message: 'Monthly Recurring Expense',
                child: Icon(
                  Icons.repeat,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Text(dateFormatter.format(expense.createdAt)),
          if (groupName != null) ...[
            const Text(' • '),
            Expanded(
              child: Text(
                groupName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        expenseProvider.formatAmountNPR(expense.amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
