import 'package:flutter/material.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';
import 'package:flutter_finance_app/services/supabase_service_budget.dart';
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
      // Avoid notifying listeners during build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      _isAuthenticated = await checkAuthenticationStatus();

      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      _isAuthenticated = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      debugPrint('Error during auth check: $e');
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
          await _initializeUserData();
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
          await _initializeUserData();
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
        await _initializeUserData();
        debugPrint('✅ User data initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing user data: $e');
        // Continue with login even if data initialization fails
      }

      _isLoading = false;
      notifyListeners();
      return {
        'success': true,
        'message': 'Successfully logged in',
      };
    } catch (e) {
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return {
        'success': false,
        'message': e.toString().contains('Invalid login credentials')
            ? 'Invalid email or password'
            : e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      _isLoading = false;

      if (response.user == null) {
        notifyListeners();
        return {
          'success': false,
          'message': 'Failed to create account.',
        };
      }

      notifyListeners();
      return {
        'success': true,
        'message':
            'Successfully signed up. Please check your email for verification.',
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Clear all user-specific cache keys
      final currentUserId = _userId;
      if (currentUserId != null) {
        final keysToRemove = [
          'cached_expenses_$currentUserId',
          'cached_groups_$currentUserId',
          'cached_settlements_$currentUserId',
          'last_sync'
        ];

        // Remove all user-specific keys
        for (var key in keysToRemove) {
          if (prefs.containsKey(key)) {
            await prefs.remove(key);
          }
        }
      }

      await SupabaseService.signOut();

      // Reset local state
      _userId = null;
      _userProfile = null;
      _isAuthenticated = false;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error signing out: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    if (_userId == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.updateUserProfile(_userId!, data);

      // Refresh profile data
      await _fetchUserProfile();

      _isLoading = false;
      notifyListeners();
      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating profile: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Reset password functionality
  Future<Map<String, dynamic>> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await SupabaseService.resetPassword(email);

      _isLoading = false;
      notifyListeners();

      return {
        'success': success,
        'message':
            'Password reset link has been sent to your email. Please check your inbox.',
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<void> _initializeUserData() async {
    // Check if current month's budget exists, create one if not
    try {
      await SupabaseServiceBudget.getCurrentMonthBudget();
      debugPrint('✅ Budget exists for current month');
    } catch (e) {
      debugPrint('❌ No budget for current month, creating one... ($e)');
      try {
        final userId = await SupabaseServiceBudget.getCurrentUserId();
        final now = DateTime.now();

        if (userId == null) {
          throw 'User not authenticated';
        }

        await SupabaseServiceBudget.createBudget({
          'user_id': userId,
          'month': now.month,
          'year': now.year,
          'amount': 0,
          'currency': 'NPR',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
        debugPrint('✅ Created default budget for current month');
      } catch (createError) {
        debugPrint('❌ Failed to create default budget: $createError');
      }
    }
  }

  // Search users by email or name for friend requests
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (_userId == null) return [];
    if (query.isEmpty) return [];

    try {
      final searchResults = await SupabaseService.searchUsers(query);
      // Filter out current user from results
      return searchResults.where((user) => user['id'] != _userId).toList();
    } catch (e) {
      debugPrint('❌ Error searching users: $e');
      return [];
    }
  }
}
