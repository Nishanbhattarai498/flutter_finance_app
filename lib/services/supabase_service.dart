import 'package:flutter_finance_app/secrets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static late final SupabaseClient _client;

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client => _client;

  // Auth methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        try {
          // First check if profile exists
          final existingProfile = await _client
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();

          if (existingProfile == null) {
            // Only insert if profile doesn't exist
            await _client
                .from('profiles')
                .insert({
                  'id': response.user!.id,
                  'full_name': fullName,
                  'email': email,
                  'updated_at': DateTime.now().toIso8601String(),
                  'created_at': DateTime.now().toIso8601String(),
                })
                .select()
                .single();
          }
        } catch (profileError) {
          print('Profile creation error: $profileError');
          // If profile creation fails, clean up the auth user
          if (response.user != null) {
            try {
              await _client.auth.admin.deleteUser(response.user!.id);
            } catch (deleteError) {
              print(
                'Error deleting auth user after profile creation failed: $deleteError',
              );
            }
          }
          throw 'Failed to create user profile. Please try again.';
        }
      }

      return response;
    } on AuthException catch (e) {
      print('Auth error during signup: ${e.message}');
      throw e.message;
    } catch (e) {
      print('Unexpected error during signup: $e');
      throw 'An unexpected error occurred during registration. Please check the required fields and try again.';
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;

  // Profile methods
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }

  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _client
        .from('profiles')
        .update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await _client
        .from('profiles')
        .select()
        .ilike('full_name', '%$query%')
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  // Group methods
  Future<List<Map<String, dynamic>>> getUserGroups() async {
    final response = await _client
        .from('groups')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    final response = await _client
        .from('groups')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<Map<String, dynamic>> updateGroup(String groupId, Map<String, dynamic> data) async {
    final response = await _client
        .from('groups')
        .update(data)
        .eq('id', groupId)
        .select()
        .single();
    return response;
  }

  Future<void> deleteGroup(String groupId) async {
    await _client
        .from('groups')
        .delete()
        .eq('id', groupId);
  }

  Future<Map<String, dynamic>> addGroupMember(
    String groupId,
    String userId,
    String role,
  ) async {
    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
    });

    final response = await _client
        .from('groups')
        .select('*, group_members(*)')
        .eq('id', groupId)
        .single();
    return response;
  }

  Future<Map<String, dynamic>> removeGroupMember(
    String groupId,
    String userId,
  ) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);

    final response = await _client
        .from('groups')
        .select('*, group_members(*)')
        .eq('id', groupId)
        .single();
    return response;
  }

  // Expense methods
  Future<List<Map<String, dynamic>>> getUserExpenses() async {
    final response = await _client
        .from('expenses')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    final response = await _client
        .from('expenses')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<Map<String, dynamic>> updateExpense(String expenseId, Map<String, dynamic> data) async {
    final response = await _client
        .from('expenses')
        .update(data)
        .eq('id', expenseId)
        .select()
        .single();
    return response;
  }

  Future<void> deleteExpense(String expenseId) async {
    await _client
        .from('expenses')
        .delete()
        .eq('id', expenseId);
  }

  // Settlement methods
  Future<List<Map<String, dynamic>>> getUserSettlements() async {
    final response = await _client
        .from('settlements')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createSettlement(Map<String, dynamic> data) async {
    final response = await _client
        .from('settlements')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<Map<String, dynamic>> updateSettlement(String settlementId, Map<String, dynamic> data) async {
    final response = await _client
        .from('settlements')
        .update(data)
        .eq('id', settlementId)
        .select()
        .single();
    return response;
  }

  Future<void> deleteSettlement(String settlementId) async {
    await _client
        .from('settlements')
        .delete()
        .eq('id', settlementId);
  }
}
