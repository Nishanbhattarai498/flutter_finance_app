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
    try {
      // Get display name from different possible sources
      String displayName = 'Unknown User';
      if (json['display_name'] != null) {
        displayName = json['display_name'] as String;
      } else if (json['user'] is Map && json['user']['full_name'] != null) {
        displayName = json['user']['full_name'] as String;
      }

      return GroupMember(
        userId: json['user_id'] as String? ?? 'unknown',
        groupId: json['group_id'] as String? ?? 'unknown',
        role: json['role'] as String? ?? 'member',
        displayName: displayName,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing GroupMember: $e with data: $json');
      // Return a fallback group member to prevent app crashes
      return GroupMember(
        userId: 'error_${DateTime.now().millisecondsSinceEpoch}',
        groupId: 'unknown',
        role: 'member',
        displayName: 'Error Loading Member',
        createdAt: DateTime.now(),
      );
    }
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
