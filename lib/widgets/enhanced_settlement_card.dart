import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/settlement.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/fixed_settlement_provider_new.dart';
import 'package:provider/provider.dart';
import 'package:flutter_finance_app/theme/app_theme.dart';

class EnhancedSettlementCard extends StatelessWidget {
  final Settlement settlement;

  const EnhancedSettlementCard({
    Key? key,
    required this.settlement,
  }) : super(key: key);

  String _getUserName(Map<String, dynamic>? userData) {
    if (userData == null) {
      return 'Unknown User';
    }
    return userData['full_name'] ?? 'Unknown User';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settlementProvider = Provider.of<FixedSettlementProvider>(context);
    final currentUserId = authProvider.userId;

    final isPayer = settlement.payerId == currentUserId;
    final profitLoss = isPayer ? -settlement.amount : settlement.amount;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPayer ? 'You paid' : 'You received',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'NPR ${settlement.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        // When you paid someone = Green
                        // When you received from someone = Red
                        color: isPayer
                            ? AppTheme.successColor // You paid (green)
                            : AppTheme.errorColor, // You received (red)
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isPayer
                  ? 'To: ${_getUserName(settlement.receiver)}'
                  : 'From: ${_getUserName(settlement.payer)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Net: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'NPR ${profitLoss.abs().toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        // Negative profitLoss = You paid (success/green)
                        // Positive profitLoss = You received/are owed (attention/red)
                        color: profitLoss < 0
                            ? AppTheme.successColor // You paid (green)
                            : AppTheme.errorColor, // You received (red)
                      ),
                ),
                Text(
                  profitLoss < 0 ? ' (paid)' : ' (received)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (settlement.notes != null && settlement.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                settlement.notes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: settlement.status == 'completed'
                            ? AppTheme.successColor.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        settlement.status.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: settlement.status == 'completed'
                                  ? AppTheme.successColor
                                  : Colors.orange,
                            ),
                      ),
                    ),
                    if (settlement.groupId != null &&
                        settlement.group != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${settlement.group!['name'] ?? 'Group'}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _formatDate(settlement.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            // Add action buttons only if settlement is pending
            if (settlement.status != 'completed') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Mark as Paid button
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldMarkAsPaid = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Mark as Paid'),
                              content: Text(
                                  'Are you sure you want to mark this settlement as paid? ' +
                                      'This action cannot be undone and will be visible to both parties.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('CANCEL'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('MARK AS PAID'),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (shouldMarkAsPaid) {
                        final success = await settlementProvider
                            .markSettlementAsPaid(settlement.id);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Settlement marked as paid')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Error: ${settlementProvider.error ?? "Failed to mark as paid"}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('MARK AS PAID'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Settlement'),
                              content: const Text(
                                  'Are you sure you want to delete this settlement?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('CANCEL'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('DELETE'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.errorColor,
                                  ),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (shouldDelete) {
                        final success = await settlementProvider
                            .deleteSettlement(settlement.id);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Settlement deleted')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Error: ${settlementProvider.error ?? "Failed to delete"}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('DELETE'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
