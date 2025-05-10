import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';

class FriendSelector extends StatefulWidget {
  final List<String> selectedFriends;
  final ValueChanged<List<String>> onFriendsSelected;

  const FriendSelector({
    Key? key,
    required this.selectedFriends,
    required this.onFriendsSelected,
  }) : super(key: key);

  @override
  State<FriendSelector> createState() => _FriendSelectorState();
}

class _FriendSelectorState extends State<FriendSelector> {
  List<Map<String, dynamic>> _friends = [];
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final results = await authProvider.searchUsers(_search);
      setState(() => _friends = results);
    } catch (_) {
      setState(() => _friends = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search friends',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() => _search = value);
            _fetchFriends();
          },
        ),
        const SizedBox(height: 8),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (!_loading)
          ..._friends.map((user) {
            final userId = user['id'];
            final isSelected = widget.selectedFriends.contains(userId);
            return ListTile(
              leading: CircleAvatar(
                child: Text(user['email']?[0]?.toUpperCase() ?? '?'),
              ),
              title: Text(user['email'] ?? ''),
              trailing: Checkbox(
                value: isSelected,
                onChanged: (checked) {
                  final updated = List<String>.from(widget.selectedFriends);
                  if (checked == true) {
                    if (!updated.contains(userId)) updated.add(userId);
                  } else {
                    updated.remove(userId);
                  }
                  widget.onFriendsSelected(updated);
                },
              ),
            );
          }).toList(),
        if (widget.selectedFriends.isNotEmpty)
          Wrap(
            spacing: 8,
            children: widget.selectedFriends.map((userId) {
              final user = _friends.firstWhere(
                (u) => u['id'] == userId,
                orElse: () => {'email': userId},
              );
              return Chip(
                label: Text(user['email'] ?? userId),
                onDeleted: () {
                  final updated = List<String>.from(widget.selectedFriends);
                  updated.remove(userId);
                  widget.onFriendsSelected(updated);
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}
