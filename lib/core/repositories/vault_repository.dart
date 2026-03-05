import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/models.dart';

class VaultRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get db async => await _dbHelper.database;

  // Simple Base64 Mock Encryption for MVP
  // In a production app, use AES-GCM with a key derived from user pin or secure storage.
  String _encrypt(String data) {
    return base64Encode(utf8.encode(data));
  }
  
  String _decrypt(String encrypted) {
    return utf8.decode(base64Decode(encrypted));
  }

  Future<List<VaultItem>> getAllItems() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'vault_items',
      orderBy: 'created_at DESC',
    );
    // Decode data on the fly before returning
    return maps.map((map) {
      final item = VaultItem.fromMap(map);
      return VaultItem(
        id: item.id,
        title: item.title,
        encryptedData: _decrypt(item.encryptedData),
        category: item.category,
        iconCode: item.iconCode,
        expiryDate: item.expiryDate,
        createdAt: item.createdAt,
        modifiedAt: item.modifiedAt,
      );
    }).toList();
  }

  Future<void> insertItem(VaultItem item) async {
    final database = await db;
    final encryptedItem = VaultItem(
        id: item.id,
        title: item.title,
        encryptedData: _encrypt(item.encryptedData),
        category: item.category,
        iconCode: item.iconCode,
        expiryDate: item.expiryDate,
        createdAt: item.createdAt,
        modifiedAt: item.modifiedAt,
    );
    await database.insert(
      'vault_items',
      encryptedItem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateItem(VaultItem item) async {
    final database = await db;
    final encryptedItem = VaultItem(
        id: item.id,
        title: item.title,
        encryptedData: _encrypt(item.encryptedData),
        category: item.category,
        iconCode: item.iconCode,
        expiryDate: item.expiryDate,
        createdAt: item.createdAt,
        modifiedAt: item.modifiedAt,
    );
    await database.update(
      'vault_items',
      encryptedItem.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteItem(String id) async {
    final database = await db;
    await database.delete(
      'vault_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
