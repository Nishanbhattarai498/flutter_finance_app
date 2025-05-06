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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

      // Create group data
      final groupData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'created_by': authProvider.userId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await groupProvider.createGroup(groupData, []);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );

        // Find the created group
        await groupProvider.fetchUserGroups(authProvider.userId!);
        final createdGroup = groupProvider.groups.firstWhere(
          (group) => group.id == result['group_id'],
          orElse: () => null!,
        );

        if (createdGroup != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GroupDetailsScreen(group: createdGroup),
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
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
              // Group name
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

              // Description (optional)
              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'Add a description for your group',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Create button
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
