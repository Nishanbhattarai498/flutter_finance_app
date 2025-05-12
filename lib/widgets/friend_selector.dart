import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/friend.dart';
import 'package:flutter_finance_app/providers/friends_provider.dart';
import 'package:provider/provider.dart';

class FriendSelector extends StatefulWidget {
  final List<String> selectedFriends;
  final ValueChanged<List<String>> onFriendsSelected;
  final int? maxSelection; // Maximum number of friends that can be selected

  const FriendSelector({
    Key? key,
    required this.selectedFriends,
    required this.onFriendsSelected,
    this.maxSelection,
  }) : super(key: key);

  @override
  State<FriendSelector> createState() => _FriendSelectorState();
}

class _FriendSelectorState extends State<FriendSelector> {
  bool _loading = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    setState(() => _loading = true);
    try {
      // Load friend data
      await Provider.of<FriendsProvider>(context, listen: false)
          .fetchFriendsList();
    } catch (_) {
      // Error handled in provider
    } finally {
      setState(() => _loading = false);
    }
  }

  void _toggleFriend(String friendId) {
    final selectedFriends = List<String>.from(widget.selectedFriends);
    if (selectedFriends.contains(friendId)) {
      selectedFriends.remove(friendId);
    } else {
      // Check if we've reached the maximum selection limit
      if (widget.maxSelection != null &&
          selectedFriends.length >= widget.maxSelection!) {
        // If we have a maximum and we've reached it, replace the last selection
        if (widget.maxSelection == 1) {
          selectedFriends.clear();
        } else {
          // Show a message if we're over the limit (but not for single selection)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('You can only select ${widget.maxSelection} friends'),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      }
      selectedFriends.add(friendId);
    }
    widget.onFriendsSelected(selectedFriends);
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);
    final allFriends = friendsProvider.friends;

    // Filter by search term
    final filteredFriends = _search.isEmpty
        ? allFriends
        : allFriends.where((friend) {
            final nameMatch =
                friend.fullName.toLowerCase().contains(_search.toLowerCase());
            final emailMatch =
                friend.email.toLowerCase().contains(_search.toLowerCase());
            return nameMatch || emailMatch;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search friends',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _search = value;
            });
          },
        ),
        const SizedBox(height: 16),
        _loading
            ? const Center(child: CircularProgressIndicator())
            : filteredFriends.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        allFriends.isEmpty
                            ? 'You have no friends yet. Add friends in the Friends tab.'
                            : 'No friends found matching "$_search"',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      ...filteredFriends.map((friend) {
                        final isSelected =
                            widget.selectedFriends.contains(friend.id);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            backgroundImage: friend.avatarUrl != null
                                ? NetworkImage(friend.avatarUrl!)
                                : null,
                            child: friend.avatarUrl == null
                                ? Text(friend.fullName[0].toUpperCase())
                                : null,
                          ),
                          title: Text(friend.fullName),
                          subtitle: Text(friend.email),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleFriend(friend.id),
                          ),
                          onTap: () => _toggleFriend(friend.id),
                        );
                      }).toList(),
                    ],
                  ),
        const SizedBox(height: 16),
        if (widget.selectedFriends.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Selected Friends (${widget.selectedFriends.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ...widget.selectedFriends.map((friendId) {
            final friend = allFriends.firstWhere(
              (f) => f.id == friendId,
              orElse: () => Friend(
                id: friendId,
                friendshipId: 'unknown',
                fullName: 'Unknown User',
                email: 'user@example.com',
                createdAt: DateTime.now(),
              ),
            );

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage: friend.avatarUrl != null
                    ? NetworkImage(friend.avatarUrl!)
                    : null,
                child: friend.avatarUrl == null
                    ? Text(friend.fullName[0].toUpperCase())
                    : null,
              ),
              title: Text(friend.fullName),
              subtitle: Text(friend.email),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _toggleFriend(friendId),
                color: Colors.red,
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}
