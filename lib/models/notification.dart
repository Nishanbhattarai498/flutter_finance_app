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
    try {
      // Parse content with error handling
      Map<String, dynamic> content = {};
      if (json['content'] != null) {
        if (json['content'] is String) {
          try {
            content = jsonDecode(json['content']);
          } catch (e) {
            print('Error decoding notification content JSON: $e');
            content = {'message': 'Notification content error'};
          }
        } else if (json['content'] is Map) {
          content = Map<String, dynamic>.from(json['content']);
        }
      }

      return NotificationModel(
        id: json['id'] as String? ?? 'unknown',
        type: json['type'] as String? ?? 'unknown',
        content: content,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        sender: json['sender'] is Map
            ? Map<String, dynamic>.from(json['sender'])
            : null,
      );
    } catch (e) {
      print('Error parsing Notification: $e with data: $json');
      // Return fallback notification
      return NotificationModel(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        type: 'error',
        content: {'message': 'Error loading notification'},
        isRead: false,
        createdAt: DateTime.now(),
      );
    }
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
