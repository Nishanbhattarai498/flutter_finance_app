import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/expense.dart';
import 'package:flutter_finance_app/providers/expense_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ExpenseDetailsScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailsScreen({Key? key, required this.expense})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final dateFormatter = DateFormat('MMMM d, yyyy');

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Navigate to edit expense screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showDeleteDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expense header with amount
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Category icon
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: categoryColor.withOpacity(0.2),
                      child: Icon(categoryIcon, color: categoryColor, size: 32),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      expense.description,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Amount
                    Text(
                      currencyFormatter.format(expense.amount),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),

                    // Date and category
                    Text(
                      '${dateFormatter.format(expense.createdAt)} • ${expense.category}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payer info
            _buildInfoCard(
              context,
              'Paid by',
              expense.user?['full_name'] ?? 'Unknown',
              Icons.person_outline,
            ),
            const SizedBox(height: 16),

            // Group info (if any)
            if (expense.group != null)
              _buildInfoCard(
                context,
                'Group',
                expense.group!['name'],
                Icons.group_outlined,
              ),
            if (expense.group != null) const SizedBox(height: 16),

            // Participants
            if (expense.participants.isNotEmpty) ...[
              const Text(
                'Split with:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expense.participants.length,
                  itemBuilder: (context, index) {
                    final participantId = expense.participants[index];

                    // Find participant name if group is available
                    String participantName = 'Unknown';
                    if (expense.group != null) {
                      final member = (expense.group!['members'] as List?)
                          ?.firstWhere(
                            (m) => m['user_id'] == participantId,
                            orElse: () => null,
                          );

                      if (member != null && member['user'] != null) {
                        participantName = member['user']['full_name'];
                      }
                    }

                    // Calculate split amount
                    final splitAmount =
                        expense.amount / expense.participants.length;

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(participantName),
                      trailing: Text(
                        currencyFormatter.format(splitAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete the expense
      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );
      final success = await expenseProvider.deleteExpense(expense.id);

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Expense deleted')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(expenseProvider.errorMessage)));
      }
    }
  }
}
