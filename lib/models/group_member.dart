class GroupMember {
  final int id;
  final int groupId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final Map<String, dynamic>? user;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.user,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      groupId: json['group_id'],
      userId: json['user_id'],
      role: json['role'],
      joinedAt: DateTime.parse(json['joined_at']),
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  String get displayName {
    if (user != null && user!['full_name'] != null) {
      return user!['full_name'];
    }
    return 'Unknown User';
  }

  String get avatarUrl {
    if (user != null && user!['avatar_url'] != null) {
      return user!['avatar_url'];
    }
    return '';
  }
}
