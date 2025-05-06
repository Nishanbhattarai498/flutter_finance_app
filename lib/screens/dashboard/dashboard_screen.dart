import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/expense.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/expense_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/screens/dashboard/widgets/balance_card.dart';
import 'package:flutter_finance_app/screens/dashboard/widgets/expense_chart.dart';
import 'package:flutter_finance_app/screens/dashboard/widgets/recent_expenses.dart';
import 'package:flutter_finance_app/screens/expenses/add_expense_screen.dart';
import 'package:flutter_finance_app/screens/groups/groups_screen.dart';
import 'package:flutter_finance_app/screens/profile/profile_screen.dart';
import 'package:flutter_finance_app/screens/settlements/settlements_screen.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const _DashboardHomePage(),
    const GroupsScreen(),
    const SettlementsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Settlements',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _DashboardHomePage extends StatefulWidget {
  const _DashboardHomePage({Key? key}) : super(key: key);

  @override
  __DashboardHomePageState createState() => __DashboardHomePageState();
}

class __DashboardHomePageState extends State<_DashboardHomePage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId != null) {
      await Provider.of<ExpenseProvider>(
        context,
        listen: false,
      ).fetchUserExpenses(userId);
      await Provider.of<GroupProvider>(
        context,
        listen: false,
      ).fetchUserGroups(userId);
      await Provider.of<GroupProvider>(
        context,
        listen: false,
      ).fetchSettlements(userId);
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    // Get user's full name from profile
    final String fullName = authProvider.userProfile?['full_name'] ?? 'User';

    // Get the current month's total expenses
    final double currentMonthTotal = expenseProvider.getCurrentMonthTotal();

    // Get all expenses for recent transactions list
    final List<Expense> expenses = expenseProvider.expenses;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: false,
                snap: true,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${fullName.split(' ').first}!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Welcome back to your finance tracker',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // Navigate to notifications screen
                    },
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance card showing monthly spend and remaining budget
                      BalanceCard(
                        spent: currentMonthTotal,
                        budget: 1000.0, // Example budget amount
                      ),
                      const SizedBox(height: 24),

                      // Expense chart showing spending over time
                      Text(
                        'Expense Trend',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ExpenseChart(
                        expenseData: expenseProvider.getMonthlyExpenseTotals(),
                      ),

                      const SizedBox(height: 24),

                      // Recent expenses list
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Expenses',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to all expenses screen
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Recent expenses list
              expenses.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
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
                              'Add your first expense by tapping the + button',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index >= expenses.length) return null;
                        return RecentExpenseItem(expense: expenses[index]);
                      }, childCount: expenses.length > 5 ? 5 : expenses.length),
                    ),

              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
        ),
      ),
    );
  }
}
