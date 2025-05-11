import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/group.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/friends_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/providers/settlement_provider.dart';
import 'package:flutter_finance_app/widgets/custom_button.dart';
import 'package:flutter_finance_app/widgets/custom_text_field.dart';
import 'package:flutter_finance_app/widgets/friend_selector.dart';
import 'package:flutter_finance_app/widgets/single_friend_selector.dart';
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
  String? _selectedFriendId; // For personal settlements
  List<String> _selectedFriendIds = []; // For group settlements
  bool _isCurrentUserPayer = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final friendsProvider =
        Provider.of<FriendsProvider>(context, listen: false);

    if (authProvider.userId != null) {
      await Future.wait([
        groupProvider.fetchUserGroups(),
        friendsProvider.fetchFriendsList(),
      ]); // Set current user as payer by default
      setState(() {
        _isCurrentUserPayer = true;
      });
    }
  }

  Future<void> _saveSettlement() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')));
        return;
      }
      if (_selectedGroup == null && _selectedFriendId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a friend')),
        );
        return;
      }

      if (_selectedGroup != null && _selectedFriendIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one friend')),
        );
        return;
      }
      final currentUserId = authProvider.userId!;
      setState(() => _isLoading = true);

      try {
        // Create settlement(s) based on whether this is a personal or group settlement
        final settlementProvider =
            Provider.of<SettlementProvider>(context, listen: false);
        final amount = double.parse(_amountController.text);
        final notes = _notesController.text.trim();
        if (_selectedGroup == null) {
          // Personal settlement - just one friend
          if (_selectedFriendId != null) {
            final settlementData = {
              'payer_id':
                  _isCurrentUserPayer ? currentUserId : _selectedFriendId,
              'receiver_id':
                  _isCurrentUserPayer ? _selectedFriendId : currentUserId,
              'amount': amount,
              'notes': notes,
              'status': 'pending',
              'created_at': DateTime.now().toIso8601String(),
            };

            print('Creating personal settlement: $settlementData');
            final success =
                await settlementProvider.createSettlement(settlementData);
            if (!success) {
              throw settlementProvider.errorMessage;
            }
          }
        } else {
          // Group settlement - multiple friends
          bool anyFailure = false;
          for (final friendId in _selectedFriendIds) {
            final settlementData = {
              'payer_id': _isCurrentUserPayer ? currentUserId : friendId,
              'receiver_id': _isCurrentUserPayer ? friendId : currentUserId,
              'amount': amount,
              'notes': notes,
              'group_id': _selectedGroup?.id,
              'status': 'pending',
              'created_at': DateTime.now().toIso8601String(),
            };

            print('Creating group settlement: $settlementData');
            final success =
                await settlementProvider.createSettlement(settlementData);
            if (!success) {
              anyFailure = true;
            }
          }

          if (anyFailure) {
            throw 'Some settlements could not be created. Please check your connection and try again.';
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settlements recorded successfully')),
          );
          Navigator.of(context).pop();
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
  }

  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final groups = groupProvider.groups;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Settlement')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Amount
                    CustomTextField(
                      controller: _amountController,
                      label: 'Amount',
                      hint: '0.00',
                      prefixIcon: Icons.attach_money,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                          // Reset selections
                          _selectedFriendIds = [];
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Settlement direction
                    Text(
                      'Settlement Direction',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('You paid for others'),
                            value: true,
                            groupValue: _isCurrentUserPayer,
                            onChanged: (value) {
                              setState(() {
                                _isCurrentUserPayer = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Others paid for you'),
                            value: false,
                            groupValue: _isCurrentUserPayer,
                            onChanged: (value) {
                              setState(() {
                                _isCurrentUserPayer = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Show appropriate friend selector based on whether a group is selected
                    if (_selectedGroup == null)
                      // Single friend selector for personal settlements
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Friend',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SingleFriendSelector(
                            selectedFriendId: _selectedFriendId,
                            onFriendSelected: (friendId) {
                              setState(() {
                                _selectedFriendId = friendId;
                              });
                            },
                          ),
                        ],
                      )
                    else
                      // Multiple friend selector for group settlements
                      FriendSelector(
                        selectedFriends: _selectedFriendIds,
                        onFriendsSelected: (selectedIds) {
                          setState(() {
                            _selectedFriendIds = selectedIds;
                          });
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: CustomButton(
                        text: 'Record Settlement',
                        isLoading: _isLoading,
                        onPressed: _saveSettlement,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
