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
    return FriendRequest(
      id: json['id'],
      userId: json['user']['id'],
      fullName: json['user']['full_name'],
      email: json['user']['email'],
      avatarUrl: json['user']['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
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
