import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/notification.dart';
import 'package:flutter_finance_app/providers/friends_provider.dart';
import 'package:flutter_finance_app/screens/friends/friend_requests_screen.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<FriendsProvider>(context, listen: false)
          .fetchNotifications();
    } catch (e) {
      // Error is handled in the provider
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: Consumer<FriendsProvider>(
                builder: (context, friendsProvider, child) {
                  if (friendsProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${friendsProvider.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadNotifications,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final notifications = friendsProvider.notifications;
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  // Mark all as read when viewed
                  Future.delayed(Duration.zero, () async {
                    for (var notification in notifications) {
                      if (!notification.isRead) {
                        await friendsProvider
                            .markNotificationAsRead(notification.id);
                      }
                    }
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(
                          notifications[index], friendsProvider);
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildNotificationCard(
      NotificationModel notification, FriendsProvider friendsProvider) {
    IconData icon;
    Color iconColor;
    VoidCallback? onTap;

    // Configure icon and action based on notification type
    switch (notification.type) {
      case 'friend_request':
        icon = Icons.person_add;
        iconColor = Colors.blue;
        onTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FriendRequestsScreen(),
            ),
          );
        };
        break;
      case 'friend_accepted':
        icon = Icons.people;
        iconColor = Colors.green;
        break;
      case 'group_invite':
        icon = Icons.group;
        iconColor = Colors.purple;
        break;
      case 'settlement_created':
        icon = Icons.attach_money;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Card(
      elevation: notification.isRead ? 1 : 3,
      margin: const EdgeInsets.only(bottom: 8),
      color: notification.isRead ? null : Color.fromRGBO(245, 250, 255, 1),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.2),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!notification.isRead)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _getNotificationTitle(notification),
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNotificationTitle(NotificationModel notification) {
    switch (notification.type) {
      case 'friend_request':
        return 'New Friend Request';
      case 'friend_accepted':
        return 'Friend Request Accepted';
      case 'group_invite':
        return 'Group Invitation';
      case 'settlement_created':
        return 'New Settlement';
      default:
        return 'Notification';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays <= 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
