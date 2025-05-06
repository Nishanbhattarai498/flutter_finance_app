class Settlement {
  final int id;
  final String payerId;
  final String receiverId;
  final double amount;
  final String? notes;
  final DateTime createdAt;
  final Map<String, dynamic>? payer;
  final Map<String, dynamic>? receiver;

  Settlement({
    required this.id,
    required this.payerId,
    required this.receiverId,
    required this.amount,
    this.notes,
    required this.createdAt,
    this.payer,
    this.receiver,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'],
      payerId: json['payer_id'],
      receiverId: json['receiver_id'],
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      payer: json['payer'],
      receiver: json['receiver'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payer_id': payerId,
      'receiver_id': receiverId,
      'amount': amount,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
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
