import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/group.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/friends_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/providers/fixed_settlement_provider.dart'
    as settlement_provider;
import 'package:flutter_finance_app/widgets/custom_button.dart';
import 'package:flutter_finance_app/widgets/custom_text_field.dart';
import 'package:flutter_finance_app/widgets/friend_selector.dart';
import 'package:provider/provider.dart';

// Alias for SettlementProvider to avoid confusion
typedef SettlementProvider = settlement_provider.SettlementProvider;

class GroupSettlementSplitScreen extends StatefulWidget {
  const GroupSettlementSplitScreen({Key? key}) : super(key: key);

  @override
  _GroupSettlementSplitScreenState createState() =>
      _GroupSettlementSplitScreenState();
}

class _GroupSettlementSplitScreenState
    extends State<GroupSettlementSplitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalAmountController = TextEditingController();
  final _notesController = TextEditingController();
  Group? _selectedGroup;
  List<String> _selectedFriendIds = [];
  bool _isCurrentUserPayer = true;
  bool _isLoading = false;
  int _participantCount = 1; // Default to 1 (only current user)
  double _individualShare = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateShares() {
    if (_totalAmountController.text.isEmpty ||
        _totalAmountController.text == "0" ||
        _totalAmountController.text == "0.0") {
      setState(() {
        _individualShare = 0.0;
      });
      return;
    }

    try {
      final totalAmount = double.parse(_totalAmountController.text);
      // Total participants = selected friends + current user
      _participantCount = _selectedFriendIds.length + 1;

      if (_participantCount > 0) {
        setState(() {
          // Round to 2 decimal places for easier reading
          _individualShare =
              (totalAmount / _participantCount).roundToDouble() / 100 * 100;
        });
      }
    } catch (e) {
      setState(() {
        _individualShare = 0.0;
      });
    }
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
      ]);
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

      if (_selectedFriendIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one friend')),
        );
        return;
      }

      final currentUserId = authProvider.userId!;
      setState(() => _isLoading = true);
      try {
        final settlementProvider =
            Provider.of<SettlementProvider>(context, listen: false);
        final notes = _notesController.text.trim();

        // Equal split amount per person (excluding the payer if current user is payer)
        final List<Map<String, dynamic>> settlements = [];

        if (_isCurrentUserPayer) {
          // Current user paid for everyone
          // Calculate what each friend owes the current user

          // Ensure consistent rounding to 2 decimal places
          final sharePerFriend =
              ((_individualShare * 100).roundToDouble() / 100);

          for (final friendId in _selectedFriendIds) {
            settlements.add({
              'payer_id': friendId, // Friend owes money
              'receiver_id': currentUserId, // Current user receives money
              'amount': sharePerFriend,
              'notes': notes,
              'group_id': _selectedGroup?.id,
              'status': 'pending',
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        } else {
          // Someone else paid, and current user is part of the group
          // In this case, current user only owes the payer
          settlements.add({
            'payer_id': currentUserId, // Current user owes money
            'receiver_id':
                _selectedFriendIds[0], // First selected friend is the payer
            'amount': (_individualShare * 100).roundToDouble() / 100,
            'notes': notes,
            'group_id': _selectedGroup?.id,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        // Create all settlements
        bool anyFailure = false;
        for (final settlementData in settlements) {
          final success =
              await settlementProvider.createSettlement(settlementData);
          if (!success) {
            anyFailure = true;
          }
        }

        if (anyFailure) {
          throw 'Some settlements could not be created. Please check your connection and try again.';
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

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final groups = groupProvider.groups;

    return Scaffold(
      appBar: AppBar(title: const Text('Split Settlement Equally')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Description
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Theme.of(context).primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Equal Split Settlement',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This will divide the total amount equally among all participants, including you. Choose who paid the bill and select the participants to calculate how much each person owes.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_isCurrentUserPayer)
                              Text(
                                '• You paid: Others will owe you money (shown in green)',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 13,
                                ),
                              )
                            else
                              Text(
                                '• Someone else paid: You will owe money (shown in red)',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Total Amount
                    CustomTextField(
                      controller: _totalAmountController,
                      label: 'Total Amount',
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
                      onChanged: (value) {
                        _calculateShares();
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
                          child: Text('No Group'),
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
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Settlement direction
                    Text(
                      'Who Paid?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('You paid'),
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
                            title: const Text('Someone else paid'),
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

                    // Friend selector for participants
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCurrentUserPayer
                              ? 'Select Participants (who owe you)'
                              : 'Select Who Paid',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        FriendSelector(
                          selectedFriends: _selectedFriendIds,
                          maxSelection: _isCurrentUserPayer
                              ? null
                              : 1, // If someone else paid, only allow one selection
                          onFriendsSelected: (selectedIds) {
                            setState(() {
                              _selectedFriendIds = selectedIds;
                              _calculateShares();
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24), // Display split information
                    if (_totalAmountController.text.isNotEmpty &&
                        double.tryParse(_totalAmountController.text) != null &&
                        double.parse(_totalAmountController.text) > 0)
                      Card(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _isCurrentUserPayer
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Split Summary',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Amount:'),
                                  Text(
                                    _totalAmountController.text.isEmpty
                                        ? 'NPR 0.00'
                                        : 'NPR ${double.parse(_totalAmountController.text).toStringAsFixed(2)}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Number of Participants:'),
                                  Text(
                                    '$_participantCount',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Amount Per Person:'),
                                  Text(
                                    'NPR ${_individualShare.toStringAsFixed(2)}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      _isCurrentUserPayer
                                          ? 'You will receive:'
                                          : 'You will pay:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    'NPR ${(_isCurrentUserPayer ? (_individualShare * _selectedFriendIds.length) : _individualShare).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _isCurrentUserPayer
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
