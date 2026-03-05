import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/journal_providers.dart';

class AddEditJournalScreen extends ConsumerStatefulWidget {
  final JournalEntry? existingEntry;

  const AddEditJournalScreen({super.key, this.existingEntry});

  @override
  ConsumerState<AddEditJournalScreen> createState() => _AddEditJournalScreenState();
}

class _AddEditJournalScreenState extends ConsumerState<AddEditJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _contentController;
  
  int _selectedMood = 3; // Neutral
  String _selectedTemplate = 'freeform';
  late DateTime _entryDate;

  final Map<int, String> _moodMap = {
    5: 'Happy', 
    4: 'Calm', 
    3: 'Neutral', 
    2: 'Sad', 
    1: 'Angry'
  };
  
  final Map<String, String> _templateMap = {
    'freeform': 'Freeform',
    'gratitude': 'Gratitude',
    'daily_review': 'Daily Review',
  };

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.existingEntry?.content ?? '');
    
    if (widget.existingEntry != null) {
      _selectedMood = widget.existingEntry!.mood ?? 3;
      _selectedTemplate = widget.existingEntry!.template;
      _entryDate = widget.existingEntry!.date;
    } else {
      _entryDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      final entry = JournalEntry(
        id: widget.existingEntry?.id ?? const Uuid().v4(),
        date: _entryDate,
        template: _selectedTemplate,
        content: _contentController.text.trim(),
        mood: _selectedMood,
        createdAt: widget.existingEntry?.createdAt ?? DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      if (widget.existingEntry == null) {
        ref.read(journalEntriesProvider.notifier).addEntry(entry);
      } else {
        ref.read(journalEntriesProvider.notifier).updateEntry(entry);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Journal Entry', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEntry,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(_entryDate),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('h:mm a').format(_entryDate),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Template Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedTemplate,
              decoration: const InputDecoration(
                labelText: 'Template',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              items: _templateMap.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedTemplate = val);
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Mood Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _moodMap.entries.map((entry) {
                  final moodKey = entry.key;
                  final moodName = entry.value;
                  final isSelected = _selectedMood == moodKey;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(moodName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedMood = moodKey);
                      },
                      selectedColor: theme.colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Content
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Write your thoughts here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              maxLines: null,
              minLines: 8,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              validator: (val) => val == null || val.isEmpty ? 'Journal entry cannot be empty' : null,
            ),
            
            const SizedBox(height: 48),
            
            // Delete parameter
            if (widget.existingEntry != null)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                     ref.read(journalEntriesProvider.notifier).deleteEntry(widget.existingEntry!.id);
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
