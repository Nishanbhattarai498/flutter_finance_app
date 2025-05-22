import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/expense.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/budget_provider.dart';
import 'package:flutter_finance_app/providers/expense_provider.dart';
import 'package:flutter_finance_app/providers/friends_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/providers/fixed_settlement_provider_new.dart'
    as settlement_provider;
import 'package:flutter_finance_app/screens/dashboard/widgets/budget_card.dart';
import 'package:flutter_finance_app/screens/dashboard/widgets/expense_chart.dart';
import 'package:flutter_finance_app/screens/dashboard/widgets/recent_expenses.dart';
import 'package:flutter_finance_app/screens/expenses/add_expense_screen.dart';
import 'package:flutter_finance_app/screens/friends/friends_screen.dart';
import 'package:flutter_finance_app/screens/groups/groups_screen.dart';
import 'package:flutter_finance_app/screens/notifications/notifications_screen.dart';
import 'package:flutter_finance_app/screens/profile/profile_screen.dart';
import 'package:flutter_finance_app/screens/settlements/add_settlement_screen.dart';
import 'package:flutter_finance_app/screens/settlements/enhanced_settlements_screen.dart';
import 'package:flutter_finance_app/screens/settlements/group_settlement_split_screen.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

// Alias for SettlementProvider to avoid confusion
typedef SettlementProvider = settlement_provider.FixedSettlementProvider;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _fabAnimationController;

  final List<Widget> _pages = [
    _DashboardHomePage(),
    GroupsScreen(),
    FriendsScreen(),
    EnhancedSettlementsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        // Main content with transparency
        Scaffold(
          backgroundColor: Colors.transparent,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: IndexedStack(
              key: ValueKey(_currentIndex),
              index: _currentIndex,
              children: _pages,
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: NavigationBar(
                  backgroundColor:
                      Theme.of(context).cardColor.withOpacity(0.92),
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTabChanged,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.group_outlined),
                      selectedIcon: Icon(Icons.group),
                      label: 'Groups',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outlined),
                      selectedIcon: Icon(Icons.people),
                      label: 'Friends',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.swap_horiz_outlined),
                      selectedIcon: Icon(Icons.swap_horiz),
                      label: 'Settlements',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: ScaleTransition(
            scale: _fabAnimationController,
            child: FloatingActionButton(
              onPressed: () => _showAddOptions(context),
              child: const Icon(Icons.add),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        ),
      ],
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.92),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.receipt_long,
                          color: Theme.of(context).primaryColor),
                      title: const Text('Add Expense'),
                      subtitle: const Text('Record a new expense'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToAddExpense(context);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.swap_horiz,
                          color: Theme.of(context).primaryColor),
                      title: const Text('Add Settlement'),
                      subtitle: const Text('Record a new settlement'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToAddSettlement(context);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToAddExpense(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddExpenseScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _navigateToAddSettlement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
}

class _DashboardHomePage extends StatefulWidget {
  const _DashboardHomePage({Key? key}) : super(key: key);

  @override
  State<_DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<_DashboardHomePage> {
  bool _isLoading = true;
  String? _error;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  @override
  void initState() {
    super.initState();
    // Fetch data after the initial build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Clear any existing expenses data first to prevent mixing with another user's data
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);
      expenseProvider.clearExpenses();

      await Future.wait([
        Provider.of<ExpenseProvider>(context, listen: false)
            .fetchUserExpenses(userId),
        Provider.of<GroupProvider>(context, listen: false).fetchUserGroups(),
        Provider.of<SettlementProvider>(context, listen: false)
            .fetchUserSettlements(),
        Provider.of<BudgetProvider>(context, listen: false)
            .fetchCurrentBudget(),
        Provider.of<FriendsProvider>(context, listen: false).loadFriendsData(),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    final String fullName = authProvider.userProfile?['full_name'] ?? 'User';
    final double currentMonthTotal = expenseProvider.getCurrentMonthTotal();
    final double monthlyRecurring = expenseProvider.getTotalMonthlyRecurring();
    final List<Expense> expenses = expenseProvider.expenses;

    return Scaffold(
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _loadData,
        child: SafeArea(
          child: _isLoading
              ? const _LoadingView()
              : _error != null
                  ? _ErrorView(
                      error: _error!,
                      onRetry: _loadData,
                    )
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        _buildAppBar(fullName),
                        SliverPadding(
                          padding: const EdgeInsets.all(16.0),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BudgetCard(
                                  spent: currentMonthTotal,
                                  monthlyRecurring: monthlyRecurring,
                                ),
                                const SizedBox(height: 24),
                                _buildExpenseTrend(expenseProvider),
                                const SizedBox(height: 24),
                                _buildRecentExpensesHeader(),
                              ],
                            ),
                          ),
                        ),
                        _buildExpensesList(expenses),
                        const SliverPadding(
                            padding: EdgeInsets.only(bottom: 80)),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildAppBar(String fullName) {
    return SliverAppBar(
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
        // Notifications icon with badge
        Consumer<FriendsProvider>(
          builder: (context, friendsProvider, _) {
            final unreadCount = friendsProvider.unreadNotificationsCount +
                friendsProvider.friendRequests.length;

            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpenseTrend(ExpenseProvider expenseProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Month Expenses by Category',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ExpenseChart(
          expenseData: expenseProvider.getCurrentMonthExpensesByCategory(),
        ),
      ],
    );
  }

  Widget _buildRecentExpensesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Expenses',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        TextButton(
          onPressed: () {
            // TODO: Navigate to all expenses screen
          },
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildExpensesList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return const SliverFillRemaining(
        child: _EmptyExpensesView(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= expenses.length) return null;
          return RecentExpenseItem(expense: expenses[index]);
        },
        childCount: expenses.length > 5 ? 5 : expenses.length,
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: const CircularProgressIndicator(key: ValueKey('loading')),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({
    Key? key,
    required this.error,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Column(
          key: const ValueKey('error'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyExpensesView extends StatelessWidget {
  const _EmptyExpensesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            'Add your first expense by tapping the + button',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
