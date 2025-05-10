import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/friend.dart';
import 'package:flutter_finance_app/providers/friends_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/screens/groups/group_details_screen.dart';
import 'package:flutter_finance_app/widgets/custom_button.dart';
import 'package:flutter_finance_app/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> selectedFriendIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load friends if not already loaded
      await Provider.of<FriendsProvider>(context, listen: false)
          .fetchFriendsList();
    } catch (e) {
      // Error handled in the provider
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleFriendSelection(String friendId) {
    setState(() {
      if (selectedFriendIds.contains(friendId)) {
        selectedFriendIds.remove(friendId);
      } else {
        selectedFriendIds.add(friendId);
      }
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one friend')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      // Add the user IDs to the group data
      final groupData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'members': [
          ...selectedFriendIds,
        ],
      };

      final isSuccess = await groupProvider.createGroup(groupData);
      if (isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        ); // Navigate to group details
        await groupProvider.fetchUserGroups();
        if (groupProvider.groups.isNotEmpty) {
          final createdGroup = groupProvider.groups.first;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailsScreen(group: createdGroup),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to create group: ${groupProvider.errorMessage}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);
    final friends = friendsProvider.friends;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        label: 'Group Name',
                        hint: 'Enter a name for your group',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a group name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description (Optional)',
                        hint: 'Enter a description for your group',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Select Friends',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (friends.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
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
                                  'Add friends in the Friends tab before creating a group',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: () {
                                    // Navigate to Friends tab
                                    Navigator.pop(context);
                                    // Set the Friends tab index (2) in the bottom navigation
                                    // This will be handled by the parent widget
                                  },
                                  child: const Text('Go to Friends'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              final friend = friends[index];
                              final isSelected =
                                  selectedFriendIds.contains(friend.id);

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
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
                                  onChanged: (_) =>
                                      _toggleFriendSelection(friend.id),
                                ),
                                onTap: () => _toggleFriendSelection(friend.id),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Create Group',
                        onPressed: _createGroup,
                        isLoading: _isLoading,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
