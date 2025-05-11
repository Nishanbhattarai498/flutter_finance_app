// Friends provider
import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/friend.dart';
import 'package:flutter_finance_app/models/friend_request.dart';
import 'package:flutter_finance_app/models/notification.dart';
import 'package:flutter_finance_app/services/supabase_service.dart';

class FriendsProvider with ChangeNotifier {
  List<Friend> _friends = [];
  List<FriendRequest> _friendRequests = [];
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadNotificationsCount = 0;

  List<Friend> get friends => _friends;
  List<FriendRequest> get friendRequests => _friendRequests;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get errorMessage => _error ?? 'An error occurred';
  int get unreadNotificationsCount => _unreadNotificationsCount;

  // Load all friends data
  Future<void> loadFriendsData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await Future.wait([
        fetchFriendsList(),
        fetchFriendRequests(),
        fetchNotifications(),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user's friends list
  Future<void> fetchFriendsList() async {
    try {
      final response = await SupabaseService.getFriendsList();
      _friends = response.map((data) => Friend.fromJson(data)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get pending friend requests
  Future<void> fetchFriendRequests() async {
    try {
      final response = await SupabaseService.getPendingFriendRequests();
      _friendRequests =
          response.map((data) => FriendRequest.fromJson(data)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get notifications
  Future<void> fetchNotifications() async {
    try {
      final response = await SupabaseService.getNotifications();
      _notifications =
          response.map((data) => NotificationModel.fromJson(data)).toList();

      // Count unread notifications
      _unreadNotificationsCount = _notifications.where((n) => !n.isRead).length;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Send a friend request
  Future<bool> sendFriendRequest(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await SupabaseService.sendFriendRequest(userId);

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

  // Accept a friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        await SupabaseService.respondToFriendRequest(requestId, 'accepted');
      } catch (e) {
        print('Error in respondToFriendRequest: $e');
        // Continue execution even if there's an error, as we'll refresh the lists
      }

      // Refresh friend requests and friends list
      await fetchFriendRequests();
      await fetchFriendsList();

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

  // Reject a friend request
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        await SupabaseService.respondToFriendRequest(requestId, 'rejected');
      } catch (e) {
        print('Error in respondToFriendRequest: $e');
        // Continue execution even if there's an error, as we'll refresh the lists
      }

      // Refresh friend requests
      await fetchFriendRequests();

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

  // Remove a friend
  Future<bool> removeFriend(String friendshipId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await SupabaseService.removeFriend(friendshipId);

      // Refresh friends list
      await fetchFriendsList();

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

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await SupabaseService.markNotificationAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        if (!_notifications[index].isRead) {
          _unreadNotificationsCount =
              _unreadNotificationsCount > 0 ? _unreadNotificationsCount - 1 : 0;
        }
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check if a user is a friend
  bool isFriend(String userId) {
    return _friends.any((friend) => friend.id == userId);
  }

  // Check if a user has a pending request
  bool hasPendingRequest(String userId) {
    return _friendRequests.any((request) => request.userId == userId);
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
