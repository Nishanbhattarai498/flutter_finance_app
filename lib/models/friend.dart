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
    return Friend(
      id: json['friend_id'],
      friendshipId: json['friendship_id'],
      fullName: json['full_name'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
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
