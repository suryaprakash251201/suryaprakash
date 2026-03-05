import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/models.dart';
import '../../core/providers/vault_providers.dart';

class AddEditVaultItemScreen extends ConsumerStatefulWidget {
  final VaultItem? existingItem;

  const AddEditVaultItemScreen({super.key, this.existingItem});

  @override
  ConsumerState<AddEditVaultItemScreen> createState() => _AddEditVaultItemScreenState();
}

class _AddEditVaultItemScreenState extends ConsumerState<AddEditVaultItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _dataController;
  
  String _selectedCategory = 'password';
  bool _isDataVisible = false;

  final Map<String, IconData> _categoryMap = {
    'password': Icons.password,
    'document': Icons.description,
    'id_card': Icons.badge,
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingItem?.title ?? '');
    _dataController = TextEditingController(text: widget.existingItem?.encryptedData ?? '');
    
    if (widget.existingItem != null) {
      _selectedCategory = widget.existingItem!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final item = VaultItem(
        id: widget.existingItem?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        encryptedData: _dataController.text.trim(),
        category: _selectedCategory,
        iconCode: _categoryMap[_selectedCategory]!.codePoint,
        expiryDate: widget.existingItem?.expiryDate,
        createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      if (widget.existingItem == null) {
        ref.read(vaultItemsProvider.notifier).addItem(item);
      } else {
        ref.read(vaultItemsProvider.notifier).updateItem(item);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.existingItem == null ? 'New Entry' : 'Edit Entry', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveItem,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Category Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              items: const [
                DropdownMenuItem(value: 'password', child: Text('Password / Login')),
                DropdownMenuItem(value: 'document', child: Text('Secure Document Note')),
                DropdownMenuItem(value: 'id_card', child: Text('ID Card Info')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Bank Account',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 24),
            
            // Secure Data
            TextFormField(
              controller: _dataController,
              obscureText: !_isDataVisible,
              maxLines: _isDataVisible ? 4 : 1,
              decoration: InputDecoration(
                labelText: 'Secret Data',
                hintText: 'Enter sensitive information here...',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                suffixIcon: IconButton(
                  icon: Icon(_isDataVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _isDataVisible = !_isDataVisible),
                ),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Secret data cannot be empty' : null,
            ),
            const SizedBox(height: 16),
            
            // Helpful Context
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This information is securely encrypted before saving into the local database.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Delete parameter
            if (widget.existingItem != null)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                     ref.read(vaultItemsProvider.notifier).deleteItem(widget.existingItem!.id);
                     Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete Entry', style: TextStyle(color: Colors.red)),
                ),
              )
          ],
        ),
      ),
    );
  }
}
