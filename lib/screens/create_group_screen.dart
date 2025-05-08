import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/widgets/custom_text_field.dart';
import 'package:flutter_finance_app/widgets/custom_button.dart';
import 'package:flutter_finance_app/widgets/friend_selector.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _selectedFriends = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final groupData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'created_by': context.read<AuthProvider>().userId,
        'members': _selectedFriends,
        'created_at': DateTime.now().toIso8601String(),
      };

      final success = await context.read<GroupProvider>().createGroup(groupData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<GroupProvider>().errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              controller: _nameController,
              label: 'Group Name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a group name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Description (Optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Friends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FriendSelector(
              selectedFriends: _selectedFriends,
              onFriendsSelected: (friends) {
                setState(() => _selectedFriends = friends);
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              onPressed: _isLoading ? null : _createGroup,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
} 