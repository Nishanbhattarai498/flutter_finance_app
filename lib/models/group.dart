import 'package:flutter_finance_app/models/expense.dart';
import 'package:flutter_finance_app/models/group_member.dart';

class Group {
  final int id;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final List<GroupMember> members;
  final List<Expense> expenses;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    required this.members,
    this.expenses = const [],
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    List<GroupMember> members = [];
    if (json['members'] != null) {
      members = List<GroupMember>.from(
        (json['members'] as List).map((x) => GroupMember.fromJson(x)),
      );
    }

    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      members: members,
      expenses: [], // Expenses are loaded separately
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Group copyWith({
    int? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    List<GroupMember>? members,
    List<Expense>? expenses,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
    );
  }
}
