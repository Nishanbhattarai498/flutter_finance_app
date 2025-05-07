import 'package:flutter/foundation.dart';

class Expense {
  final int id;
  final String userId;
  final String? groupId;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final DateTime createdAt;
  final bool isMonthly;
  final List<String> participants;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? group;

  Expense({
    required this.id,
    required this.userId,
    this.groupId,
    required this.description,
    required this.amount,
    this.currency = 'NPR',
    required this.category,
    required this.createdAt,
    this.isMonthly = false,
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
      currency: json['currency'] ?? 'NPR',
      category: json['category'],
      createdAt: DateTime.parse(json['created_at']),
      isMonthly: json['is_monthly'] ?? false,
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
      'currency': currency,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'is_monthly': isMonthly,
      'participants': participants,
    };
  }

  Expense copyWith({
    int? id,
    String? userId,
    String? groupId,
    String? description,
    double? amount,
    String? currency,
    String? category,
    DateTime? createdAt,
    bool? isMonthly,
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
      currency: currency ?? this.currency,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isMonthly: isMonthly ?? this.isMonthly,
      participants: participants ?? this.participants,
      user: user ?? this.user,
      group: group ?? this.group,
    );
  }

  // Calculate monthly amount if it's a monthly expense
  double get monthlyAmount => isMonthly ? amount : 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Expense &&
        other.id == id &&
        other.userId == userId &&
        other.groupId == groupId &&
        other.description == description &&
        other.amount == amount &&
        other.currency == currency &&
        other.category == category &&
        other.createdAt == createdAt &&
        other.isMonthly == isMonthly &&
        listEquals(other.participants, participants);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        groupId.hashCode ^
        description.hashCode ^
        amount.hashCode ^
        currency.hashCode ^
        category.hashCode ^
        createdAt.hashCode ^
        isMonthly.hashCode ^
        participants.hashCode;
  }
}
