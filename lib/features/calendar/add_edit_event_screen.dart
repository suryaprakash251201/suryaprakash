import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/models.dart';
import '../../core/providers/calendar_providers.dart';

class AddEditEventScreen extends ConsumerStatefulWidget {
  final Event? existingEvent;
  final DateTime? selectedDate;

  const AddEditEventScreen({super.key, this.existingEvent, this.selectedDate});

  @override
  ConsumerState<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends ConsumerState<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  
  bool _isAllDay = false;
  String _colorHex = '4A90E2'; // Default Blue

  final List<String> _colorOptions = [
    '4A90E2', // Blue
    'E24A4A', // Red
    '4AE285', // Green
    'F5A623', // Orange
    'BD10E0', // Purple
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingEvent?.title ?? '');
    _descController = TextEditingController(text: widget.existingEvent?.description ?? '');
    
    if (widget.existingEvent != null) {
      _startDate = widget.existingEvent!.startDateTime;
      _startTime = TimeOfDay.fromDateTime(widget.existingEvent!.startDateTime);
      _endDate = widget.existingEvent!.endDateTime;
      _endTime = TimeOfDay.fromDateTime(widget.existingEvent!.endDateTime);
      _isAllDay = widget.existingEvent!.isAllDay;
      _colorHex = widget.existingEvent!.colorHex;
    } else {
      final now = DateTime.now();
      _startDate = widget.selectedDate ?? now;
      _startTime = TimeOfDay(hour: now.hour + 1, minute: 0); // Next hour
      _endDate = _startDate;
      _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: 0); // 1 hr diff
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate; // Keep end date sane
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate; 
          }
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      final startDatetime = DateTime(
        _startDate.year, _startDate.month, _startDate.day, 
        _isAllDay ? 0 : _startTime.hour, _isAllDay ? 0 : _startTime.minute
      );
      final endDatetime = DateTime(
        _endDate.year, _endDate.month, _endDate.day, 
        _isAllDay ? 23 : _endTime.hour, _isAllDay ? 59 : _endTime.minute
      );

      if (endDatetime.isBefore(startDatetime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time cannot be before Start time')),
        );
        return;
      }

      final event = Event(
        id: widget.existingEvent?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        startDateTime: startDatetime,
        endDateTime: endDatetime,
        isAllDay: _isAllDay,
        colorHex: _colorHex,
        createdAt: widget.existingEvent?.createdAt ?? DateTime.now(),
      );

      if (widget.existingEvent == null) {
        ref.read(eventsProvider.notifier).addEvent(event);
      } else {
        ref.read(eventsProvider.notifier).updateEvent(event);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.existingEvent == null ? 'New Event' : 'Edit Event'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _saveEvent,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Event Title',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              style: theme.textTheme.titleLarge,
              validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            
            // All-Day Toggle
            SwitchListTile(
              title: const Text('All-day'),
              value: _isAllDay,
              onChanged: (val) => setState(() => _isAllDay = val),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
            ),
            const SizedBox(height: 16),

            // Date & Time Picker
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Starts'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _pickDate(true),
                          child: Text(DateFormat('MMM d, yyyy').format(_startDate)),
                        ),
                        if (!_isAllDay)
                          TextButton(
                            onPressed: () => _pickTime(true),
                            child: Text(_startTime.format(context)),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Ends'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _pickDate(false),
                          child: Text(DateFormat('MMM d, yyyy').format(_endDate)),
                        ),
                        if (!_isAllDay)
                          TextButton(
                            onPressed: () => _pickTime(false),
                            child: Text(_endTime.format(context)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Color Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Color Marker', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _colorOptions.map((hex) {
                      final color = Color(int.parse('0xFF$hex'));
                      final isSelected = _colorHex == hex;
                      return GestureDetector(
                        onTap: () => setState(() => _colorHex = hex),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: theme.colorScheme.onSurface, width: 3) : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                hintText: 'Add description...',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}
