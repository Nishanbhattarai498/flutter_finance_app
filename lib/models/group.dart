import 'package:flutter/foundation.dart';
import 'package:flutter_finance_app/models/expense.dart';
import 'package:flutter_finance_app/models/group_member.dart';

class Group {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<GroupMember> members;
  final List<Expense> expenses;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    required this.members,
    required this.expenses,
  });
  factory Group.fromJson(Map<String, dynamic> json) {
    try {
      return Group(
        id: json['id'] as String? ?? 'unknown',
        name: json['name'] as String? ?? 'Unnamed Group',
        description: json['description'] as String?,
        createdBy: json['created_by'] as String? ?? 'unknown',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'].toString())
            : null,
        members: _parseMembersList(json['group_members']),
        expenses: _parseExpensesList(json['expenses']),
      );
    } catch (e) {
      print('Error parsing Group: $e with data: $json');
      // Return a fallback group to prevent app crashes
      return Group(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Error Loading Group',
        createdBy: 'unknown',
        createdAt: DateTime.now(),
        members: [],
        expenses: [],
      );
    }
  }

  // Helper methods to parse lists safely
  static List<GroupMember> _parseMembersList(dynamic membersData) {
    if (membersData == null) return [];

    try {
      if (membersData is List) {
        return membersData
            .map((m) =>
                m is Map<String, dynamic> ? GroupMember.fromJson(m) : null)
            .whereType<GroupMember>()
            .toList();
      }
    } catch (e) {
      print('Error parsing group members: $e');
    }

    return [];
  }

  static List<Expense> _parseExpensesList(dynamic expensesData) {
    if (expensesData == null) return [];

    try {
      if (expensesData is List) {
        return expensesData
            .map((e) => e is Map<String, dynamic> ? Expense.fromJson(e) : null)
            .whereType<Expense>()
            .toList();
      }
    } catch (e) {
      print('Error parsing group expenses: $e');
    }

    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'group_members': members.map((m) => m.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<GroupMember>? members,
    List<Expense>? expenses,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        listEquals(other.members, members) &&
        listEquals(other.expenses, expenses);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        createdBy.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        members.hashCode ^
        expenses.hashCode;
  }
}
