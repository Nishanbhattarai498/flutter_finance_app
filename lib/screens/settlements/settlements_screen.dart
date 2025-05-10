import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/settlement.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/settlement_provider.dart';
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
              : ListView.builder(
                  itemCount: settlements.length,
                  itemBuilder: (context, index) {
                    final settlement = settlements[index];
                    return _SettlementCard(settlement: settlement);
                  },
                ),
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userId;

    final isPayer = settlement.payerId == currentUserId;

    return Card(
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
                  ? 'To: ${settlement.receiverId}'
                  : 'From: ${settlement.payerId}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (settlement.notes != null && settlement.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                settlement.notes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  settlement.status.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: settlement.status == 'completed'
                            ? Colors.green
                            : Colors.orange,
                      ),
                ),
                Text(
                  settlement.createdAt.toString().split('.')[0],
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
