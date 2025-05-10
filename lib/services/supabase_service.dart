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
    final response =
        await _client.from('profiles').select().eq('id', userId).single();
    return response;
  }

  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('profiles').update({
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
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
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      // First, try to get all groups where the user is the creator
      final createdGroups = await _client
          .from('groups')
          .select('id, name, description, created_by, created_at')
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      // Then, get IDs of groups the user is a member of (but didn't create)
      final groupMemberIds = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      List<Map<String, dynamic>> memberGroups = [];

      if (groupMemberIds.isNotEmpty) {
        // Extract the array of group IDs
        final List<String> ids =
            List<String>.from(groupMemberIds.map((item) => item['group_id']));

        // Get detailed group information for these IDs
        // Filter out groups the user created to avoid duplication
        memberGroups = await _client
            .from('groups')
            .select('id, name, description, created_by, created_at')
            .inFilter('id', ids)
            .neq('created_by', userId) // Avoid duplicates with created groups
            .order('created_at', ascending: false);
      }

      // Combine the two lists
      final allGroups = [...createdGroups, ...memberGroups];

      if (allGroups.isEmpty) {
        return [];
      }

      // For each group, get its members separately WITHOUT using the user:profiles join
      // which is causing the recursion
      final result = await Future.wait(allGroups.map((group) async {
        try {
          // Get basic member info without the join that causes recursion
          final members = await _client
              .from('group_members')
              .select('id, user_id, role, created_at')
              .eq('group_id', group['id']);

          // For each member, get the user profile separately
          for (var member in members) {
            try {
              final userProfile = await _client
                  .from('profiles')
                  .select('id, full_name, email')
                  .eq('id', member['user_id'])
                  .single();

              // Add the user info manually
              member['user'] = userProfile;
            } catch (e) {
              print(
                  'Error fetching profile for member ${member['user_id']}: $e');
              // If we can't get a profile, add a placeholder
              member['user'] = {
                'id': member['user_id'],
                'full_name': 'Unknown User',
                'email': 'unknown@example.com'
              };
            }
          }

          group['group_members'] = members;
        } catch (e) {
          print('Error fetching members for group ${group['id']}: $e');
          group['group_members'] = [];
        }

        return group;
      }));

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error fetching user groups: $e');
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    try {
      // Extract members if they exist and remove from data
      List<String> memberList = [];
      if (data.containsKey('members')) {
        memberList = List<String>.from(data['members']);
        data.remove('members'); // Remove to prevent circular reference
      }

      // Insert the group with basic data
      final response = await _client
          .from('groups')
          .insert(data)
          .select('id, name, description, created_by, created_at')
          .single();

      final groupId = response['id'];
      final creatorId = data['created_by'];

      try {
        // First attempt: Add the creator as admin directly
        await _client.from('group_members').insert({
          'group_id': groupId,
          'user_id': creatorId,
          'role': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('Error adding creator as admin: $e');
        // If direct insertion fails due to RLS, try using a database function
        // You would need to create this function in Supabase
        try {
          await _client.rpc('add_group_creator_as_admin', params: {
            'group_id': groupId,
            'user_id': creatorId,
          });
        } catch (rpcError) {
          print('RPC error: $rpcError');
          // If both approaches fail, try direct SQL query via REST endpoint
          // as a last resort
        }
      }

      // Add additional members
      for (final memberId in memberList) {
        if (memberId != creatorId) {
          // Skip if creator is in the members list
          try {
            await _client.from('group_members').insert({
              'group_id': groupId,
              'user_id': memberId,
              'role': 'member',
              'created_at': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            print('Error adding member $memberId: $e');
            // Continue with other members if one fails
          }
        }
      }

      // Wait a short time to ensure all database operations complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Retrieve the complete group including members
      // Use a simpler query first to avoid recursion
      final completeGroup = await _client
          .from('groups')
          .select('id, name, description, created_by, created_at')
          .eq('id', groupId)
          .single();

      // Get members separately to avoid recursive references
      final groupMembers = await _client
          .from('group_members')
          .select(
              'id, user_id, role, created_at, user:profiles(id, full_name, email)')
          .eq('group_id', groupId);

      // Combine the results
      completeGroup['group_members'] = groupMembers;

      return completeGroup;
    } catch (e) {
      print('Error creating group: $e');
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> updateGroup(
      String groupId, Map<String, dynamic> data) async {
    // Add created_at if it doesn't exist but don't try to update it
    if (!data.containsKey('created_at')) {
      data['created_at'] = DateTime.now().toIso8601String();
    }

    final response = await _client
        .from('groups')
        .update(data)
        .eq('id', groupId)
        .select('id, name, description, created_by, created_at')
        .single();
    return response;
  }

  Future<void> deleteGroup(String groupId) async {
    await _client.from('groups').delete().eq('id', groupId);
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

    // Get the group data
    final groupData = await _client
        .from('groups')
        .select('id, name, description, created_by, created_at')
        .eq('id', groupId)
        .single();

    // Get members separately
    final membersData = await _client
        .from('group_members')
        .select(
            'id, user_id, role, created_at, user:profiles(id, full_name, email)')
        .eq('group_id', groupId);

    // Combine data
    groupData['group_members'] = membersData;

    return groupData;
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

    // Get the group data
    final groupData = await _client
        .from('groups')
        .select('id, name, description, created_by, created_at')
        .eq('id', groupId)
        .single();

    // Get remaining members separately
    final membersData = await _client
        .from('group_members')
        .select(
            'id, user_id, role, created_at, user:profiles(id, full_name, email)')
        .eq('group_id', groupId);

    // Combine data
    groupData['group_members'] = membersData;

    return groupData;
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
    try {
      print('Creating expense with data: $data'); // Debug log

      // Force a schema refresh before inserting to handle cache issues
      try {
        await _client.from('expenses').select('id').limit(1);
      } catch (_) {
        // Ignore errors from this call, it's just to warm up the schema cache
      }

      // Make sure all required fields are present
      if (!data.containsKey('title')) {
        throw Exception("Missing required 'title' field");
      }

      // Extract participants before sending to Supabase
      List<String> participants = [];
      if (data.containsKey('participants')) {
        participants = List<String>.from(data['participants']);
        data.remove('participants'); // Remove to prevent DB errors
      }

      final response =
          await _client.from('expenses').insert(data).select().single();
      print('Success response: $response'); // Debug log

      // Create expense participants if provided
      final expenseId = response['id'];
      if (participants.isNotEmpty) {
        try {
          await Future.wait(participants.map((userId) async {
            await _client.from('expense_participants').insert({
              'expense_id': expenseId,
              'user_id': userId,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }));

          // Add participants back to the response for the app
          response['participants'] = participants;
        } catch (e) {
          print('Error adding participants: $e');
          // Continue even if adding participants fails
        }
      }

      return response;
    } catch (e) {
      print('Error creating expense: $e'); // Debug error log
      rethrow; // Re-throw the error to be caught by the caller
    }
  }

  Future<Map<String, dynamic>> updateExpense(
      String expenseId, Map<String, dynamic> data) async {
    final response = await _client
        .from('expenses')
        .update(data)
        .eq('id', expenseId)
        .select()
        .single();
    return response;
  }

  Future<void> deleteExpense(String expenseId) async {
    await _client.from('expenses').delete().eq('id', expenseId);
  }

  // Settlement methods
  Future<List<Map<String, dynamic>>> getUserSettlements() async {
    final response = await _client
        .from('settlements')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createSettlement(
      Map<String, dynamic> data) async {
    final response =
        await _client.from('settlements').insert(data).select().single();
    return response;
  }

  Future<Map<String, dynamic>> updateSettlement(
      String settlementId, Map<String, dynamic> data) async {
    final response = await _client
        .from('settlements')
        .update(data)
        .eq('id', settlementId)
        .select()
        .single();
    return response;
  }

  Future<void> deleteSettlement(String settlementId) async {
    await _client.from('settlements').delete().eq('id', settlementId);
  }

  // Budget methods
  Future<List<Map<String, dynamic>>> getUserBudgets() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      final response = await _client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .order('year', ascending: false)
          .order('month', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user budgets: $e');
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> getCurrentMonthBudget() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      final response = await _client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('month', currentMonth)
          .eq('year', currentYear)
          .maybeSingle();

      if (response == null) {
        // Create default budget for current month if it doesn't exist
        final newBudget = {
          'user_id': userId,
          'amount': 0.0,
          'currency': 'NPR',
          'month': currentMonth,
          'year': currentYear,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        return await createBudget(newBudget);
      }

      return response;
    } catch (e) {
      print('Error fetching current month budget: $e');
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> createBudget(Map<String, dynamic> data) async {
    try {
      final response =
          await _client.from('budgets').insert(data).select().single();
      return response;
    } catch (e) {
      print('Error creating budget: $e');
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> updateBudget(
      String budgetId, double amount) async {
    try {
      final response = await _client
          .from('budgets')
          .update({
            'amount': amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', budgetId)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error updating budget: $e');
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> getBudgetSummary(int month, int year) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      // Get budget for the specified month
      final budgetResponse = await _client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      // Calculate total expenses for the month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month

      final expensesResponse = await _client
          .from('expenses')
          .select('amount')
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      double totalExpenses = 0.0;
      for (var expense in expensesResponse) {
        totalExpenses += (expense['amount'] as num).toDouble();
      }

      // Return a summary
      return {
        'budget': budgetResponse ?? {'amount': 0.0},
        'totalExpenses': totalExpenses,
        'remaining': budgetResponse != null
            ? (budgetResponse['amount'] as num).toDouble() - totalExpenses
            : -totalExpenses
      };
    } catch (e) {
      print('Error getting budget summary: $e');
      throw e.toString();
    }
  }
}
