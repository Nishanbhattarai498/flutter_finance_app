import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/settlement.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/fixed_settlement_provider.dart';
import 'package:flutter_finance_app/screens/settlements/add_settlement_screen.dart';
import 'package:provider/provider.dart';

class SettlementsScreen extends StatefulWidget {
  const SettlementsScreen({Key? key}) : super(key: key);

  @override
  State<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends State<SettlementsScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId != null) {
      await Provider.of<SettlementProvider>(context, listen: false)
          .fetchUserSettlements();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settlementProvider = Provider.of<SettlementProvider>(context);
    final settlements = settlementProvider.settlements;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userId;

    // Calculate total paid, received, and net balance
    double totalPaid = 0.0;
    double totalReceived = 0.0;

    for (final settlement in settlements) {
      if (settlement.payerId == currentUserId) {
        totalPaid += settlement.amount;
      } else if (settlement.receiverId == currentUserId) {
        totalReceived += settlement.amount;
      }
    }

    double netBalance = totalReceived - totalPaid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddSettlement(context),
          ),
        ],
      ),
      body: settlementProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : settlements.isEmpty
              ? const Center(child: Text('No settlements yet'))
              : Column(
                  children: [
                    // Summary Card
                    Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settlement Summary',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryItem(
                                  context,
                                  'Total Paid',
                                  totalPaid,
                                  Colors.red,
                                ),
                                _buildSummaryItem(
                                  context,
                                  'Total Received',
                                  totalReceived,
                                  Colors.green,
                                ),
                                _buildSummaryItem(
                                  context,
                                  'Net Balance',
                                  netBalance,
                                  netBalance >= 0 ? Colors.green : Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Section title
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 8, bottom: 8),
                      child: Text(
                        'All Settlements',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),

                    // Settlements list
                    Expanded(
                      child: ListView.builder(
                        itemCount: settlements.length,
                        itemBuilder: (context, index) {
                          final settlement = settlements[index];
                          return _SettlementCard(settlement: settlement);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, String title, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'NPR ${amount.abs().toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  void _navigateToAddSettlement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddSettlementScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final Settlement settlement;

  const _SettlementCard({
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
                        color: isPayer ? Colors.red : Colors.green,
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
                        color: profitLoss >= 0 ? Colors.green : Colors.red,
                      ),
                ),
                Text(
                  profitLoss >= 0 ? ' (profit)' : ' (expense)',
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
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        settlement.status.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: settlement.status == 'completed'
                                  ? Colors.green
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
          ],
        ),
      ),
    );
  }
}
