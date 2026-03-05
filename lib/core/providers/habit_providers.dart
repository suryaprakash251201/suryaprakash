import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../repositories/habit_repository.dart';

// ─── Repository Provider ───
final habitRepositoryProvider = Provider((ref) => HabitRepository());

// ─── Selected Date Provider ───
class SelectedHabitDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void updateDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

final selectedHabitDateProvider = NotifierProvider<SelectedHabitDateNotifier, DateTime>(
  SelectedHabitDateNotifier.new,
);

// ─── Habits Provider ───
class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  @override
  Future<List<Habit>> build() async {
    return ref.read(habitRepositoryProvider).getAllHabits();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(habitRepositoryProvider).getAllHabits());
  }

  Future<void> addHabit(Habit habit) async {
    await ref.read(habitRepositoryProvider).insertHabit(habit);
    await refresh();
  }

  Future<void> updateHabit(Habit habit) async {
    await ref.read(habitRepositoryProvider).updateHabit(habit);
    await refresh();
  }

  Future<void> deleteHabit(String id) async {
    await ref.read(habitRepositoryProvider).deleteHabit(id);
    await refresh();
  }
}

final habitsProvider = AsyncNotifierProvider<HabitsNotifier, List<Habit>>(
  HabitsNotifier.new,
);

// ─── Habit Logs for Selected Date Provider ───
class DailyHabitLogsNotifier extends AsyncNotifier<List<HabitLog>> {
  @override
  Future<List<HabitLog>> build() async {
    final selectedDate = ref.watch(selectedHabitDateProvider);
    return ref.read(habitRepositoryProvider).getLogsForDate(selectedDate);
  }

  Future<void> refreshLogs() async {
    final selectedDate = ref.read(selectedHabitDateProvider);
    state = const AsyncLoading();
    state = AsyncData(await ref.read(habitRepositoryProvider).getLogsForDate(selectedDate));
    // Also refresh habits to update streak changes if necessary (in a real advanced implementation)
    ref.read(habitsProvider.notifier).refresh();
  }

  Future<void> toggleHabitCompletion(Habit habit, bool isCompleted) async {
    final selectedDate = ref.read(selectedHabitDateProvider);
    final logs = state.asData?.value ?? [];
    
    if (isCompleted) {
      // Mark as completed
      final log = HabitLog(
        id: const Uuid().v4(),
        habitId: habit.id,
        date: selectedDate,
        count: 1,
      );
      await ref.read(habitRepositoryProvider).logHabit(log);
      
      // Update habit streak optimistic
      final newStreak = habit.streakCount + 1;
      final bestStreak = newStreak > habit.bestStreak ? newStreak : habit.bestStreak;
      await ref.read(habitRepositoryProvider).updateHabit(
        habit.copyWith(streakCount: newStreak, bestStreak: bestStreak)
      );
      
    } else {
      // Find log and delete
      final existingLog = logs.firstWhere((l) => l.habitId == habit.id);
      await ref.read(habitRepositoryProvider).deleteHabitLog(existingLog.id);
      
      // Update habit streak optimistic
      final newStreak = (habit.streakCount - 1).clamp(0, 9999);
      await ref.read(habitRepositoryProvider).updateHabit(
        habit.copyWith(streakCount: newStreak)
      );
    }
    
    await refreshLogs();
  }
}

final dailyHabitLogsProvider = AsyncNotifierProvider<DailyHabitLogsNotifier, List<HabitLog>>(
  DailyHabitLogsNotifier.new,
);

// Habit.copyWith extension since we didn't add it in models
extension HabitCopyWith on Habit {
  Habit copyWith({
    String? name,
    String? description,
    int? iconCode,
    String? colorHex,
    String? frequency,
    int? targetCount,
    int? streakCount,
    int? bestStreak,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCode: iconCode ?? this.iconCode,
      colorHex: colorHex ?? this.colorHex,
      frequency: frequency ?? this.frequency,
      targetCount: targetCount ?? this.targetCount,
      streakCount: streakCount ?? this.streakCount,
      bestStreak: bestStreak ?? this.bestStreak,
      createdAt: createdAt,
    );
  }
}
