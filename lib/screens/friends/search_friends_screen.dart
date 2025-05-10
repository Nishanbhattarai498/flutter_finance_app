import 'package:flutter/material.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/friends_provider.dart';
import 'package:provider/provider.dart';

class SearchFriendsScreen extends StatefulWidget {
  const SearchFriendsScreen({Key? key}) : super(key: key);

  @override
  _SearchFriendsScreenState createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    if (_searchController.text.length < 3) {
      return;
    }

    await _searchUsers(_searchController.text);
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Provider.of<AuthProvider>(context, listen: false)
          .searchUsers(query);

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Friends'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name or email',
                hintText: 'Enter at least 3 characters',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 20.0,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) async {
                if (_searchController.text.length >= 3) {
                  await _searchUsers(_searchController.text);
                }
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isEmpty && _searchController.text.length >= 3)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('No users found. Try a different search term.'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  final bool isFriend = friendsProvider.isFriend(user['id']);
                  final bool hasPendingRequest =
                      friendsProvider.hasPendingRequest(user['id']);

                  return Card(
                    elevation: 2,
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        backgroundImage: user['avatar_url'] != null
                            ? NetworkImage(user['avatar_url'])
                            : null,
                        child: user['avatar_url'] == null
                            ? Text(user['full_name'][0].toUpperCase())
                            : null,
                      ),
                      title: Text(user['full_name']),
                      subtitle: Text(user['email']),
                      trailing: isFriend
                          ? const Chip(
                              label: Text('Friend'),
                              backgroundColor: Colors.green,
                              labelStyle: TextStyle(color: Colors.white),
                            )
                          : hasPendingRequest
                              ? const Chip(
                                  label: Text('Pending'),
                                  backgroundColor: Colors.orange,
                                  labelStyle: TextStyle(color: Colors.white),
                                )
                              : ElevatedButton(
                                  onPressed: () async {
                                    final success = await friendsProvider
                                        .sendFriendRequest(user['id']);
                                    if (success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Friend request sent!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      // Refresh the screen
                                      setState(() {});
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Error: ${friendsProvider.errorMessage}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Add'),
                                ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
