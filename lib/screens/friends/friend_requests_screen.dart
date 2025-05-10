import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/friend_request.dart';
import 'package:flutter_finance_app/providers/friends_provider.dart';
import 'package:provider/provider.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  _FriendRequestsScreenState createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  Future<void> _loadFriendRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<FriendsProvider>(context, listen: false)
          .fetchFriendRequests();
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
        title: const Text('Friend Requests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<FriendsProvider>(
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
                          onPressed: _loadFriendRequests,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final requests = friendsProvider.friendRequests;
                if (requests.isEmpty) {
                  return const Center(
                    child: Text(
                      'No pending friend requests',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _buildFriendRequestCard(requests[index]);
                  },
                );
              },
            ),
    );
  }

  Widget _buildFriendRequestCard(FriendRequest request) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: request.avatarUrl != null
                      ? NetworkImage(request.avatarUrl!)
                      : null,
                  child: request.avatarUrl == null
                      ? Text(request.fullName[0].toUpperCase())
                      : null,
                  radius: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested ${_formatDate(request.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _respondToRequest(request.id, 'reject'),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _respondToRequest(request.id, 'accept'),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respondToRequest(String requestId, String action) async {
    setState(() {
      _isLoading = true;
    });

    final friendsProvider =
        Provider.of<FriendsProvider>(context, listen: false);

    try {
      bool success;
      if (action == 'accept') {
        success = await friendsProvider.acceptFriendRequest(requestId);
      } else {
        success = await friendsProvider.rejectFriendRequest(requestId);
      }

      if (success) {
        // Refresh the list after response
        await friendsProvider.fetchFriendRequests();

        if (action == 'accept') {
          // Also refresh friends list if we accepted
          await friendsProvider.fetchFriendsList();
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                action == 'accept'
                    ? 'Friend request accepted!'
                    : 'Friend request declined',
              ),
              backgroundColor:
                  action == 'accept' ? Colors.green : Colors.grey[600],
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${friendsProvider.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Error handled in provider
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    // Format date as 'Today', 'Yesterday', or 'MM/DD/YYYY'
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
