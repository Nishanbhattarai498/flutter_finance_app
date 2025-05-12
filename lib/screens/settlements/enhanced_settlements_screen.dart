import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/settlement.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/fixed_settlement_provider_new.dart'
    as settlement_provider;
import 'package:flutter_finance_app/screens/settlements/add_settlement_screen.dart';
import 'package:flutter_finance_app/screens/settlements/group_settlement_split_screen.dart';
import 'package:provider/provider.dart';

// Alias for SettlementProvider to avoid confusion
typedef SettlementProvider = settlement_provider.FixedSettlementProvider;

class EnhancedSettlementsScreen extends StatefulWidget {
  const EnhancedSettlementsScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedSettlementsScreen> createState() =>
      _EnhancedSettlementsScreenState();
}

class _EnhancedSettlementsScreenState extends State<EnhancedSettlementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId != null) {
      await Provider.of<SettlementProvider>(context, listen: false)
          .fetchUserSettlements();
    }
  }

  void _navigateToAddSettlement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.person_outline,
                color: Theme.of(context).primaryColor),
            title: const Text('One-to-One Settlement'),
            subtitle: const Text('Settle with one person'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddSettlementScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.group_outlined,
                color: Theme.of(context).primaryColor),
            title: const Text('Equal Split Settlement'),
            subtitle:
                const Text('Split an amount equally among multiple people'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const GroupSettlementSplitScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settlementProvider = Provider.of<SettlementProvider>(context);
    final settlements = settlementProvider.settlements;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userId;

    // Calculate settlement statistics
    double totalPaid = 0.0;
    double totalReceived = 0.0;
    double totalOwed = 0.0;
    double totalOwing = 0.0;

    // Maps to track balances with individual users
    Map<String, double> balanceByUser = {};
    Map<String, Map<String, dynamic>> userDetailsMap = {};

    for (final settlement in settlements) {
      if (settlement.status == 'completed') {
        continue; // Skip completed settlements for the owing/owed calculations
      }

      if (settlement.payerId == currentUserId) {
        // Current user paid
        totalPaid += settlement.amount;

        // Add to user balance
        String otherUserId = settlement.receiverId;
        balanceByUser[otherUserId] =
            (balanceByUser[otherUserId] ?? 0) - settlement.amount;

        // Store user details
        if (settlement.receiver != null) {
          userDetailsMap[otherUserId] = settlement.receiver!;
        }
      } else if (settlement.receiverId == currentUserId) {
        // Current user received
        totalReceived += settlement.amount;

        // Add to user balance
        String otherUserId = settlement.payerId;
        balanceByUser[otherUserId] =
            (balanceByUser[otherUserId] ?? 0) + settlement.amount;

        // Store user details
        if (settlement.payer != null) {
          userDetailsMap[otherUserId] = settlement.payer!;
        }
      }
    }

    // Calculate total owing and owed based on balances
    balanceByUser.forEach((userId, balance) {
      if (balance > 0) {
        totalOwed += balance; // Money owed to current user
      } else if (balance < 0) {
        totalOwing += balance.abs(); // Money current user owes to others
      }
    });

    double netBalance = totalReceived - totalPaid;

    // Create lists for who owes to and who is owed by the current user
    List<MapEntry<String, double>> usersWhoOweMe = [];
    List<MapEntry<String, double>> usersIowe = [];

    balanceByUser.forEach((userId, balance) {
      if (balance > 0) {
        usersWhoOweMe.add(MapEntry(userId, balance));
      } else if (balance < 0) {
        usersIowe.add(MapEntry(userId, balance.abs()));
      }
    });

    // Sort by amount (higher first)
    usersWhoOweMe.sort((a, b) => b.value.compareTo(a.value));
    usersIowe.sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddSettlement(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'They Owe Me'),
            Tab(text: 'I Owe Them'),
          ],
        ),
      ),
      body: settlementProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : settlements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swap_horiz_outlined,
                        size: 64,
                        color: Colors.grey.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No settlements yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the + button to add your first settlement',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToAddSettlement(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Settlement'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Overview Tab
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          // Updated Summary Card
                          Card(
                            margin: const EdgeInsets.all(16),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: netBalance >= 0
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: netBalance >= 0
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.red.withOpacity(0.2),
                                        child: Icon(
                                          netBalance >= 0
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          size: 16,
                                          color: netBalance >= 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Settlement Summary',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: netBalance >= 0
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Net Balance: ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            Text(
                                              'NPR ${netBalance.abs().toStringAsFixed(2)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    color: netBalance >= 0
                                                        ? Colors.green
                                                        : Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          netBalance >= 0
                                              ? 'Overall, others owe you money'
                                              : 'Overall, you owe others money',
                                          style: TextStyle(
                                            color: netBalance >= 0
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildSummaryItem(
                                        context,
                                        'Total Paid',
                                        totalPaid,
                                        Colors.red,
                                        Icons.arrow_upward,
                                      ),
                                      _buildSummaryItem(
                                        context,
                                        'Total Received',
                                        totalReceived,
                                        Colors.green,
                                        Icons.arrow_downward,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ), // Detailed balance breakdown
                          Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detailed Balance',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      // What people owe you
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color:
                                                  Colors.green.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.arrow_downward,
                                                      size: 14,
                                                      color: Colors.green),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Others Owe You',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'NPR ${totalOwed.toStringAsFixed(2)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              if (usersWhoOweMe.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4),
                                                  child: Text(
                                                    '${usersWhoOweMe.length} ${usersWhoOweMe.length == 1 ? 'person' : 'people'} owe you',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.green[700],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // What you owe others
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color:
                                                  Colors.red.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.arrow_upward,
                                                      size: 14,
                                                      color: Colors.red),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'You Owe Others',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'NPR ${totalOwing.toStringAsFixed(2)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              if (usersIowe.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4),
                                                  child: Text(
                                                    'You owe ${usersIowe.length} ${usersIowe.length == 1 ? 'person' : 'people'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.red[700],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Recent Settlements
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recent Settlements',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ...settlements.take(5).map((settlement) =>
                                    _SettlementCard(settlement: settlement)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ), // They Owe Me Tab
                    usersWhoOweMe.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 48,
                                  color: Colors.grey.withOpacity(0.7),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No one owes you money',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'When others owe you, they will appear here',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.green.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.green[50],
                                          child: Icon(
                                            Icons.arrow_downward,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total money owed to you',
                                                style: TextStyle(
                                                    color: Colors.grey[700]),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'NPR ${totalOwed.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: usersWhoOweMe.length,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemBuilder: (context, index) {
                                    final entry = usersWhoOweMe[index];
                                    final userId = entry.key;
                                    final amount = entry.value;
                                    final userData =
                                        userDetailsMap[userId] ?? {};
                                    final userName =
                                        userData['full_name'] ?? 'Unknown User';

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(12),
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.green[100],
                                          child: Icon(Icons.person,
                                              color: Colors.green),
                                        ),
                                        title: Text(
                                          userName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text('Owes you money'),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'NPR ${amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'incoming',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ), // I Owe Them Tab
                    usersIowe.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 48,
                                  color: Colors.grey.withOpacity(0.7),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'You don\'t owe anyone money',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'When you owe others, they will appear here',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.red.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.red[50],
                                          child: Icon(
                                            Icons.arrow_upward,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total money you owe others',
                                                style: TextStyle(
                                                    color: Colors.grey[700]),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'NPR ${totalOwing.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: usersIowe.length,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemBuilder: (context, index) {
                                    final entry = usersIowe[index];
                                    final userId = entry.key;
                                    final amount = entry.value;
                                    final userData =
                                        userDetailsMap[userId] ?? {};
                                    final userName =
                                        userData['full_name'] ?? 'Unknown User';

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(12),
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.red[100],
                                          child: Icon(Icons.person,
                                              color: Colors.red),
                                        ),
                                        title: Text(
                                          userName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text('You owe money'),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'NPR ${amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'outgoing',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, String title, double amount, Color color,
      [IconData? iconData]) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconData != null) ...[
                Icon(iconData, size: 16, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
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
    return userData['full_name'] ?? userData['email'] ?? 'Unknown User';
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

    // Determine if the user can edit/delete this settlement
    // Allow both payer and receiver to edit/delete
    final canModify = settlement.payerId == currentUserId ||
        settlement.receiverId == currentUserId;
    final isCompleted = settlement.status == 'completed';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: profitLoss >= 0
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPayer
                      ? Colors.red.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  child: Icon(
                    isPayer ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPayer ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPayer ? 'You paid' : 'You received',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          Text(
                            isPayer ? 'To: ' : 'From: ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Expanded(
                            child: Text(
                              isPayer
                                  ? _getUserName(settlement.receiver)
                                  : _getUserName(settlement.payer),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Add explanation of both parties
                      const SizedBox(height: 4),
                      Text(
                        'Between: ${_getUserName(settlement.payer)} → ${_getUserName(settlement.receiver)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'NPR ${settlement.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isPayer ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      isPayer ? 'expense' : 'income',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            if (settlement.notes != null && settlement.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 48.0),
                child: Text(
                  settlement.notes!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48.0),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue,
                            ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(settlement.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Add edit/delete buttons if the user can modify this settlement
            if (canModify && !isCompleted) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 48.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit button
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _showEditSettlementDialog(context, settlement);
                      },
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    TextButton.icon(
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.red.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _showDeleteConfirmation(context, settlement);
                      },
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Settlement settlement) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userId;
    final isPayer = settlement.payerId == currentUserId;
    final otherPartyName = isPayer
        ? _getUserName(settlement.receiver)
        : _getUserName(settlement.payer);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Settlement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Settlement details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPayer
                        ? 'You paid to: $otherPartyName'
                        : 'You received from: $otherPartyName',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NPR ${settlement.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isPayer ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Settlement between: ${_getUserName(settlement.payer)} → ${_getUserName(settlement.receiver)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to delete this settlement? This action cannot be undone.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final settlementProvider = Provider.of<SettlementProvider>(
                  context,
                  listen: false,
                );

                final success =
                    await settlementProvider.deleteSettlement(settlement.id);

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Settlement deleted successfully')),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Failed to delete settlement: ${settlementProvider.errorMessage}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditSettlementDialog(BuildContext context, Settlement settlement) {
    final amountController =
        TextEditingController(text: settlement.amount.toString());
    final notesController = TextEditingController(text: settlement.notes ?? '');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userId;
    final isPayer = settlement.payerId == currentUserId;
    final otherPartyName = isPayer
        ? _getUserName(settlement.receiver)
        : _getUserName(settlement.payer);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Settlement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Settlement details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPayer
                        ? 'You paid to: $otherPartyName'
                        : 'You received from: $otherPartyName',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Settlement between: ${_getUserName(settlement.payer)} → ${_getUserName(settlement.receiver)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                double amount = double.parse(amountController.text);
                if (amount <= 0) {
                  throw 'Amount must be greater than zero';
                }

                Navigator.of(ctx).pop();

                final settlementProvider =
                    Provider.of<SettlementProvider>(context, listen: false);

                final data = {
                  'amount': amount,
                  'notes': notesController.text,
                  'updated_at': DateTime.now().toIso8601String(),
                };

                final success = await settlementProvider.updateSettlement(
                    settlement.id, data);

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Settlement updated successfully')),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Failed to update settlement: ${settlementProvider.errorMessage}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
