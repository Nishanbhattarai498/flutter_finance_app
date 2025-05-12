// Add this method to SupabaseService
static Future<void> createNotification(Map<String, dynamic> data) async {
  final user = await _client.auth.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  // Make sure required fields are present
  if (!data.containsKey('user_id') || !data.containsKey('type') || !data.containsKey('content')) {
    throw Exception('Notification must have user_id, type, and content');
  }

  await _client.from('notifications').insert(data);
}
