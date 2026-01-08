import 'package:flutter/material.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/fixed_settlement_provider_new.dart'
    as settlement_provider;
import 'package:flutter_finance_app/screens/settlements/add_settlement_screen.dart';
import 'package:flutter_finance_app/screens/settlements/group_settlement_split_screen.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

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

    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF26A69A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Settlements'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _navigateToAddSettlement(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).primaryColor,
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
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Card(
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  color: Theme.of(context)
                                      .cardColor
                                      .withOpacity(0.96),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: netBalance >= 0
                                                  ? Colors.green
                                                      .withOpacity(0.2)
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
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                                    '${netBalance >= 0 ? '+' : '-'}\u20b9${netBalance.abs().toStringAsFixed(2)}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          color: netBalance >= 0
                                                              ? Colors.green
                                                              : Colors.red,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text('Total Paid:',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium),
                                                  Text(
                                                    '\u20b9${totalPaid.toStringAsFixed(2)}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text('Total Received:',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium),
                                                  Text(
                                                    '\u20b9${totalReceived.toStringAsFixed(2)}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // They Owe Me Tab
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
                                                        color:
                                                            Colors.grey[700]),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'NPR ${totalOwed.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                            userData['full_name'] ??
                                                'Unknown User';

                                        return Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          elevation: 1,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.all(12),
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  Colors.green[100],
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
                              ),
                        // I Owe Them Tab
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
                                                        color:
                                                            Colors.grey[700]),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'NPR ${totalOwing.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                            userData['full_name'] ??
                                                'Unknown User';

                                        return Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          elevation: 1,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
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
        ),
      ],
    );
  }
}
