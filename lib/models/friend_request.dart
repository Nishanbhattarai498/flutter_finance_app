// Friend request model
class FriendRequest {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
  });
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    try {
      // Check if the 'user' field exists and is a Map
      final userMap = json['user'] as Map<String, dynamic>?;

      if (userMap == null) {
        print('Warning: FriendRequest json missing user field: $json');
        // Return a placeholder object with default values to avoid crashes
        return FriendRequest(
          id: json['id'] ?? 'unknown',
          userId: 'unknown',
          fullName: 'Unknown User',
          email: 'unknown@example.com',
          avatarUrl: null,
          createdAt: DateTime.now(),
        );
      }

      return FriendRequest(
        id: json['id'] ?? 'unknown',
        userId: userMap['id'] ?? 'unknown',
        fullName: userMap['full_name'] ?? 'Unknown',
        email: userMap['email'] ?? 'no-email',
        avatarUrl: userMap['avatar_url'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing FriendRequest: $e');
      // Return a placeholder object to avoid crashes
      return FriendRequest(
        id: 'error',
        userId: 'error',
        fullName: 'Error',
        email: 'error@example.com',
        avatarUrl: null,
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': {
        'id': userId,
        'full_name': fullName,
        'email': email,
        'avatar_url': avatarUrl,
      },
      'created_at': createdAt.toIso8601String(),
    };
  }
}
