import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/group.dart';
import 'package:flutter_finance_app/models/group_member.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/screens/expenses/add_expense_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;

  const GroupDetailsScreen({Key? key, required this.group}) : super(key: key);

  @override
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    // Load detailed data for the group if needed
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);

    // Calculate balances
    final balances = groupProvider.calculateGroupBalances(widget.group.id);
    final simplifiedDebts = groupProvider.getSimplifiedDebts(widget.group.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to group settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: TabBar(
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Summary'),
                Tab(text: 'Members'),
                Tab(text: 'Expenses'),
              ],
              onTap: (index) {
                setState(() {
                  _currentTab = index;
                });
              },
            ),
          ),

          // Tab content
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                // Summary tab
                _buildSummaryTab(context, balances, simplifiedDebts),

                // Members tab
                _buildMembersTab(context),

                // Expenses tab
                _buildExpensesTab(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryTab(
    BuildContext context,
    Map<String, Map<String, double>> balances,
    List<Map<String, dynamic>> simplifiedDebts,
  ) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userId;

    // Get total expenses for this group
    double totalGroupExpenses = 0;
    if (widget.group.expenses.isNotEmpty) {
      totalGroupExpenses = widget.group.expenses.fold(
        0,
        (sum, expense) => sum + expense.amount,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Group total card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Group Total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormatter.format(totalGroupExpenses),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Simplified settlement plan
        Text(
          'Simplified Settlement Plan',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        if (simplifiedDebts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('All settled up! No payments needed.')),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: simplifiedDebts.length,
            itemBuilder: (context, index) {
              final debt = simplifiedDebts[index];
              final payerId = debt['payer'];
              final receiverId = debt['receiver'];
              final amount = debt['amount'] as double;

              // Find member names
              final payer = widget.group.members.firstWhere(
                (m) => m.userId == payerId,
                orElse: () => GroupMember(
                    userId: '',
                    groupId: '',
                    role: '',
                    displayName: 'Unknown',
                    createdAt: DateTime(1970)),
              );

              final receiver = widget.group.members.firstWhere(
                (m) => m.userId == receiverId,
                orElse: () => GroupMember(
                    userId: '',
                    groupId: '',
                    role: '',
                    displayName: 'Unknown',
                    createdAt: DateTime(1970)),
              );

              final isUserInvolved =
                  (payerId == currentUserId || receiverId == currentUserId);

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: isUserInvolved
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: payerId == currentUserId
                              ? 'You'
                              : payer.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' owes '),
                        TextSpan(
                          text: receiverId == currentUserId
                              ? 'you'
                              : receiver.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  trailing: Text(
                    currencyFormatter.format(amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 24),

        // Individual balances
        Text(
          'Individual Balances',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.group.members.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final member = widget.group.members[index];

              // Calculate net balance
              double netBalance = 0;
              if (balances.containsKey(member.userId)) {
                balances[member.userId]!.forEach((otherUserId, amount) {
                  netBalance += amount;
                });
              }

              final isCurrentUser = member.userId == currentUserId;

              return ListTile(
                leading: CircleAvatar(
                  child: Text(member.displayName.substring(0, 1)),
                ),
                title: Text(
                  isCurrentUser ? 'You' : member.displayName,
                  style: isCurrentUser
                      ? const TextStyle(fontWeight: FontWeight.bold)
                      : null,
                ),
                trailing: Text(
                  currencyFormatter.format(netBalance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: netBalance > 0
                        ? Colors.green
                        : netBalance < 0
                            ? Colors.red
                            : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMembersTab(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.group.members.length,
      itemBuilder: (context, index) {
        final member = widget.group.members[index];
        final isAdmin = member.role == 'admin';

        return ListTile(
          leading: CircleAvatar(
            child: Text(member.displayName.substring(0, 1)),
          ),
          title: Text(member.displayName),
          subtitle: Text(isAdmin ? 'Admin' : 'Member'),
          trailing: isAdmin
              ? Icon(Icons.star, color: Theme.of(context).colorScheme.primary)
              : null,
        );
      },
    );
  }

  Widget _buildExpensesTab(BuildContext context) {
    if (widget.group.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add an expense to split with the group',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.group.expenses.length,
      itemBuilder: (context, index) {
        final expense = widget.group.expenses[index];
        final dateFormatter = DateFormat('MMM d');
        final currencyFormatter = NumberFormat.currency(symbol: '\$');

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            title: Text(expense.description ?? ''),
            subtitle: Text(dateFormatter.format(expense.createdAt)),
            trailing: Text(
              currencyFormatter.format(expense.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
