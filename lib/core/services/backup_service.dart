import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../repositories/expense_repository.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  Future<Directory> _backupDirectory() async {
    final extDir = await getApplicationDocumentsDirectory();
    final backupFolder = Directory(join(extDir.path, 'Suryaprakash_Backups'));
    if (!await backupFolder.exists()) {
      await backupFolder.create(recursive: true);
    }
    return backupFolder;
  }

  /// Exports the entire SQLite database file to a specified directory (e.g. Downloads or Custom picker)
  /// For this MVP, we will export to the app's document directory or a common location.
  Future<String?> exportDatabase() async {
    try {
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'suryaprakash.db');
      
      final File sourceFile = File(dbPath);
      if (!await sourceFile.exists()) {
        debugPrint('Source database does not exist');
        return null;
      }

      final backupFolder = await _backupDirectory();

      final backupPath = join(backupFolder.path, 'suryaprakash_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db');
      
      await sourceFile.copy(backupPath);
      return backupPath;
    } catch (e) {
      debugPrint('Error exporting database: \$e');
      return null;
    }
  }

  Future<List<String>> listBackupFiles() async {
    try {
      final backupFolder = await _backupDirectory();
      final files = backupFolder
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.db'))
          .map((f) => f.path)
          .toList();
      files.sort((a, b) => b.compareTo(a));
      return files;
    } catch (e) {
      debugPrint('Error listing backup files: $e');
      return const [];
    }
  }

  Future<String?> exportExpensesCsv() async {
    try {
      final transactions = await _expenseRepository.getAllTransactions();
      final categories = await _categoryRepository.getAllCategories();
      final categoryMap = {for (final c in categories) c.id: c.name};

      final rows = <String>[
        'Date,Type,Category,Amount,Note',
      ];

      for (final txn in transactions) {
        final dateStr = DateFormat('yyyy-MM-dd').format(txn.date);
        final type = txn.isIncome ? 'Income' : 'Expense';
        final category = _escapeCsv(categoryMap[txn.categoryId] ?? txn.categoryId);
        final amount = txn.amount.toStringAsFixed(2);
        final note = _escapeCsv(txn.note ?? '');
        rows.add('$dateStr,$type,$category,$amount,$note');
      }

      final backupFolder = await _backupDirectory();
      final exportPath = join(
        backupFolder.path,
        'expenses_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
      );

      final file = File(exportPath);
      await file.writeAsString(rows.join('\n'));
      return exportPath;
    } catch (e) {
      debugPrint('Error exporting expenses CSV: $e');
      return null;
    }
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// Restores the database from a given file path.
  Future<bool> restoreDatabase(String backupFilePath) async {
    try {
      final File backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        debugPrint('Backup file does not exist');
        return false;
      }

      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'suryaprakash.db');
      
      final File currentDb = File(dbPath);
      
      // Close any active connections (ideally handled via DB Provider resetting but this works for MVP)
      final activeDb = await _dbHelper.database;
      await activeDb.close();

      // Overwrite the current db
      await backupFile.copy(currentDb.path);
      
      // Re-initialize Database
      // Realistically we'd need to notify riverpod to restart/invalidate providers, 
      // but restarting the app is the safest way after a DB restore.
      return true;
    } catch (e) {
      debugPrint('Error restoring database: \$e');
      return false;
    }
  }
}
