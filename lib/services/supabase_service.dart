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

  // Password reset functionality
  static Future<bool> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterfinance://login/reset-callback/',
      );
      return true;
    } on AuthException catch (e) {
      print('Auth error during password reset: ${e.message}');
      throw e.message;
    } catch (e) {
      print('Unexpected error during password reset: $e');
      throw 'An unexpected error occurred. Please try again later.';
    }
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
    try {
      if (query.isEmpty) {
        return [];
      }

      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      // Search for users that match the query
      final response = await _client
          .from('profiles')
          .select('id, full_name, email, avatar_url')
          .not('id', 'eq', userId) // Exclude current user
          .or('full_name.ilike.%${query}%,email.ilike.%${query}%')
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Failed to search users: $e';
    }
  }

  // Friend management methods
  static Future<List<Map<String, dynamic>>> getFriendsList() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      // Get friends where current user is either user_id or friend_id
      final response = await _client
          .from('friends')
          .select('''
            id, 
            status, 
            created_at,
            user_id, 
            user:user_id(id, full_name, email, avatar_url),
            friend:friend_id(id, full_name, email, avatar_url)
          ''')
          .or('user_id.eq.${userId},friend_id.eq.${userId}')
          .eq('status', 'accepted');

      // Transform the data to have a consistent format
      return response.map<Map<String, dynamic>>((friendship) {
        // Check if current user is user_id or friend_id to determine which profile to show
        final bool isUserIdCurrentUser = friendship['user_id'] == userId;
        final Map<String, dynamic> friendProfile =
            isUserIdCurrentUser ? friendship['friend'] : friendship['user'];

        return {
          'friendship_id': friendship['id'],
          'status': friendship['status'],
          'created_at': friendship['created_at'],
          'friend_id': friendProfile['id'],
          'full_name': friendProfile['full_name'],
          'email': friendProfile['email'],
          'avatar_url': friendProfile['avatar_url'],
        };
      }).toList();
    } catch (e) {
      throw 'Failed to get friends list: $e';
    }
  }

  // Get pending friend requests
  static Future<List<Map<String, dynamic>>> getPendingFriendRequests() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      // Get pending friend requests where current user is the receiver (friend_id)
      final response = await _client.from('friends').select('''
            id, 
            status, 
            created_at,
            user:user_id(id, full_name, email, avatar_url)
          ''').eq('friend_id', userId).eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Failed to get pending friend requests: $e';
    }
  }

  // Send a friend request
  static Future<Map<String, dynamic>> sendFriendRequest(String friendId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      // Check if a request already exists
      final existingRequest = await _client
          .from('friends')
          .select()
          .or('and(user_id.eq.${userId},friend_id.eq.${friendId}),and(user_id.eq.${friendId},friend_id.eq.${userId})')
          .maybeSingle();

      if (existingRequest != null) {
        throw 'A friend request already exists with this user';
      }

      // Create a new friend request
      final response = await _client
          .from('friends')
          .insert({
            'user_id': userId,
            'friend_id': friendId,
            'status': 'pending',
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw 'Failed to send friend request: $e';
    }
  }

  // Respond to a friend request (accept or reject)
  static Future<Map<String, dynamic>> respondToFriendRequest(
      String requestId, String action) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      if (action != 'accepted' && action != 'rejected') {
        throw 'Invalid action: must be "accepted" or "rejected"';
      }

      // Verify this request is for the current user
      final request = await _client
          .from('friends')
          .select()
          .eq('id', requestId)
          .eq('friend_id', userId) // Current user must be the receiver
          .maybeSingle();

      if (request == null) {
        throw 'Friend request not found or you are not authorized to respond';
      } // Update the friend request status with debug print statements
      print('Updating friend request $requestId to status: $action');

      final response = await _client
          .from('friends')
          .update({
            'status': action,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', requestId)
          .select()
          .single();

      print('Friend request updated successfully: ${response.toString()}');

      // Return a clean Map to avoid JSON formatting issues
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Friend request response error: $e');
      // Return an empty map instead of throwing to avoid parsing issues
      throw 'Failed to respond to friend request: $e';
    }
  }

  // Get user's notifications
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      final response = await _client
          .from('notifications')
          .select('''
            id, 
            type, 
            content, 
            is_read, 
            created_at,
            sender:sender_id(id, full_name, avatar_url)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(30);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Failed to get notifications: $e';
    }
  }

  // Mark a notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      await _client
          .from('notifications')
          .update(
              {'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (e) {
      throw 'Failed to mark notification as read: $e';
    }
  }

  // Delete a friend connection
  static Future<void> removeFriend(String friendshipId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      // Verify this friendship involves the current user
      final friendship = await _client
          .from('friends')
          .select()
          .eq('id', friendshipId)
          .or('user_id.eq.${userId},friend_id.eq.${userId}')
          .maybeSingle();

      if (friendship == null) {
        throw 'Friendship not found or you are not authorized to remove it';
      }

      // Delete the friendship
      await _client.from('friends').delete().eq('id', friendshipId);
    } catch (e) {
      throw 'Failed to remove friend: $e';
    }
  }

  // Group methods
  static Future<List<Map<String, dynamic>>> getUserGroups() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      // 1. Get all groups the user created
      final createdGroupsResponse = await _client
          .from('groups')
          .select('id, name, description, created_by, created_at')
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      // 2. Get all groups the user is a member of (excluding created ones)
      // We use a single query with a join on group_members
      final memberGroupsResponse = await _client
          .from('group_members')
          .select('group:groups(id, name, description, created_by, created_at)')
          .eq('user_id', userId);

      List<Map<String, dynamic>> allGroups = [];

      // Add created groups
      for (var group in createdGroupsResponse) {
        allGroups.add(Map<String, dynamic>.from(group));
      }

      // Add member groups (extracting from the join)
      for (var item in memberGroupsResponse) {
        if (item['group'] != null) {
          final groupData = Map<String, dynamic>.from(item['group']);
          // Avoid duplicates if user is both creator and member (shouldn't happen with correct logic but safe to check)
          if (groupData['created_by'] != userId) {
            allGroups.add(groupData);
          }
        }
      }

      // 3. Fetch members for ALL groups in parallel
      // This is much faster than fetching one by one
      if (allGroups.isNotEmpty) {
        final groupIds = allGroups.map((g) => g['id'] as String).toList();
        
        // Fetch all members for these groups in one go
        final allMembers = await _client
            .from('group_members')
            .select('id, group_id, user_id, role, created_at, user:profiles(id, full_name, email, avatar_url)')
            .inFilter('group_id', groupIds);

        // Organize members by group_id
        final membersByGroup = <String, List<Map<String, dynamic>>>{};
        for (var member in allMembers) {
          final groupId = member['group_id'] as String;
          if (!membersByGroup.containsKey(groupId)) {
            membersByGroup[groupId] = [];
          }
          
          // Flatten the user profile into the member object for easier consumption
          final memberData = Map<String, dynamic>.from(member);
          if (member['user'] != null) {
             // Ensure user data is accessible
             memberData['user'] = member['user'];
          } else {
             // Fallback
             memberData['user'] = {
               'id': member['user_id'],
               'full_name': 'Unknown',
               'email': ''
             };
          }
          
          membersByGroup[groupId]!.add(memberData);
        }

        // Attach members to groups
        for (var group in allGroups) {
          group['group_members'] = membersByGroup[group['id']] ?? [];
        }
      }

      // Sort combined list by created_at
      allGroups.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'].toString()) ?? DateTime.now();
        final dateB = DateTime.tryParse(b['created_at'].toString()) ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      return allGroups;
    } catch (e) {
      print('Error fetching user groups: $e');
      throw e.toString();
    }
  }

  static Future<Map<String, dynamic>> createGroup(
      Map<String, dynamic> data) async {
    try {
      // Extract members if they exist and remove from data
      List<String> memberList = [];
      if (data.containsKey('members')) {
        memberList = List<String>.from(data['members']);
        data.remove('members');
      }

      // Insert the group
      final response = await _client
          .from('groups')
          .insert(data)
          .select('id, name, description, created_by, created_at')
          .single();

      final groupId = response['id'];
      final creatorId = data['created_by'];

      // Add creator as owner/admin
      // RLS policy "Add members" allows this because user is the creator
      await _client.from('group_members').insert({
        'group_id': groupId,
        'user_id': creatorId,
        'role': 'owner', // Creator is owner
        'created_at': DateTime.now().toIso8601String(),
      });

      // Add additional members
      if (memberList.isNotEmpty) {
        final membersToInsert = memberList
            .where((id) => id != creatorId)
            .map((memberId) => {
                  'group_id': groupId,
                  'user_id': memberId,
                  'role': 'member',
                  'created_at': DateTime.now().toIso8601String(),
                })
            .toList();

        if (membersToInsert.isNotEmpty) {
          await _client.from('group_members').insert(membersToInsert);
        }
      }

      // Retrieve the complete group including members
      final completeGroup = await _client
          .from('groups')
          .select('id, name, description, created_by, created_at')
          .eq('id', groupId)
          .single();

      // Get members separately with user profiles
      final groupMembers = await _client
          .from('group_members')
          .select(
              'id, user_id, role, created_at, user:profiles(id, full_name, email, avatar_url)')
          .eq('group_id', groupId);

      // Combine the results
      completeGroup['group_members'] = groupMembers;

      return completeGroup;
    } catch (e) {
      print('Error creating group: $e');
      throw e.toString();
    }
  }

  static Future<Map<String, dynamic>> updateGroup(
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

  static Future<void> deleteGroup(String groupId) async {
    await _client.from('groups').delete().eq('id', groupId);
  }

  static Future<Map<String, dynamic>> addGroupMember(
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

  static Future<Map<String, dynamic>> removeGroupMember(
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
  static Future<List<Map<String, dynamic>>> getUserExpenses() async {
    // Get the current user ID
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Fetch expenses where user is owner OR participant
    // Using a more inclusive query than just owner
    final response = await _client
        .from('expenses')
        .select('''
          id, title, amount, currency, date, category, description, 
          user_id, group_id, is_recurring, recurring_frequency, 
          created_at, updated_at
        ''')
        .or('user_id.eq.${user.id}') // For now just owner, can extend to participants if needed
        .order('date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> createExpense(
      Map<String, dynamic> data) async {
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

      // Ensure the user_id is set to the current user
      final user = await _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Enforce the current user's ID for the expense
      data['user_id'] = user.id;

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

  static Future<Map<String, dynamic>> updateExpense(
      String expenseId, Map<String, dynamic> data) async {
    final user = await _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // First, verify this expense belongs to the current user
    final checkResponse = await _client
        .from('expenses')
        .select('id')
        .eq('id', expenseId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (checkResponse == null) {
      throw Exception(
          'Expense not found or you do not have permission to update it');
    }

    // Perform the update after verification
    final response = await _client
        .from('expenses')
        .update(data)
        .eq('id', expenseId)
        .eq('user_id', user.id) // Additional safety check
        .select()
        .single();

    return response;
  }

  static Future<void> deleteExpense(String expenseId) async {
    final user = await _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // First, verify this expense belongs to the current user
    final checkResponse = await _client
        .from('expenses')
        .select('id')
        .eq('id', expenseId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (checkResponse == null) {
      throw Exception(
          'Expense not found or you do not have permission to delete it');
    }

    try {
      // First, delete all participants records
      await _client
          .from('expense_participants')
          .delete()
          .eq('expense_id', expenseId);

      // Then delete the expense itself
      await _client
          .from('expenses')
          .delete()
          .eq('id', expenseId)
          .eq('user_id', user.id); // Additional safety check
    } catch (e) {
      print('Error deleting expense: $e');
      throw Exception('Failed to delete expense: $e');
    }
  }

  // Settlement methods
  static Future<List<Map<String, dynamic>>> getUserSettlements() async {
    // Get the current user ID
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Fetch settlements where the current user is either the payer or the receiver
    final response = await _client
        .from('settlements')
        .select('''
          id, amount, currency, status, method, created_at,
          payer_id, receiver_id, group_id, expense_id,
          payer:payer_id(id, full_name, avatar_url),
          receiver:receiver_id(id, full_name, avatar_url)
        ''')
        .or('payer_id.eq.${user.id},receiver_id.eq.${user.id}')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> createSettlement(
      Map<String, dynamic> data) async {
    final user = await _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    } // Make sure payer_id and receiver_id are set correctly
    if (!data.containsKey('payer_id') || !data.containsKey('receiver_id')) {
      throw Exception('Settlement must have payer_id and receiver_id');
    }

    // Insert the settlement
    final response =
        await _client.from('settlements').insert(data).select().single();

    try {
      // If the current user is NOT the payer, then create a notification for the payer
      if (user.id != data['payer_id']) {
        await _client.from('notifications').insert({
          'user_id': data['payer_id'],
          'sender_id': user.id,
          'type': 'settlement',
          'content': 'You have a new settlement request',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // If the current user is NOT the receiver, then create a notification for the receiver
      if (user.id != data['receiver_id']) {
        await _client.from('notifications').insert({
          'user_id': data['receiver_id'],
          'sender_id': user.id,
          'type': 'settlement',
          'content': 'You have a new settlement request',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error creating settlement notification: $e');
      // Continue even if notification creation fails
    }

    return response;
  }

  static Future<Map<String, dynamic>> updateSettlement(
      String settlementId, Map<String, dynamic> data) async {
    final user = await _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // First, verify this settlement involves the current user (as payer or receiver)
    final checkResponse = await _client
        .from('settlements')
        .select('id')
        .eq('id', settlementId)
        .or('payer_id.eq.${user.id},receiver_id.eq.${user.id}')
        .maybeSingle();

    if (checkResponse == null) {
      throw Exception(
          'Settlement not found or you do not have permission to update it');
    }

    final response = await _client
        .from('settlements')
        .update(data)
        .eq('id', settlementId)
        .select()
        .single();
    return response;
  }

  static Future<void> deleteSettlement(String settlementId) async {
    final user = await _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // First, verify this settlement involves the current user (as payer or receiver)
    final checkResponse = await _client
        .from('settlements')
        .select('id')
        .eq('id', settlementId)
        .or('payer_id.eq.${user.id},receiver_id.eq.${user.id}')
        .maybeSingle();
    if (checkResponse == null) {
      throw Exception(
          'Settlement not found or you do not have permission to delete it');
    }

    await _client.from('settlements').delete().eq('id', settlementId);
  }

  static Future<void> createNotification(Map<String, dynamic> data) async {
    final user = await _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Make sure required fields are present
    if (!data.containsKey('user_id') ||
        !data.containsKey('type') ||
        !data.containsKey('content')) {
      throw Exception('Notification must have user_id, type, and content');
    }

    await _client.from('notifications').insert(data);
  }

  // Budget methods
  static Future<List<Map<String, dynamic>>> getUserBudgets() async {
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

  static Future<Map<String, dynamic>> getCurrentMonthBudget() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // Try to get the current month's budget or create a new one if it doesn't exist
      final response = await _client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('month', currentMonth)
          .eq('year', currentYear)
          .maybeSingle();

      if (response == null) {
        // Create a default budget for current month
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

  static Future<Map<String, dynamic>> createBudget(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _client.from('budgets').insert(data).select().single();
      return response;
    } catch (e) {
      print('Error creating budget: $e');
      throw e.toString();
    }
  }

  static Future<Map<String, dynamic>> updateBudget(
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

  static Future<Map<String, dynamic>> getBudgetSummary(
      String monthString) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      // Parse the YYYY-MM string to get year and month
      final parts = monthString.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      // Get budget for the specified month
      final budgetResponse = await _client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      // Calculate start and end dates for the month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month

      // Calculate total expenses for the month using the transactions table
      final expensesResponse = await _client
          .from('transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      double totalExpenses = 0.0;
      for (var expense in expensesResponse) {
        totalExpenses += (expense['amount'] as num).toDouble();
      }

      // If no budget exists for this month, create one
      Map<String, dynamic> budgetData;
      if (budgetResponse == null) {
        final newBudget = {
          'user_id': userId,
          'amount': 0.0,
          'currency': 'NPR',
          'month': month,
          'year': year,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          budgetData = await createBudget(newBudget);
        } catch (e) {
          print('Error creating budget in getBudgetSummary: $e');
          budgetData = {'amount': 0.0};
        }
      } else {
        budgetData = budgetResponse;
      }

      // Return a summary
      return {
        'budget': budgetData,
        'totalExpenses': totalExpenses,
        'remaining': (budgetData['amount'] as num).toDouble() - totalExpenses
      };
    } catch (e) {
      print('Error getting budget summary: $e');
      throw e.toString();
    }
  }
}
