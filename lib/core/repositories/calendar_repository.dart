import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class CalendarRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // ─── Events ─── //
  Future<void> insertEvent(Event event) async {
    final db = await _db.database;
    await db.insert('events', event.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateEvent(Event event) async {
    final db = await _db.database;
    await db.update('events', event.toMap(), where: 'id = ?', whereArgs: [event.id]);
  }

  Future<void> deleteEvent(String id) async {
    final db = await _db.database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Event>> getEventsForDay(DateTime day) async {
    final db = await _db.database;
    // For simplicity, we fetch all events that overlap with the given day.
    // SQLite doesn't easily support dynamic date range queries without custom functions,
    // so we get events that start on the day or surround it.
    final startOfDay = DateTime(day.year, day.month, day.day).toIso8601String();
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59).toIso8601String();

    final maps = await db.query(
      'events',
      where: '(start_datetime <= ? AND end_datetime >= ?) OR (start_datetime >= ? AND start_datetime <= ?)',
      whereArgs: [endOfDay, startOfDay, startOfDay, endOfDay],
      orderBy: 'start_datetime ASC',
    );
    return maps.map((e) => Event.fromMap(e)).toList();
  }

  Future<List<Event>> getAllEvents() async {
    final db = await _db.database;
    final maps = await db.query('events', orderBy: 'start_datetime ASC');
    return maps.map((e) => Event.fromMap(e)).toList();
  }

  // ─── Reminders ─── //
  Future<void> insertReminder(Reminder reminder) async {
    final db = await _db.database;
    await db.insert('reminders', reminder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await _db.database;
    await db.update('reminders', reminder.toMap(), where: 'id = ?', whereArgs: [reminder.id]);
  }

  Future<void> deleteReminder(String id) async {
    final db = await _db.database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Reminder>> getPendingReminders() async {
    final db = await _db.database;
    final maps = await db.query(
      'reminders', 
      where: 'is_completed = ?', 
      whereArgs: [0],
      orderBy: 'datetime ASC',
    );
    return maps.map((e) => Reminder.fromMap(e)).toList();
  }
}
