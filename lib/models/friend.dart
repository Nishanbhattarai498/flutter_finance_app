// Friend model
class Friend {
  final String id;
  final String friendshipId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;

  Friend({
    required this.id,
    required this.friendshipId,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
  });
  factory Friend.fromJson(Map<String, dynamic> json) {
    try {
      return Friend(
        id: json['friend_id'] ?? 'unknown',
        friendshipId: json['friendship_id'] ?? 'unknown',
        fullName: json['full_name'] ?? 'Unknown User',
        email: json['email'] ?? 'no-email',
        avatarUrl: json['avatar_url'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing Friend: $e');
      // Return a placeholder object to avoid crashes
      return Friend(
        id: 'error',
        friendshipId: 'error',
        fullName: 'Error',
        email: 'error@example.com',
        avatarUrl: null,
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'friend_id': id,
      'friendship_id': friendshipId,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
