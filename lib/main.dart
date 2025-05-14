import 'package:flutter/material.dart';
// Import providers directly instead of through the models/providers.dart file
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/budget_provider.dart';
import 'package:flutter_finance_app/providers/expense_provider.dart';
import 'package:flutter_finance_app/providers/friends_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/providers/fixed_settlement_provider_new.dart';
import 'package:flutter_finance_app/providers/theme_provider.dart';
import 'package:flutter_finance_app/screens/auth/login_screen.dart';
import 'package:flutter_finance_app/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:flutter_finance_app/theme/app_theme.dart';
import 'package:flutter_finance_app/utils/cache_manager.dart';
import 'package:flutter_finance_app/utils/font_loader.dart';
import 'package:provider/provider.dart';
import 'package:flutter_finance_app/widgets/loading_screen.dart';
import 'package:flutter_finance_app/secrets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload assets to avoid loading issues
  try {
    // We'll preload assets later in the app lifecycle when we have a BuildContext
    print('✅ Ready to load assets');
  } catch (e) {
    print('⚠️ Error preloading assets: $e');
    // Continue anyway, we'll use fallbacks if needed
  }

  // Load Noto fonts for better character support
  await FontLoader.preloadFonts();

  // Initialize Supabase
  await SupabaseService.initialize(
    supabaseUrl: Secrets.supabaseUrl,
    supabaseAnonKey: Secrets.supabaseAnonKey,
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final cacheManager = CacheManager(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(cacheManager),
        ),
        ChangeNotifierProvider(
          create: (_) => GroupProvider(cacheManager),
        ),
        ChangeNotifierProvider(
          create: (context) => FixedSettlementProvider(
            cacheManager,
            Provider.of<AuthProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => FriendsProvider(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Provider.of<AuthProvider>(context, listen: false).checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const LoadingScreen(message: 'Starting up...');
          }

          if (authProvider.isAuthenticated) {
            return const DashboardScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
