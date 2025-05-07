import 'package:flutter/material.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
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
  final _searchController = TextEditingController();
  List<String> selectedFriends = [];
  List<Map<String, dynamic>> searchResults = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFriends(String query) async {
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    try {
      final results = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).searchUsers(query);
      setState(() => searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to search users: $e')));
    }
  }

  void _toggleFriendSelection(String userId) {
    setState(() {
      if (selectedFriends.contains(userId)) {
        selectedFriends.remove(userId);
      } else {
        selectedFriends.add(userId);
      }
    });
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      if (authProvider.userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        return;
      }

      final groupData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'created_by': authProvider.userId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await groupProvider.createGroup(
        groupData,
        selectedFriends,
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );

        await groupProvider.fetchUserGroups(authProvider.userId!);
        final createdGroup = groupProvider.groups.firstWhere(
          (group) => group.id == result['group_id'],
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GroupDetailsScreen(group: createdGroup),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create group'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Group Name',
                hint: 'Enter a name for your group',
                prefixIcon: Icons.group_outlined,
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
                hint: 'Add a description for your group',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Friend search section
              Text(
                'Add Friends to Group',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              CustomTextField(
                controller: _searchController,
                label: 'Search Friends',
                hint: 'Enter name or email',
                prefixIcon: Icons.search,
                onChanged: _searchFriends,
              ),

              // Search results
              if (searchResults.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: searchResults.map((user) {
                      final userId = user['id'];
                      final isSelected = selectedFriends.contains(userId);
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(user['email'][0].toUpperCase()),
                        ),
                        title: Text(user['email']),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: isSelected ? Colors.green : Colors.grey,
                        ),
                        onTap: () => _toggleFriendSelection(userId),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Selected friends chips
              if (selectedFriends.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: selectedFriends.map((userId) {
                    final user = searchResults.firstWhere(
                      (user) => user['id'] == userId,
                    );
                    return Chip(
                      label: Text(user['email']),
                      onDeleted: () => _toggleFriendSelection(userId),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 32),

              CustomButton(
                text: 'Create Group',
                isLoading: groupProvider.isLoading,
                onPressed: _createGroup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
