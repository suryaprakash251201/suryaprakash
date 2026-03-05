import 'package:sqflite/sqflite.dart' hide Transaction;
import '../database/database_helper.dart';
import '../models/models.dart';

class ExpenseRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // ─── Transactions ─── //
  Future<void> insertTransaction(Transaction transaction) async {
    final db = await _db.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Insert tags
    for (var tag in transaction.tags) {
      await db.insert('transaction_tags', {'transaction_id': transaction.id, 'tag': tag}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final db = await _db.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    // Update tags (delete all then re-insert)
    await db.delete('transaction_tags', where: 'transaction_id = ?', whereArgs: [transaction.id]);
    for (var tag in transaction.tags) {
      await db.insert('transaction_tags', {'transaction_id': transaction.id, 'tag': tag}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _db.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    await db.delete('transaction_tags', where: 'transaction_id = ?', whereArgs: [id]);
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC');
    return await _processTransactions(db, maps);
  }

  Future<List<Transaction>> getTransactionsForMonth(int year, int month) async {
    final db = await _db.database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return await _processTransactions(db, maps);
  }

  Future<List<Transaction>> _processTransactions(Database db, List<Map<String, dynamic>> maps) async {
    List<Transaction> transactions = [];
    for (var map in maps) {
      final tagsMaps = await db.query('transaction_tags', where: 'transaction_id = ?', whereArgs: [map['id']]);
      final tags = tagsMaps.map((e) => e['tag'] as String).toList();
      transactions.add(Transaction.fromMap({...map, 'tags': tags}));
    }
    return transactions;
  }

  // ─── Budgets ─── //
  Future<void> insertMonthlyBudget(MonthlyBudget budget) async {
    final db = await _db.database;
    await db.insert('monthly_budgets', budget.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<MonthlyBudget?> getMonthlyBudget(String monthYearStr) async {
    final db = await _db.database;
    final maps = await db.query('monthly_budgets', where: 'month_year_str = ?', whereArgs: [monthYearStr]);
    if (maps.isNotEmpty) {
      return MonthlyBudget.fromMap(maps.first);
    }
    return null;
  }
}

class CategoryRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> insertCategory(Category category) async {
    final db = await _db.database;
    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Category>> getAllCategories() async {
    final db = await _db.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((e) => Category.fromMap(e)).toList();
  }

  Future<Category?> getCategory(String id) async {
    final db = await _db.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }
}
