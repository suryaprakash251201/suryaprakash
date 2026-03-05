import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/habit_providers.dart';
import 'add_edit_habit_screen.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : theme.colorScheme.surface;

    final selectedDate = ref.watch(selectedHabitDateProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final logsAsync = ref.watch(dailyHabitLogsProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Habits', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildDateSelector(context, ref, theme, isDark, selectedDate),
          const SizedBox(height: 16),
          Expanded(
            child: habitsAsync.when(
              data: (habits) {
                if (habits.isEmpty) {
                  return _buildEmptyState(theme);
                }
                
                final logs = logsAsync.asData?.value ?? [];
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 100),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    final isCompleted = logs.any((l) => l.habitId == habit.id);
                    return _HabitCard(
                      habit: habit,
                      isCompleted: isCompleted,
                      theme: theme,
                      isDark: isDark,
                      onToggle: (val) {
                        ref.read(dailyHabitLogsProvider.notifier).toggleHabitCompletion(habit, val);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditHabitScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, WidgetRef ref, ThemeData theme, bool isDark, DateTime selectedDate) {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // 2 weeks (7 days past, 1 day future)
        // Adjust initialOffset to show today near center roughly
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: 10 - index));
          final isSelected = date.year == selectedDate.year && 
                             date.month == selectedDate.month && 
                             date.day == selectedDate.day;
          
          return GestureDetector(
            onTap: () => ref.read(selectedHabitDateProvider.notifier).updateDate(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : (isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4)
                  )
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${date.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Icon(Icons.track_changes, size: 48, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No habits tracked yet',
             style: theme.textTheme.bodyLarge?.copyWith(
               color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
             ),
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final ThemeData theme;
  final bool isDark;
  final ValueChanged<bool> onToggle;

  const _HabitCard({
    required this.habit, 
    required this.isCompleted, 
    required this.theme, 
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0x${habit.colorHex}'));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: isCompleted ? 0.3 : 0.05)),
        boxShadow: [
          BoxShadow(
             color: color.withValues(alpha: isCompleted ? 0.05 : 0),
             blurRadius: 10,
             offset: const Offset(0, 4),
          )
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isCompleted ? color : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
                color: isCompleted ? Colors.white : color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? theme.colorScheme.onSurface.withValues(alpha: 0.5) : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (habit.description != null && habit.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      habit.description!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, size: 14, color: Colors.orange.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.streakCount} Day Streak',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.orange.shade400, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            // Completion Checkbox
            GestureDetector(
              onTap: () => onToggle(!isCompleted),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: isCompleted ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: isCompleted ? color : theme.colorScheme.outline.withValues(alpha: 0.3), width: 2),
                ),
                child: isCompleted 
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : null,
              ),
            )
          ],
        ),
      ),
    );
  }
}
