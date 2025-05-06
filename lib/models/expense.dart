import 'package:flutter/foundation.dart';

class Expense {
  final int id;
  final String userId;
  final String? groupId;
  final String description;
  final double amount;
  final String category;
  final DateTime createdAt;
  final List<String> participants;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? group;

  Expense({
    required this.id,
    required this.userId,
    this.groupId,
    required this.description,
    required this.amount,
    required this.category,
    required this.createdAt,
    required this.participants,
    this.user,
    this.group,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      userId: json['user_id'],
      groupId: json['group_id'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      createdAt: DateTime.parse(json['created_at']),
      participants: List<String>.from(json['participants'] ?? []),
      user: json['user'],
      group: json['group'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'group_id': groupId,
      'description': description,
      'amount': amount,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'participants': participants,
    };
  }

  Expense copyWith({
    int? id,
    String? userId,
    String? groupId,
    String? description,
    double? amount,
    String? category,
    DateTime? createdAt,
    List<String>? participants,
    Map<String, dynamic>? user,
    Map<String, dynamic>? group,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
      user: user ?? this.user,
      group: group ?? this.group,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Expense &&
        other.id == id &&
        other.userId == userId &&
        other.groupId == groupId &&
        other.description == description &&
        other.amount == amount &&
        other.category == category &&
        other.createdAt == createdAt &&
        listEquals(other.participants, participants);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        groupId.hashCode ^
        description.hashCode ^
        amount.hashCode ^
        category.hashCode ^
        createdAt.hashCode ^
        participants.hashCode;
  }
}
