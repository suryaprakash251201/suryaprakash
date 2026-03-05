import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class HabitRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get db async => await _dbHelper.database;

  // ─── Habits ───

  Future<List<Habit>> getAllHabits() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'habits',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<void> insertHabit(Habit habit) async {
    final database = await db;
    await database.insert(
      'habits',
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateHabit(Habit habit) async {
    final database = await db;
    await database.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> deleteHabit(String id) async {
    final database = await db;
    await database.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Habit Logs ───

  Future<List<HabitLog>> getLogsForHabit(String habitId) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => HabitLog.fromMap(map)).toList();
  }

  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    final database = await db;
    final dateStr = date.toIso8601String().split('T').first;
    final List<Map<String, dynamic>> maps = await database.query(
      'habit_logs',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    return maps.map((map) => HabitLog.fromMap(map)).toList();
  }

  Future<void> logHabit(HabitLog log) async {
    final database = await db;
    final dateStr = log.date.toIso8601String().split('T').first;
    
    // Check if log exists
    final List<Map<String, dynamic>> existing = await database.query(
      'habit_logs',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [log.habitId, dateStr],
    );

    if (existing.isNotEmpty) {
      // Update count
      final existingLog = HabitLog.fromMap(existing.first);
      await database.update(
        'habit_logs',
        {'count': existingLog.count + log.count},
        where: 'id = ?',
        whereArgs: [existingLog.id],
      );
    } else {
      // Insert new
      await database.insert(
        'habit_logs',
        {...log.toMap(), 'date': dateStr},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> deleteHabitLog(String logId) async {
    final database = await db;
    await database.delete(
      'habit_logs',
      where: 'id = ?',
      whereArgs: [logId],
    );
  }
}
