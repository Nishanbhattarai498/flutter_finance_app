import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseServiceFix {
  // Settlement methods
  static Future<List<Map<String, dynamic>>> getUserSettlements() async {
    final user = await Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Fetch settlements where the current user is either the payer or the receiver
    final response = await Supabase.instance.client
        .from('settlements')
        .select()
        .or('payer_id.eq.${user.id},receiver_id.eq.${user.id}')
        .order('created_at', ascending: false);

    return response;
  }

  static Future<Map<String, dynamic>> createSettlement(
      Map<String, dynamic> data) async {
    final user = await Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Make sure payer_id and receiver_id are set correctly
    if (!data.containsKey('payer_id') || !data.containsKey('receiver_id')) {
      throw Exception('Settlement must have payer_id and receiver_id');
    }

    // Insert the settlement
    final response = await Supabase.instance.client
        .from('settlements')
        .insert(data)
        .select()
        .single();

    try {
      // If the current user is NOT the payer, then create a notification for the payer
      if (user.id != data['payer_id']) {
        await createNotification({
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
        await createNotification({
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
    final user = await Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // First, verify this settlement involves the current user (as payer or receiver)
    final checkResponse = await Supabase.instance.client
        .from('settlements')
        .select('id')
        .eq('id', settlementId)
        .or('payer_id.eq.${user.id},receiver_id.eq.${user.id}')
        .maybeSingle();

    if (checkResponse == null) {
      throw Exception(
          'Settlement not found or you do not have permission to update it');
    }

    final response = await Supabase.instance.client
        .from('settlements')
        .update(data)
        .eq('id', settlementId)
        .select()
        .single();
    return response;
  }

  static Future<void> deleteSettlement(String settlementId) async {
    final user = await Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // First, verify this settlement involves the current user (as payer or receiver)
    final checkResponse = await Supabase.instance.client
        .from('settlements')
        .select('id')
        .eq('id', settlementId)
        .or('payer_id.eq.${user.id},receiver_id.eq.${user.id}')
        .maybeSingle();

    if (checkResponse == null) {
      throw Exception(
          'Settlement not found or you do not have permission to delete it');
    }

    await Supabase.instance.client
        .from('settlements')
        .delete()
        .eq('id', settlementId);
  }

  static Future<void> createNotification(Map<String, dynamic> data) async {
    final user = await Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Make sure required fields are present
    if (!data.containsKey('user_id') ||
        !data.containsKey('type') ||
        !data.containsKey('content')) {
      throw Exception('Notification must have user_id, type, and content');
    }

    await Supabase.instance.client.from('notifications').insert(data);
  }
}
