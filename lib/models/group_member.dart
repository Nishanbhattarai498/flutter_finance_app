import 'package:flutter/foundation.dart';

class GroupMember {
  final String userId;
  final String groupId;
  final String role;
  final String displayName;
  final DateTime createdAt;

  GroupMember({
    required this.userId,
    required this.groupId,
    required this.role,
    required this.displayName,
    required this.createdAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'],
      groupId: json['group_id'],
      role: json['role'],
      displayName: json['display_name'] ?? json['user']['full_name'] ?? 'Unknown User',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'group_id': groupId,
      'role': role,
      'display_name': displayName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  GroupMember copyWith({
    String? userId,
    String? groupId,
    String? role,
    String? displayName,
    DateTime? createdAt,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMember &&
        other.userId == userId &&
        other.groupId == groupId &&
        other.role == role &&
        other.displayName == displayName &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        groupId.hashCode ^
        role.hashCode ^
        displayName.hashCode ^
        createdAt.hashCode;
  }

  String get avatarUrl {
    // Implementation of avatarUrl getter
    return '';
  }
}
