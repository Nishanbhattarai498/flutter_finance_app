import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/expense.dart';
import 'package:flutter_finance_app/screens/expenses/expense_details_screen.dart';
import 'package:intl/intl.dart';

class RecentExpenseItem extends StatelessWidget {
  final Expense expense;

  const RecentExpenseItem({Key? key, required this.expense}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
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
      leading: CircleAvatar(
        backgroundColor: categoryColor.withOpacity(0.2),
        child: Icon(categoryIcon, color: categoryColor),
      ),
      title: Text(
        expense.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
        currencyFormatter.format(expense.amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
