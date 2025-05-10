// Notification model
import 'dart:convert';

class NotificationModel {
  final String id;
  final String type;
  final Map<String, dynamic> content;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;

  NotificationModel({
    required this.id,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.sender,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      content: json['content'] is String
          ? jsonDecode(json['content'])
          : json['content'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
      sender: json['sender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'sender': sender,
    };
  }

  String get message => content['message'] ?? 'New notification';

  // Helper for creating a copy with some fields updated
  NotificationModel copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? content,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? sender,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
    );
  }
}
