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
  final String currency;
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
    this.currency = 'NPR',
  });
  factory Expense.fromJson(Map<String, dynamic> json) {
    try {
      // Parse amount with error handling
      double amount = 0.0;
      if (json['amount'] != null) {
        if (json['amount'] is num) {
          amount = (json['amount'] as num).toDouble();
        } else if (json['amount'] is String) {
          amount = double.tryParse(json['amount'] as String) ?? 0.0;
        }
      }

      // Parse date with error handling
      DateTime date = DateTime.now();
      if (json['date'] != null) {
        try {
          date = DateTime.parse(json['date'].toString());
        } catch (e) {
          print('Error parsing expense date: $e');
        }
      }

      // Parse participants list safely
      List<String> participants = [];
      if (json['participants'] != null && json['participants'] is List) {
        participants = (json['participants'] as List)
            .map((item) => item?.toString() ?? '')
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return Expense(
        id: json['id'] as String? ?? 'unknown',
        title: json['title'] as String? ?? 'Unnamed Expense',
        amount: amount,
        date: date,
        category: json['category'] as String? ?? 'Other',
        description: json['description'] as String?,
        userId: json['user_id'] as String? ?? 'unknown',
        groupId: json['group_id'] as String?,
        isRecurring: json['is_recurring'] as bool? ?? false,
        recurringFrequency: json['recurring_frequency'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isMonthly: json['is_monthly'] as bool? ?? false,
        participants: participants,
        user: json['user'] is Map
            ? Map<String, dynamic>.from(json['user'])
            : null,
        group: json['group'] is Map
            ? Map<String, dynamic>.from(json['group'])
            : null,
        currency: json['currency'] as String? ?? 'NPR',
      );
    } catch (e) {
      print('Error parsing Expense: $e with data: $json');
      // Return fallback expense
      return Expense(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Error Loading Expense',
        amount: 0.0,
        date: DateTime.now(),
        category: 'Error',
        userId: 'unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
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
      'currency': currency,
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
    String? currency,
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
      currency: currency ?? this.currency,
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
        other.currency == currency &&
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
        currency.hashCode ^
        participants.hashCode;
  }
}
