import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/models.dart';
import '../../core/providers/expense_providers.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? existingTransaction;

  const AddEditTransactionScreen({super.key, this.existingTransaction});

  @override
  ConsumerState<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends ConsumerState<AddEditTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagController = TextEditingController();
  
  bool _isIncome = false;
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  List<String> _tags = [];
  bool _seedingIncomeCategories = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final t = widget.existingTransaction!;
      _amountController.text = t.amount.toString();
      _noteController.text = t.note ?? '';
      _isIncome = t.isIncome;
      _selectedDate = t.date;
      _selectedCategoryId = t.categoryId;
      _tags = List.from(t.tags);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Watch categories to populate dropdown
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.existingTransaction == null ? 'New Transaction' : 'Edit Transaction',
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _saveTransaction(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income / Expense Toggle
            Center(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                  ButtonSegment(value: true, label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                ],
                selected: {_isIncome},
                onSelectionChanged: (set) {
                  setState(() {
                    _isIncome = set.first;
                    _selectedCategoryId = null;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _isIncome ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer;
                    }
                    return Colors.transparent;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Amount Input
            Center(
              child: IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _isIncome ? Colors.green : Colors.redAccent,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: theme.textTheme.displaySmall?.copyWith(
                      color: _isIncome ? Colors.green : Colors.redAccent,
                      fontWeight: FontWeight.w900,
                    ),
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Category Dropdown
            Text('Category', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) {
                // Filter categories based on income/expense type
                final filtered = categories.where((c) {
                  final type = c.type.toLowerCase();
                  if (c.isIncomeScore == 0) return true;
                  if (_isIncome) {
                    return c.isIncomeScore > 0 || type == 'income';
                  }
                  return c.isIncomeScore < 0 || type == 'expense';
                }).toList();

                if (_isIncome && filtered.isEmpty && !_seedingIncomeCategories) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _seedDefaultIncomeCategories(categories);
                  });
                }

                final selectedValue = filtered.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null;
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedValue,
                      hint: Text(_isIncome && filtered.isEmpty ? 'Creating income categories...' : 'Select a category'),
                      items: filtered.map((c) {
                        final color = _parseCategoryColor(c.colorHex);
                        return DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(IconData(c.iconCode, fontFamily: 'MaterialIcons'), color: color),
                              const SizedBox(width: 12),
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCategoryId = val);
                      },
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading categories: $e'),
            ),
            const SizedBox(height: 24),

            // Date Picker
            Text('Date', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notes Note
            Text('Note (Optional)', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'What was this for?',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Tags
            Text('Tags', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) => Chip(
                      label: Text('#$tag'),
                      onDeleted: () {
                        setState(() => _tags.remove(tag));
                      },
                      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      side: BorderSide.none,
                    )).toList(),
                  ),
                  if (_tags.isNotEmpty) const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: InputDecoration(
                            hintText: 'Add a tag...',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          onSubmitted: _addTag,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: theme.colorScheme.primary,
                        onPressed: () => _addTag(_tagController.text),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48), // Bottom padding
          ],
        ),
      ),
    );
  }

  void _addTag(String value) {
    var tag = value.trim().toLowerCase();
    if (tag.startsWith('#')) tag = tag.substring(1);
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagController.clear();
    }
  }

  void _saveTransaction() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final transaction = Transaction(
      id: widget.existingTransaction?.id ?? const Uuid().v4(),
      amount: amount,
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      isIncome: _isIncome,
      tags: _tags,
      createdAt: widget.existingTransaction?.createdAt ?? DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    if (widget.existingTransaction == null) {
      ref.read(transactionListProvider.notifier).addTransaction(transaction);
    } else {
      ref.read(transactionListProvider.notifier).updateTransaction(transaction);
    }

    Navigator.of(context).pop();
  }

  Color _parseCategoryColor(String colorHex) {
    var hex = colorHex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) {
      return Colors.grey;
    }
    return Color(int.parse(hex, radix: 16));
  }

  Future<void> _seedDefaultIncomeCategories(List<Category> existingCategories) async {
    if (_seedingIncomeCategories) return;
    _seedingIncomeCategories = true;

    final hasIncome = existingCategories.any((c) {
      final type = c.type.toLowerCase();
      return c.isIncomeScore > 0 || type == 'income';
    });

    if (!hasIncome) {
      final notifier = ref.read(categoryListProvider.notifier);
      await notifier.addCategory(
        Category(
          id: const Uuid().v4(),
          name: 'Salary',
          iconCode: Icons.payments_rounded.codePoint,
          colorHex: 'FF4CAF50',
          type: 'income',
          isIncomeScore: 1,
          createdAt: DateTime.now(),
        ),
      );

      await notifier.addCategory(
        Category(
          id: const Uuid().v4(),
          name: 'Other Income',
          iconCode: Icons.account_balance_wallet_rounded.codePoint,
          colorHex: 'FF26C6DA',
          type: 'income',
          isIncomeScore: 1,
          createdAt: DateTime.now(),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _seedingIncomeCategories = false;
      });
    }
  }
}
