import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/friend.dart';
import 'package:flutter_finance_app/providers/friends_provider.dart';
import 'package:provider/provider.dart';

class SingleFriendSelector extends StatefulWidget {
  final String? selectedFriendId;
  final Function(String?) onFriendSelected;

  const SingleFriendSelector({
    Key? key,
    this.selectedFriendId,
    required this.onFriendSelected,
  }) : super(key: key);

  @override
  _SingleFriendSelectorState createState() => _SingleFriendSelectorState();
}

class _SingleFriendSelectorState extends State<SingleFriendSelector> {
  String _search = '';
  bool _isLoading = false;
  String? _selectedFriendId;

  @override
  void initState() {
    super.initState();
    _selectedFriendId = widget.selectedFriendId;
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<FriendsProvider>(context, listen: false)
          .fetchFriendsList();
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

  void _selectFriend(String? friendId) {
    setState(() {
      _selectedFriendId = friendId;
    });
    widget.onFriendSelected(friendId);
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);
    final friends = friendsProvider.friends;

    // Filter friends by search term if active
    final filteredFriends = _search.isEmpty
        ? friends
        : friends.where((friend) {
            final nameMatch =
                friend.fullName.toLowerCase().contains(_search.toLowerCase());
            final emailMatch =
                friend.email.toLowerCase().contains(_search.toLowerCase());
            return nameMatch || emailMatch;
          }).toList();

    // Find the selected friend
    final selectedFriend = _selectedFriendId != null
        ? friends.firstWhere(
            (friend) => friend.id == _selectedFriendId,
            orElse: () => Friend(
              id: '',
              friendshipId: '',
              fullName: 'Unknown',
              email: '',
              createdAt: DateTime.now(),
            ),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedFriend != null)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(selectedFriend.fullName[0].toUpperCase()),
              ),
              title: Text(selectedFriend.fullName),
              subtitle: Text(selectedFriend.email),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _selectFriend(null),
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search friends',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _search = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (friends.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You have no friends yet',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add some friends in the Friends tab to continue',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else if (filteredFriends.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No friends found matching "$_search"',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = filteredFriends[index];
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
                        onTap: () => _selectFriend(friend.id),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
