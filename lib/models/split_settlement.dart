class SplitSettlement {
  final double totalAmount;
  final String payerId;
  final List<String> participantIds;
  final String? groupId;
  final String? notes;
  final Map<String, double> individualShares;
  SplitSettlement({
    required this.totalAmount,
    required this.payerId,
    required this.participantIds,
    this.groupId,
    this.notes,
    Map<String, double>? individualShares,
  }) : individualShares = individualShares ??
            _calculateIndividualShares(totalAmount, participantIds);

  // Helper method to calculate individual shares with better precision
  static Map<String, double> _calculateIndividualShares(
      double totalAmount, List<String> participantIds) {
    double perPersonShare =
        (totalAmount / (participantIds.length + 1) * 100).roundToDouble() / 100;
    return Map.fromIterable(
      participantIds,
      key: (id) => id,
      value: (_) => perPersonShare,
    );
  }

  // Calculate what each participant owes to the payer
  double getIndividualShare() {
    // Round to 2 decimal places to avoid floating point precision issues
    double share = totalAmount / (participantIds.length + 1);
    return (share * 100).roundToDouble() / 100;
  }

  // Calculate what the payer will receive in total
  double getTotalToReceive() {
    // Direct calculation to avoid potential rounding errors
    return totalAmount - getIndividualShare();
  }

  // For a participant, calculate what they owe
  double getAmountOwed(String participantId) {
    if (!participantIds.contains(participantId)) {
      return 0.0;
    }
    return individualShares[participantId] ?? getIndividualShare();
  }

  // For custom unequal splits (not implemented yet, but prepared for future)
  SplitSettlement withCustomShares(Map<String, double> customShares) {
    return SplitSettlement(
      totalAmount: totalAmount,
      payerId: payerId,
      participantIds: participantIds,
      groupId: groupId,
      notes: notes,
      individualShares: customShares,
    );
  }

  // Convert to a list of settlement data maps ready for backend storage
  List<Map<String, dynamic>> toSettlementDataList() {
    return participantIds.map((participantId) {
      return {
        'payer_id': participantId,
        'receiver_id': payerId,
        'amount': getAmountOwed(participantId),
        'notes': notes,
        'group_id': groupId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
    }).toList();
  }
}
