import 'package:intl/intl.dart';

class Budget {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final int month; // Month (1-12)
  final int year; // Year (e.g., 2025)
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.userId,
    required this.amount,
    this.currency = 'NPR',
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'].toString(),
      userId: map['user_id'],
      amount: (map['amount'] is int)
          ? (map['amount'] as int).toDouble()
          : map['amount'],
      currency: map['currency'] ?? 'NPR',
      month: map['month'],
      year: map['year'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'month': month,
      'year': year,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get human-readable month name
  String get monthName {
    final date = DateTime(year, month);
    return DateFormat('MMMM yyyy').format(date);
  }

  // Get YYYY-MM format string for month
  String get monthString {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  Budget copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
