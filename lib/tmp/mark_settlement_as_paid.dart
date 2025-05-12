// Add this method to fixed_settlement_provider.dart
Future<bool> markSettlementAsPaid(String settlementId) async {
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await SupabaseService.updateSettlement(
      settlementId, 
      {'status': 'completed', 'updated_at': DateTime.now().toIso8601String()}
    );

    final updatedSettlement = Settlement.fromJson(response);
    final index = _settlements.indexWhere((s) => s.id == settlementId);
    if (index != -1) {
      _settlements[index] = updatedSettlement;
    }

    // Update cache
    final cachedSettlements = await _cacheManager.getCachedSettlements() ?? [];
    final cacheIndex = cachedSettlements.indexWhere((s) => s['id'] == settlementId);
    if (cacheIndex != -1) {
      cachedSettlements[cacheIndex] = response;
      await _cacheManager.cacheSettlements(cachedSettlements);
    }

    // Create notification for the other party
    try {
      final currentUserId = _authProvider.userId;
      String otherUserId;
      
      // Determine the other user to notify
      if (updatedSettlement.payerId == currentUserId) {
        otherUserId = updatedSettlement.receiverId;
      } else {
        otherUserId = updatedSettlement.payerId;
      }
      
      // Create notification for the other user
      await SupabaseService.createNotification({
        'user_id': otherUserId,
        'sender_id': currentUserId,
        'type': 'settlement_paid',
        'content': 'A settlement has been marked as paid',
        'is_read': false,
        'settlement_id': settlementId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating settlement paid notification: $e');
      // Continue even if notification creation fails
    }

    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
