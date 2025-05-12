# Settlement Functionality Enhancement Guide (Updated)

This guide explains the implementation of the settlement functionality in your Flutter Finance App, ensuring that settlements are visible to both parties and proper notifications are sent.

## Overview of Files Created

1. **SupabaseServiceFix** (in `lib/services/supabase_service_settlement.dart`)
   - Contains properly fixed implementations of all settlement-related methods
   - Uses `Supabase.instance.client` instead of `_client` for better reliability
   - Includes notification support

2. **FixedSettlementProvider** (in `lib/providers/fixed_settlement_provider_new.dart`)
   - Updated version of the settlement provider that works with SupabaseServiceFix
   - Includes support for AuthProvider to identify the current user
   - Implements marking settlements as paid with notifications

## Core Functionality

### 1. Viewing Settlements
The `getUserSettlements()` method now fetches settlements where the user is either the payer or receiver:
```dart
static Future<List<Map<String, dynamic>>> getUserSettlements() async {
  final user = await Supabase.instance.client.auth.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }
  
  // Fetch settlements where the current user is either payer or receiver
  final response = await Supabase.instance.client
      .from('settlements')
      .select()
      .or('payer_id.eq.${user.id},receiver_id.eq.${user.id}')
      .order('created_at', ascending: false);
  
  return response;
}
```

### 2. Creating Settlements with Notifications
When a settlement is created, notifications are sent to both parties:
```dart
static Future<Map<String, dynamic>> createSettlement(
    Map<String, dynamic> data) async {
  // ...
  
  // Insert the settlement
  final response = await Supabase.instance.client.from('settlements').insert(data).select().single();

  try {
    // If the current user is NOT the payer, create notification for payer
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

    // If the current user is NOT the receiver, create notification for receiver
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

### 3. Marking Settlements as Paid
The `markSettlementAsPaid` method now:
- Updates the settlement status to "completed"
- Notifies the other party
```dart
Future<bool> markSettlementAsPaid(String settlementId) async {
  // ...update settlement...
  
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
    await SupabaseServiceFix.createNotification({
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
  
  // ...
}
```

### 4. Deleting Settlements
Both the payer and receiver can now delete settlements:
```dart
static Future<void> deleteSettlement(String settlementId) async {
  // ...
  
  // Verify this settlement involves the current user (as payer or receiver)
  final checkResponse = await Supabase.instance.client
      .from('settlements')
      .select('id')
      .eq('id', settlementId)
      .or('payer_id.eq.${user.id},receiver_id.eq.${user.id}')
      .maybeSingle();
      
  // ...
}
```

## UI Implementation

The settlement card UI has been enhanced to include a "Mark as Paid" button and a "Delete" button for pending settlements. These buttons are only visible when the settlement status is not "completed".

## How to use the updated code

1. Use the FixedSettlementProvider in your screens instead of the original SettlementProvider
2. Make sure to provide both the CacheManager and AuthProvider when creating the provider
3. All other functionality remains the same - the API is compatible with the original provider
