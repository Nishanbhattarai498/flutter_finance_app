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
    try {
      // Parse amount with error handling
      double amount = 0.0;
      if (map['amount'] != null) {
        if (map['amount'] is int) {
          amount = (map['amount'] as int).toDouble();
        } else if (map['amount'] is double) {
          amount = map['amount'] as double;
        } else if (map['amount'] is String) {
          amount = double.tryParse(map['amount'] as String) ?? 0.0;
        }
      }

      // Parse month and year with error handling
      int month = DateTime.now().month;
      if (map['month'] != null) {
        if (map['month'] is int) {
          month = map['month'] as int;
        } else if (map['month'] is String) {
          // Try to parse month from YYYY-MM format or plain string
          final monthStr = map['month'] as String;
          if (monthStr.contains('-')) {
            final parts = monthStr.split('-');
            month = int.tryParse(parts[1]) ?? DateTime.now().month;
          } else {
            month = int.tryParse(monthStr) ?? DateTime.now().month;
          }
        }
      }

      int year = DateTime.now().year;
      if (map['year'] != null) {
        if (map['year'] is int) {
          year = map['year'] as int;
        } else if (map['year'] is String) {
          // Try to parse year from YYYY-MM format or plain string
          final yearStr = map['year'] as String;
          if (yearStr.contains('-')) {
            final parts = yearStr.split('-');
            year = int.tryParse(parts[0]) ?? DateTime.now().year;
          } else {
            year = int.tryParse(yearStr) ?? DateTime.now().year;
          }
        }
      }

      // For backward compatibility, if month is in YYYY-MM format and year is missing, extract both
      if (map['month'] is String && (map['year'] == null)) {
        final monthStr = map['month'] as String;
        if (monthStr.contains('-')) {
          final parts = monthStr.split('-');
          if (parts.length == 2) {
            year = int.tryParse(parts[0]) ?? year;
            month = int.tryParse(parts[1]) ?? month;
          }
        }
      }

      return Budget(
        id: map['id']?.toString() ?? 'unknown',
        userId: map['user_id'] as String? ?? 'unknown',
        amount: amount,
        currency: map['currency'] as String? ?? 'NPR',
        month: month,
        year: year,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: map['updated_at'] != null
            ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing Budget: $e with data: $map');
      // Return fallback budget
      return Budget(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'unknown',
        amount: 0.0,
        month: DateTime.now().month,
        year: DateTime.now().year,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
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
  } // Get human-readable month name

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
