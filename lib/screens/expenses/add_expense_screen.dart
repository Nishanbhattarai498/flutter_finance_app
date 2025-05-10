import 'package:flutter/material.dart';
import 'package:flutter_finance_app/models/group.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/providers/expense_provider.dart';
import 'package:flutter_finance_app/providers/group_provider.dart';
import 'package:flutter_finance_app/widgets/custom_button.dart';
import 'package:flutter_finance_app/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            // Add bottom padding to prevent overflow
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Description
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

              // Amount with NPR prefix
              CustomTextField(
                controller: _amountController,
                label: 'Amount (NPR)',
                hint: '0.00',
                prefixIcon: Icons.currency_rupee,
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

              // Monthly Expense Switch
              SwitchListTile(
                title: const Text('Monthly Recurring Expense'),
                subtitle: const Text('This expense repeats every month'),
                value: _isMonthlyExpense,
                onChanged: (bool value) {
                  setState(() {
                    _isMonthlyExpense = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Category
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
                    // Reset participants when group changes
                    _selectedParticipants = [];
                  });
                },
              ),
              const SizedBox(height: 16),

              // Participants (if group is selected)
              if (_selectedGroup != null) ...[
                const Text(
                  'Split with:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // List of group members as checkboxes
                ...(_selectedGroup?.members ?? []).map((member) {
                  final userId = member.userId;
                  final isCurrentUser = userId == authProvider.userId;

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

                // Select all / clear selection buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedParticipants = _selectedGroup!.members
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

              // Display current month's remaining balance
              FutureBuilder<void>(
                future: null, // This will be replaced with actual data
                builder: (context, snapshot) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Month Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total Expenses: ${expenseProvider.formatAmountNPR(expenseProvider.getCurrentMonthTotal())}',
                            ),
                            if (_isMonthlyExpense)
                              Text(
                                'Monthly Recurring: ${expenseProvider.formatAmountNPR(expenseProvider.getTotalMonthlyRecurring())}',
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ), // Save button
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
    );
  }
}
