import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/models.dart';
import '../../core/providers/habit_providers.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final Habit? existingHabit;

  const AddEditHabitScreen({super.key, this.existingHabit});

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  
  String _selectedFrequency = 'daily';
  int _targetCount = 1;
  int _selectedIconCode = Icons.local_drink.codePoint;
  String _selectedColorHex = 'FF009688';

  final List<String> _colorOptions = [
    'FF009688', // Teal
    'FFE91E63', // Pink
    'FF9C27B0', // Purple
    'FF3F51B5', // Indigo
    'FF4CAF50', // Green
    'FFFF9800', // Orange
    'FFF44336', // Red
    'FF795548', // Brown
  ];

  final List<IconData> _iconOptions = [
    Icons.local_drink,
    Icons.directions_run,
    Icons.menu_book,
    Icons.self_improvement,
    Icons.bedtime,
    Icons.fitness_center,
    Icons.monitor_heart,
    Icons.savings,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingHabit?.name ?? '');
    _descController = TextEditingController(text: widget.existingHabit?.description ?? '');
    
    if (widget.existingHabit != null) {
      _selectedFrequency = widget.existingHabit!.frequency;
      _targetCount = widget.existingHabit!.targetCount;
      _selectedIconCode = widget.existingHabit!.iconCode;
      _selectedColorHex = widget.existingHabit!.colorHex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveHabit() {
    if (_formKey.currentState!.validate()) {
      final habit = Habit(
        id: widget.existingHabit?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        iconCode: _selectedIconCode,
        colorHex: _selectedColorHex,
        frequency: _selectedFrequency,
        targetCount: _targetCount,
        streakCount: widget.existingHabit?.streakCount ?? 0,
        bestStreak: widget.existingHabit?.bestStreak ?? 0,
        createdAt: widget.existingHabit?.createdAt ?? DateTime.now(),
      );

      if (widget.existingHabit == null) {
        ref.read(habitsProvider.notifier).addHabit(habit);
      } else {
        ref.read(habitsProvider.notifier).updateHabit(habit);
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
        title: Text(widget.existingHabit == null ? 'New Habit' : 'Edit Habit', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveHabit,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Icon & Name Row
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(int.parse('0x$_selectedColorHex')).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconData(_selectedIconCode, fontFamily: 'MaterialIcons'),
                    color: Color(int.parse('0x$_selectedColorHex')),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Habit Name',
                      hintText: 'e.g., Drink Water',
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Please enter a name' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Why are you tracking this?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            
            // Icon Selection
            Text('Select Icon', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _iconOptions.map((icon) {
                final isSelected = _selectedIconCode == icon.codePoint;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconCode = icon.codePoint),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            
            // Color Selection
            Text('Select Color', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _colorOptions.map((hex) {
                final color = Color(int.parse('0x$hex'));
                final isSelected = _selectedColorHex == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorHex = hex),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: theme.colorScheme.onSurface, width: 3) : null,
                      boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)] : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
            
            // Delete parameter
            if (widget.existingHabit != null)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                     ref.read(habitsProvider.notifier).deleteHabit(widget.existingHabit!.id);
                     Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete Habit', style: TextStyle(color: Colors.red)),
                ),
              )
          ],
        ),
      ),
    );
  }
}
