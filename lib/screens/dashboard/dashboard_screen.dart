import 'dart:ui';
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
import 'package:flutter_finance_app/theme/app_theme.dart';
import 'package:provider/provider.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Animated Gradient Background
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppTheme.darkSurfaceGradient
                : AppTheme.primaryGradient,
          ),
        ),
        // Decorative Circles for depth
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),

        // Main content
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
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).cardTheme.color?.withOpacity(0.8) ??
                            Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: NavigationBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _onTabChanged,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard_rounded),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.group_outlined),
                        selectedIcon: Icon(Icons.group_rounded),
                        label: 'Groups',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.people_outlined),
                        selectedIcon: Icon(Icons.people_rounded),
                        label: 'Friends',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.swap_horiz_outlined),
                        selectedIcon: Icon(Icons.swap_horiz_rounded),
                        label: 'Settle',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person_rounded),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: ScaleTransition(
            scale: _fabAnimationController,
            child: FloatingActionButton(
              onPressed: () => _showAddOptions(context),
              elevation: 4,
              backgroundColor: AppTheme.primaryColor,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
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
    final budgetProvider = Provider.of<BudgetProvider>(context);

    final String fullName = authProvider.userProfile?['full_name'] ?? 'User';
    final double currentMonthTotal = expenseProvider.getCurrentMonthTotal();
    final double monthlyRecurring = expenseProvider.getTotalMonthlyRecurring();
    final double budgetAmount = budgetProvider.budgetAmount;
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
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeroHeader(
                                  fullName: fullName,
                                  spent: currentMonthTotal,
                                  recurring: monthlyRecurring,
                                  budget: budgetAmount,
                                ),
                                const SizedBox(height: 16),
                                _buildQuickActions(context),
                                const SizedBox(height: 20),
                                BudgetCard(
                                  spent: currentMonthTotal,
                                  monthlyRecurring: monthlyRecurring,
                                ),
                                const SizedBox(height: 20),
                                _buildExpenseTrend(expenseProvider),
                                const SizedBox(height: 20),
                                _buildRecentExpensesHeader(),
                              ],
                            ),
                          ),
                        ),
                        _buildExpensesList(expenses),
                        const SliverPadding(
                            padding: EdgeInsets.only(bottom: 96)),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Insights',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: const [
                Icon(Icons.pie_chart_rounded, size: 18),
                SizedBox(width: 6),
                Text('Monthly breakdown'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ExpenseChart(
          expenseData: expenseProvider.getCurrentMonthExpensesByCategory(),
        ),
      ],
    );
  }

  Widget _buildHeroHeader({
    required String fullName,
    required double spent,
    required double recurring,
    required double budget,
  }) {
    final remaining = budget - spent;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hey ${fullName.split(' ').first}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Let’s keep spending intentional.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.blur_on_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroStat(
                label: 'Spent this month',
                value: 'NPR ${spent.toStringAsFixed(0)}',
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              _heroStat(
                label: 'Remaining',
                value: 'NPR ${remaining.toStringAsFixed(0)}',
                color: remaining >= 0 ? Colors.white : AppTheme.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pillTag(Icons.repeat_rounded,
                  'Recurring: NPR ${recurring.toStringAsFixed(0)}'),
              _pillTag(Icons.account_balance_wallet_rounded,
                  'Budget: NPR ${budget.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(
      {required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final cards = [
      _QuickAction(
        icon: Icons.add_circle_outline,
        label: 'Expense',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
        color: AppTheme.primaryColor,
      ),
      _QuickAction(
        icon: Icons.swap_horiz_rounded,
        label: 'Settlement',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddSettlementScreen()),
          );
        },
        color: AppTheme.secondaryColor,
      ),
      _QuickAction(
        icon: Icons.groups_2_rounded,
        label: 'Groups',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GroupsScreen()),
          );
        },
        color: AppTheme.accentColor,
      ),
    ];

    return Row(
      children: cards
          .map((card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: card,
                ),
              ))
          .toList(),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          gradient:
              isDark ? AppTheme.glassGradientDark : AppTheme.glassGradientLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.20),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.14),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
