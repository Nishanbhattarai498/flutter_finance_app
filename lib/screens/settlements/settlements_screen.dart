import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/settlement.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/screens/settlements/add_settlement_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SettlementsScreen extends StatefulWidget {
  const SettlementsScreen({Key? key}) : super(key: key);

  @override
  _SettlementsScreenState createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends State<SettlementsScreen> {
  @override
  void initState() {
    super.initState();
    _loadSettlements();
  }

  Future<void> _loadSettlements() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId != null) {
      await Provider.of<GroupProvider>(
        context,
        listen: false,
      ).fetchSettlements(userId);
    }
  }

  Future<void> _refreshSettlements() async {
    await _loadSettlements();
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final settlements = groupProvider.settlements;
    final currentUserId = authProvider.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddSettlementScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSettlements,
        child: settlements.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: settlements.length,
                itemBuilder: (context, index) {
                  final settlement = settlements[index];
                  final isUserPayer = settlement.payerId == currentUserId;
                  final isUserReceiver = settlement.receiverId == currentUserId;

                  return _buildSettlementCard(
                    context,
                    settlement,
                    isUserPayer,
                    isUserReceiver,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No settlements yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Record payments between friends to keep track of settlements',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddSettlementScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Settlement'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(
    BuildContext context,
    Settlement settlement,
    bool isUserPayer,
    bool isUserReceiver,
  ) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final dateFormatter = DateFormat('MMM d, yyyy');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleMedium,
                      children: [
                        TextSpan(
                          text: isUserPayer ? 'You' : settlement.payerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' paid '),
                        TextSpan(
                          text: isUserReceiver
                              ? 'you'
                              : settlement.receiverName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  currencyFormatter.format(settlement.amount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUserPayer
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateFormatter.format(settlement.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (settlement.notes != null && settlement.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                settlement.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
