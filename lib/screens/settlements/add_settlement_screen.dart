import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/group.dart';
import 'package:flutter_finance_app/models/group_member.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/widgets/custom_button.dart';
import 'package:flutter_finance_app/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class AddSettlementScreen extends StatefulWidget {
  const AddSettlementScreen({Key? key}) : super(key: key);

  @override
  _AddSettlementScreenState createState() => _AddSettlementScreenState();
}

class _AddSettlementScreenState extends State<AddSettlementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  Group? _selectedGroup;
  String? _selectedPayerId;
  String? _selectedReceiverId;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.userId != null) {
      await groupProvider.fetchUserGroups(authProvider.userId!);

      // Set current user as payer by default
      setState(() {
        _selectedPayerId = authProvider.userId;
      });
    }
  }

  Future<void> _saveSettlement() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      if (authProvider.userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        return;
      }

      if (_selectedPayerId == null || _selectedReceiverId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select payer and receiver')),
        );
        return;
      }

      // Create settlement data
      final settlementData = {
        'payer_id': _selectedPayerId,
        'receiver_id': _selectedReceiverId,
        'amount': double.parse(_amountController.text),
        'notes': _notesController.text.trim(),
        'group_id': _selectedGroup?.id,
        'created_at': DateTime.now().toIso8601String(),
      };

      final success = await groupProvider.addSettlement(settlementData);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settlement recorded successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(groupProvider.errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);

    final groups = groupProvider.groups;
    final currentUserId = authProvider.userId;

    // Get all members from the selected group
    List<GroupMember> groupMembers = [];
    if (_selectedGroup != null) {
      groupMembers = _selectedGroup!.members;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Record Settlement')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Amount
              CustomTextField(
                controller: _amountController,
                label: 'Amount',
                hint: '0.00',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  try {
                    final amount = double.parse(value);
                    if (amount <= 0) {
                      return 'Amount must be greater than zero';
                    }
                  } catch (e) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Group (optional)
              DropdownButtonFormField<Group?>(
                value: _selectedGroup,
                decoration: InputDecoration(
                  labelText: 'Group (Optional)',
                  prefixIcon: const Icon(Icons.group_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem<Group?>(
                    value: null,
                    child: Text('Personal Settlement'),
                  ),
                  ...groups.map((group) {
                    return DropdownMenuItem<Group>(
                      value: group,
                      child: Text(group.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGroup = value;
                    _selectedPayerId = currentUserId;
                    _selectedReceiverId = null;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Payer and receiver
              Text(
                'Who paid whom?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Payer
              DropdownButtonFormField<String>(
                value: _selectedPayerId,
                decoration: InputDecoration(
                  labelText: 'Payer',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: currentUserId,
                    child: const Text('You'),
                  ),
                  ...groupMembers
                      .where((member) => member.userId != currentUserId)
                      .map((member) {
                        return DropdownMenuItem<String>(
                          value: member.userId,
                          child: Text(member.displayName),
                        );
                      }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPayerId = value;

                    // If receiver is same as payer, reset receiver
                    if (_selectedReceiverId == value) {
                      _selectedReceiverId = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Receiver
              DropdownButtonFormField<String>(
                value: _selectedReceiverId,
                decoration: InputDecoration(
                  labelText: 'Receiver',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  if (_selectedPayerId != currentUserId)
                    DropdownMenuItem<String>(
                      value: currentUserId,
                      child: const Text('You'),
                    ),
                  ...groupMembers
                      .where(
                        (member) =>
                            member.userId != _selectedPayerId &&
                            member.userId != currentUserId,
                      )
                      .map((member) {
                        return DropdownMenuItem<String>(
                          value: member.userId,
                          child: Text(member.displayName),
                        );
                      }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedReceiverId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a receiver';
                  }
                  if (value == _selectedPayerId) {
                    return 'Receiver cannot be the same as payer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Notes (optional)
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Add any additional notes',
                prefixIcon: Icons.note_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Save button
              CustomButton(
                text: 'Record Settlement',
                isLoading: groupProvider.isLoading,
                onPressed: _saveSettlement,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
