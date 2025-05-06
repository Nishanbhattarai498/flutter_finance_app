import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static late final SupabaseClient _client;

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
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

  // Users
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
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
    await _client.from('profiles').update(data).eq('id', userId);
  }

  // Expenses
  static Future<List<Map<String, dynamic>>> getExpenses() async {
    final response = await _client
        .from('expenses')
        .select('*, user:profiles(*), group:groups(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getUserExpenses(
    String userId,
  ) async {
    final response = await _client
        .from('expenses')
        .select('*, user:profiles(*), group:groups(*)')
        .or('user_id.eq.$userId,participants.cs.{$userId}')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addExpense(Map<String, dynamic> data) async {
    await _client.from('expenses').insert(data);
  }

  static Future<void> updateExpense(int id, Map<String, dynamic> data) async {
    await _client.from('expenses').update(data).eq('id', id);
  }

  static Future<void> deleteExpense(int id) async {
    await _client.from('expenses').delete().eq('id', id);
  }

  // Groups
  static Future<List<Map<String, dynamic>>> getGroups() async {
    final response = await _client
        .from('groups')
        .select('*, members:group_members(*, user:profiles(*))')
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getUserGroups(String userId) async {
    final response = await _client
        .from('groups')
        .select('*, members:group_members!inner(*, user:profiles(*))')
        .eq('members.user_id', userId)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<int> createGroup(Map<String, dynamic> data) async {
    final response = await _client
        .from('groups')
        .insert(data)
        .select('id')
        .single();
    return response['id'];
  }

  static Future<void> addMemberToGroup(Map<String, dynamic> data) async {
    await _client.from('group_members').insert(data);
  }

  // Settlements
  static Future<List<Map<String, dynamic>>> getSettlements(
    String userId,
  ) async {
    final response = await _client
        .from('settlements')
        .select('*, payer:profiles(*), receiver:profiles(*)')
        .or('payer_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addSettlement(Map<String, dynamic> data) async {
    await _client.from('settlements').insert(data);
  }
}
