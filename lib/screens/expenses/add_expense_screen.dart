import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/group.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/expense_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/widgets/custom_button.dart';
import 'package:flutter_finance_app/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedCategory = 'Food';
  Group? _selectedGroup;
  List<String> _selectedParticipants = [];
  bool _isMonthlyExpense = false;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Healthcare',
    'Travel',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.userId != null) {
      await groupProvider.fetchUserGroups();
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );

      if (authProvider.userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        return;
      } // If no participants are selected, add the current user
      if (_selectedParticipants.isEmpty) {
        _selectedParticipants = [authProvider.userId!];
      }

      // Create expense data with all required fields
      final expenseData = {
        'user_id': authProvider.userId,
        'group_id': _selectedGroup?.id,
        'title': _descriptionController.text.trim(), // Title field (required)
        'description': _descriptionController.text.trim(),
        'amount': double.parse(_amountController.text),
        'currency': 'NPR',
        'category': _selectedCategory,
        'is_monthly': _isMonthlyExpense,
        'participants': _selectedParticipants,
        'date': DateTime.now().toIso8601String(), // Required date field
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final success = await expenseProvider.addExpense(expenseData);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(expenseProvider.errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);
    final groups = groupProvider.groups;

    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF26A69A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Add Expense'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: Theme.of(context).cardColor.withOpacity(0.96),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Add a New Expense',
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            CustomTextField(
                              controller: _descriptionController,
                              label: 'Description',
                              hint: 'What was this expense for?',
                              prefixIcon: Icons.description_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _amountController,
                              label: 'Amount (NPR)',
                              hint: '0.00',
                              prefixIcon: Icons.currency_rupee,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
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
                            SwitchListTile(
                              title: const Text('Monthly Recurring Expense'),
                              subtitle: const Text(
                                  'This expense repeats every month'),
                              value: _isMonthlyExpense,
                              onChanged: (bool value) {
                                setState(() {
                                  _isMonthlyExpense = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: const Icon(Icons.category_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
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
                                  child: Text('Personal Expense'),
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
                                  _selectedParticipants = [];
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_selectedGroup != null) ...[
                              const Text(
                                'Split with:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...(_selectedGroup?.members ?? []).map((member) {
                                final userId = member.userId;
                                final isCurrentUser =
                                    userId == authProvider.userId;
                                return CheckboxListTile(
                                  title: Text(
                                    isCurrentUser
                                        ? 'Me (${member.displayName})'
                                        : member.displayName,
                                  ),
                                  value: _selectedParticipants.contains(userId),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedParticipants.add(userId);
                                      } else {
                                        _selectedParticipants.remove(userId);
                                      }
                                    });
                                  },
                                );
                              }),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedParticipants = _selectedGroup!
                                            .members
                                            .map((member) => member.userId)
                                            .toList();
                                      });
                                    },
                                    child: const Text('Select All'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedParticipants = [];
                                      });
                                    },
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: CustomButton(
                                text: 'Save Expense',
                                isLoading: expenseProvider.isLoading,
                                onPressed: _saveExpense,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
