import 'package:flutter/material.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';

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
        return true;
      }

      // Try to get existing session
      final session = await SupabaseService.client.auth.currentSession;
      if (session?.user != null) {
        _userId = session!.user.id;
        await _fetchUserProfile();
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
      await SupabaseService.signOut();
      _userId = null;
      _userProfile = null;
      _isAuthenticated = false;
    } catch (e) {
      debugPrint('Error signing out: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.updateUserProfile(_userId!, data);
      await _fetchUserProfile();
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }

    _isLoading = false;
    notifyListeners();
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
