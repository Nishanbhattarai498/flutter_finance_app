import 'package:flutter/foundation.dart';

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String role;
  final DateTime createdAt;
  final Map<String, dynamic>? user;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.createdAt,
    this.user,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'user': user,
    };
  }

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? role,
    DateTime? createdAt,
    Map<String, dynamic>? user,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMember &&
        other.id == id &&
        other.groupId == groupId &&
        other.userId == userId &&
        other.role == role &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        groupId.hashCode ^
        userId.hashCode ^
        role.hashCode ^
        createdAt.hashCode;
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
