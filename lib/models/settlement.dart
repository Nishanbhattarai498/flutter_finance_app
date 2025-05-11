import 'package:flutter/foundation.dart';

class Settlement {
  final String id;
  final double amount;
  final String payerId;
  final String receiverId;
  final String? groupId;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? payer;
  final Map<String, dynamic>? receiver;
  final Map<String, dynamic>? group;

  Settlement({
    required this.id,
    required this.amount,
    required this.payerId,
    required this.receiverId,
    this.groupId,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.payer,
    this.receiver,
    this.group,
  });
  factory Settlement.fromJson(Map<String, dynamic> json) {
    try {
      return Settlement(
        id: json['id'] as String? ?? 'unknown',
        amount: json['amount'] != null
            ? (json['amount'] is num
                ? (json['amount'] as num).toDouble()
                : double.tryParse(json['amount'].toString()) ?? 0.0)
            : 0.0,
        payerId: json['payer_id'] as String? ?? 'unknown',
        receiverId: json['receiver_id'] as String? ?? 'unknown',
        groupId: json['group_id'] as String?,
        status: json['status'] as String? ?? 'unknown',
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'].toString())
            : null,
        payer: json['payer'] is Map
            ? Map<String, dynamic>.from(json['payer'])
            : null,
        receiver: json['receiver'] is Map
            ? Map<String, dynamic>.from(json['receiver'])
            : null,
        group: json['group'] is Map
            ? Map<String, dynamic>.from(json['group'])
            : null,
      );
    } catch (e) {
      print('Error parsing Settlement: $e with data: $json');
      // Return a fallback settlement to prevent app crashes
      return Settlement(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        amount: 0.0,
        payerId: 'unknown',
        receiverId: 'unknown',
        status: 'error',
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'payer_id': payerId,
      'receiver_id': receiverId,
      'group_id': groupId,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'payer': payer,
      'receiver': receiver,
      'group': group,
    };
  }

  Settlement copyWith({
    String? id,
    double? amount,
    String? payerId,
    String? receiverId,
    String? groupId,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? payer,
    Map<String, dynamic>? receiver,
    Map<String, dynamic>? group,
  }) {
    return Settlement(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      payerId: payerId ?? this.payerId,
      receiverId: receiverId ?? this.receiverId,
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      payer: payer ?? this.payer,
      receiver: receiver ?? this.receiver,
      group: group ?? this.group,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Settlement &&
        other.id == id &&
        other.amount == amount &&
        other.payerId == payerId &&
        other.receiverId == receiverId &&
        other.groupId == groupId &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        amount.hashCode ^
        payerId.hashCode ^
        receiverId.hashCode ^
        groupId.hashCode ^
        status.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  String get payerName {
    if (payer != null && payer!['full_name'] != null) {
      return payer!['full_name'];
    }
    return 'Unknown User';
  }

  String get receiverName {
    if (receiver != null && receiver!['full_name'] != null) {
      return receiver!['full_name'];
    }
    return 'Unknown User';
  }
}
