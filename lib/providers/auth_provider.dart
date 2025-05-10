import 'package:flutter/material.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:flutter_finance_app/utils/cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _userId;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  String? get userId => _userId;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuth() async {
    try {
      _isLoading = true;
      notifyListeners();

      _isAuthenticated = await checkAuthenticationStatus();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<bool> checkAuthenticationStatus() async {
    try {
      // Check for current user first
      final user = SupabaseService.currentUser;
      if (user != null) {
        _userId = user.id;
        await _fetchUserProfile();

        // Initialize user data (including budget) after checking auth
        try {
          final supabaseService = SupabaseService();
          await _initializeUserData(supabaseService);
          debugPrint('✅ User data initialized on app startup');
        } catch (e) {
          debugPrint('❌ Error initializing user data on startup: $e');
        }

        return true;
      }

      // Try to get existing session
      final session = await SupabaseService.client.auth.currentSession;
      if (session?.user != null) {
        _userId = session!.user.id;
        await _fetchUserProfile();

        // Initialize user data (including budget) after checking session
        try {
          final supabaseService = SupabaseService();
          await _initializeUserData(supabaseService);
          debugPrint('✅ User data initialized on session restore');
        } catch (e) {
          debugPrint('❌ Error initializing user data on session restore: $e');
        }

        return true;
      }
    } catch (e) {
      debugPrint('Error checking authentication: $e');
    }
    return false;
  }

  Future<void> _fetchUserProfile() async {
    if (_userId == null) return;

    try {
      _userProfile = await SupabaseService.getUserProfile(_userId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );
      _userId = response.user?.id;
      await _fetchUserProfile();
      _isAuthenticated = true;

      // Initialize user data after login (creates budget if not exists)
      try {
        final supabaseService = SupabaseService();
        await _initializeUserData(supabaseService);
        debugPrint('✅ User data initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing user data: $e');
        // Continue with login even if data initialization fails
      }

      _isLoading = false;
      notifyListeners();

      return {
        'success': response.user != null,
        'message': response.user != null
            ? 'Successfully signed in'
            : 'Invalid email or password',
      };
    } catch (e) {
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();

      return {'success': false, 'message': e.toString()};
    }
  }

  // Initialize user data including creating initial budget
  Future<void> _initializeUserData(SupabaseService supabaseService) async {
    if (_userId == null) return;

    // Ensure user has a budget for the current month
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    try {
      // This will create a budget if none exists
      await supabaseService.getCurrentMonthBudget();
      debugPrint(
          '✅ Budget initialized for month: $currentMonth, year: $currentYear');
    } catch (e) {
      debugPrint('❌ Error initializing budget: $e');
      // Continue even if budget initialization fails
    }
  }

  Future<Map<String, dynamic>> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user == null) {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': 'Registration failed. Please try again.',
        };
      }

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'message':
            'Successfully signed up. Please check your email for verification.',
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      String message = 'An error occurred during registration';
      if (e.toString().contains('already registered')) {
        message = 'This email is already registered';
      }

      return {'success': false, 'message': message};
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get CacheManager instance to clear cache
      final prefs = await SharedPreferences.getInstance();
      final cacheManager = CacheManager(prefs);

      // Clear all cached data
      await cacheManager.clearCache();

      // Sign out from Supabase
      await SupabaseService.signOut();

      // Reset local state
      _userId = null;
      _userProfile = null;
      _isAuthenticated = false;
    } catch (e) {
      debugPrint('Error signing out: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    if (_userId == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.updateUserProfile(_userId!, data);
      await _fetchUserProfile();

      _isLoading = false;
      notifyListeners();
      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      debugPrint('Error updating profile: $e');

      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Failed to update profile: ${e.toString()}'
      };
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      return await SupabaseService.searchUsers(query);
    } catch (e) {
      debugPrint('Error searching users: $e');
      throw 'Failed to search users: $e';
    }
  }
}
