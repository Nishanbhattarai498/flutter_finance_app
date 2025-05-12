# Settlement Functionality Enhancement Guide

This guide explains how to fix the settlement functionality in your Flutter Finance App so that settlements are visible to both parties involved and proper notifications are sent.

## Overview of Changes

1. **Fixed `getUserSettlements()`** ✅
   - Already modified to fetch settlements where the current user is either payer or receiver
   - Uses `.or('payer_id.eq.${user.id},receiver_id.eq.${user.id}')`

2. **Fixed `createSettlement()`** ✅
   - Already removed the unnecessary `user_id` field
   - Now properly sets `payer_id` and `receiver_id`

3. **Fixed `updateSettlement()`** ✅
   - Already modified to allow updates by either payer or receiver

4. **Fixed `deleteSettlement()`** ✅
   - Already modified to allow deletion by either payer or receiver

## Step 1: Add Notification Support

1. Add a `createNotification()` method to `SupabaseService`:

```dart
static Future<void> createNotification(Map<String, dynamic> data) async {
  final user = await _client.auth.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  // Make sure required fields are present
  if (!data.containsKey('user_id') || !data.containsKey('type') || !data.containsKey('content')) {
    throw Exception('Notification must have user_id, type, and content');
  }

  await _client.from('notifications').insert(data);
}
```

## Step 2: Update the SettlementProvider

1. Modify the SettlementProvider constructor to accept an AuthProvider:

```dart
import 'package:flutter_finance_app/providers/auth_provider.dart';

class SettlementProvider with ChangeNotifier {
  final CacheManager _cacheManager;
  final AuthProvider _authProvider;
  List<Settlement> _settlements = [];
  bool _isLoading = false;
  String? _error;

  SettlementProvider(this._cacheManager, this._authProvider);
  
  // ... rest of the class
}
```

2. Update the `markSettlementAsPaid` method to include notification creation:

```dart
Future<bool> markSettlementAsPaid(String settlementId) async {
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final response = await SupabaseService.updateSettlement(
      settlementId,
      {
        'status': 'completed', 
        'updated_at': DateTime.now().toIso8601String()
      },
    );
    
    final updatedSettlement = Settlement.fromJson(response);
    final index = _settlements.indexWhere((s) => s.id == settlementId);
    if (index != -1) {
      _settlements[index] = updatedSettlement;
    }

    // Update cache
    final cachedSettlements =
        await _cacheManager.getCachedSettlements() ?? [];
    final cacheIndex =
        cachedSettlements.indexWhere((s) => s['id'] == settlementId);
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
```

## Step 3: Update the SettlementCard UI

Update the `_SettlementCard` widget in your settlements_screen.dart file or create a new enhanced card:

```dart
class EnhancedSettlementCard extends StatelessWidget {
  final Settlement settlement;

  const EnhancedSettlementCard({
    Key? key,
    required this.settlement,
  }) : super(key: key);

  String _getUserName(Map<String, dynamic>? userData) {
    if (userData == null) {
      return 'Unknown User';
    }
    return userData['full_name'] ?? 'Unknown User';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settlementProvider = Provider.of<SettlementProvider>(context);
    final currentUserId = authProvider.userId;

    final isPayer = settlement.payerId == currentUserId;
    final profitLoss = isPayer ? -settlement.amount : settlement.amount;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... existing card content ...
            
            // Add this section at the end, before the final closing brackets
            
            // Add action buttons only if settlement is pending
            if (settlement.status != 'completed') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Mark as Paid button
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldMarkAsPaid = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Mark as Paid'),
                          content: Text(
                            'Are you sure you want to mark this settlement as paid? ' +
                            'This action cannot be undone and will be visible to both parties.'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('CANCEL'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('MARK AS PAID'),
                            ),
                          ],
                        ),
                      ) ?? false;

                      if (shouldMarkAsPaid) {
                        final success = await settlementProvider.markSettlementAsPaid(settlement.id);
                        
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Settlement marked as paid')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${settlementProvider.error ?? "Failed to mark as paid"}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('MARK AS PAID'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Settlement'),
                          content: const Text('Are you sure you want to delete this settlement?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('DELETE'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ) ?? false;

                      if (shouldDelete) {
                        final success = await settlementProvider.deleteSettlement(settlement.id);
                        
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Settlement deleted')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${settlementProvider.error ?? "Failed to delete"}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('DELETE'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

Then in your SettlementsScreen, replace:
```dart
return _SettlementCard(settlement: settlement);
```

with:
```dart
return EnhancedSettlementCard(settlement: settlement);
```

## Step 4: Update the main.dart file to provide AuthProvider to SettlementProvider

Locate where you register the SettlementProvider in your main.dart (or wherever the provider is registered) and update it:

```dart
ChangeNotifierProvider(
  create: (context) => SettlementProvider(
    cacheManager,
    Provider.of<AuthProvider>(context, listen: false),
  ),
),
```

## Step 5: Test Notifications in createSettlement

Finally, update your `createSettlement` method in SupabaseService to notify both parties:

```dart
static Future<Map<String, dynamic>> createSettlement(
    Map<String, dynamic> data) async {
  final user = await _client.auth.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  // Make sure payer_id and receiver_id are set correctly
  if (!data.containsKey('payer_id') || !data.containsKey('receiver_id')) {
    throw Exception('Settlement must have payer_id and receiver_id');
  }

  // Insert the settlement
  final response =
      await _client.from('settlements').insert(data).select().single();

  try {
    // If the current user is NOT the payer, then create a notification for the payer
    if (user.id != data['payer_id']) {
      await createNotification({
        'user_id': data['payer_id'],
        'sender_id': user.id,
        'type': 'settlement',
        'content': 'You have a new settlement request',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // If the current user is NOT the receiver, then create a notification for the receiver
    if (user.id != data['receiver_id']) {
      await createNotification({
        'user_id': data['receiver_id'],
        'sender_id': user.id,
        'type': 'settlement',
        'content': 'You have a new settlement request',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  } catch (e) {
    print('Error creating settlement notification: $e');
    // Continue even if notification creation fails
  }

  return response;
}
```

## Summary

These changes will ensure that:

1. Settlements are visible to both the payer and receiver
2. Both parties can mark a settlement as paid
3. Both parties can delete a settlement
4. Notifications are sent when a settlement is created or marked as paid
5. The UI is updated to show appropriate action buttons
