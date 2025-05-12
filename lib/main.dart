import 'package:flutter/material.dart';
// Import providers directly instead of through the models/providers.dart file
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/budget_provider.dart';
import 'package:flutter_finance_app/providers/expense_provider.dart';
import 'package:flutter_finance_app/providers/friends_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/providers/fixed_settlement_provider_new.dart';
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
          // This import is from fixed_settlement_provider_new.dart
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => FriendsProvider(),
        ),
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
    // We'll preload assets in the first frame when we have a context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAssets(context);
    });
  }

  // Preload assets to ensure they're available
  Future<void> _preloadAssets(BuildContext context) async {
    try {
      // Force the loading of asset manifest
      await precacheImage(
        const AssetImage(
            'assets/images/finance-app-by-nishan-high-resolution-logo.png'),
        context,
      );
      debugPrint('✅ Assets preloaded successfully');
    } catch (e) {
      debugPrint('⚠️ Error preloading assets: $e');
      // Continue anyway, we'll use fallbacks if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const LoadingScreen();
        }

        if (authProvider.isAuthenticated) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
