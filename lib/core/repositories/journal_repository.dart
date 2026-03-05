import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class JournalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get db async => await _dbHelper.database;

  Future<List<JournalEntry>> getAllEntries() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'journal_entries',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  Future<void> insertEntry(JournalEntry entry) async {
    final database = await db;
    await database.insert(
      'journal_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateEntry(JournalEntry entry) async {
    final database = await db;
    await database.update(
      'journal_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> deleteEntry(String id) async {
    final database = await db;
    await database.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
