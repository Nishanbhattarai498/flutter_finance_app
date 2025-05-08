import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? description;
  final String userId;
  final String? groupId;
  final bool isRecurring;
  final String? recurringFrequency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isMonthly;
  final List<String> participants;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? group;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.description,
    required this.userId,
    this.groupId,
    this.isRecurring = false,
    this.recurringFrequency,
    required this.createdAt,
    required this.updatedAt,
    this.isMonthly = false,
    this.participants = const [],
    this.user,
    this.group,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      description: json['description'] as String?,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringFrequency: json['recurring_frequency'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isMonthly: json['is_monthly'] as bool? ?? false,
      participants: List<String>.from(json['participants'] ?? []),
      user: json['user'] as Map<String, dynamic>?,
      group: json['group'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'description': description,
      'user_id': userId,
      'group_id': groupId,
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_monthly': isMonthly,
      'participants': participants,
      'user': user,
      'group': group,
    };
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? description,
    String? userId,
    String? groupId,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isMonthly,
    List<String>? participants,
    Map<String, dynamic>? user,
    Map<String, dynamic>? group,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isMonthly: isMonthly ?? this.isMonthly,
      participants: participants ?? this.participants,
      user: user ?? this.user,
      group: group ?? this.group,
    );
  }

  // Calculate monthly amount if it's a monthly expense
  double get monthlyAmount => isRecurring ? amount : 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense &&
        other.id == id &&
        other.title == title &&
        other.amount == amount &&
        other.date == date &&
        other.category == category &&
        other.description == description &&
        other.userId == userId &&
        other.groupId == groupId &&
        other.isRecurring == isRecurring &&
        other.recurringFrequency == recurringFrequency &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isMonthly == isMonthly &&
        listEquals(other.participants, participants);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        amount.hashCode ^
        date.hashCode ^
        category.hashCode ^
        description.hashCode ^
        userId.hashCode ^
        groupId.hashCode ^
        isRecurring.hashCode ^
        recurringFrequency.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isMonthly.hashCode ^
        participants.hashCode;
  }
}
