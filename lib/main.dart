import 'package:flutter/material.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:flutter_finance_app/screens/auth/login_screen.dart';
import 'package:flutter_finance_app/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_finance_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/expense_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize(
    // Replace with your Supabase URL and anon key
    supabaseUrl: 'YOUR_SUPABASE_URL',
    supabaseAnonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return FutureBuilder<bool>(
            future: authProvider.isAuthenticated(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final bool isAuthenticated = snapshot.data ?? false;

              if (isAuthenticated) {
                return const DashboardScreen();
              } else {
                return const LoginScreen();
              }
            },
          );
        },
      ),
    );
  }
}
