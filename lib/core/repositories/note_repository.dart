import '../database/database_helper.dart';
import '../models/models.dart';

class NoteRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // ─── Create ───
  Future<void> insertNote(Note note) async {
    final db = await _db.database;
    await db.insert('notes', note.toMap());
    for (final tag in note.tags) {
      await db.insert('note_tags', {'note_id': note.id, 'tag': tag});
    }
  }

  // ─── Read ───
  Future<List<Note>> getAllNotes() async {
    final db = await _db.database;
    final maps = await db.query('notes', orderBy: 'is_pinned DESC, modified_at DESC');
    final notes = <Note>[];
    for (final map in maps) {
      final tags = await _getNoteTags(map['id'] as String);
      notes.add(Note.fromMap({...map}).copyWith(tags: tags));
    }
    return notes;
  }

  Future<List<Note>> getNotesByNotebook(String notebookId) async {
    final db = await _db.database;
    final maps = await db.query(
      'notes',
      where: 'notebook_id = ?',
      whereArgs: [notebookId],
      orderBy: 'is_pinned DESC, modified_at DESC',
    );
    final notes = <Note>[];
    for (final map in maps) {
      final tags = await _getNoteTags(map['id'] as String);
      notes.add(Note.fromMap({...map}).copyWith(tags: tags));
    }
    return notes;
  }

  Future<List<Note>> getPinnedNotes() async {
    final db = await _db.database;
    final maps = await db.query(
      'notes',
      where: 'is_pinned = 1',
      orderBy: 'modified_at DESC',
    );
    final notes = <Note>[];
    for (final map in maps) {
      final tags = await _getNoteTags(map['id'] as String);
      notes.add(Note.fromMap({...map}).copyWith(tags: tags));
    }
    return notes;
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await _db.database;
    final maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content_markdown LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'modified_at DESC',
    );
    final notes = <Note>[];
    for (final map in maps) {
      final tags = await _getNoteTags(map['id'] as String);
      notes.add(Note.fromMap({...map}).copyWith(tags: tags));
    }
    return notes;
  }

  // ─── Update ───
  Future<void> updateNote(Note note) async {
    final db = await _db.database;
    await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
    await db.delete('note_tags', where: 'note_id = ?', whereArgs: [note.id]);
    for (final tag in note.tags) {
      await db.insert('note_tags', {'note_id': note.id, 'tag': tag});
    }
  }

  Future<void> togglePin(String noteId, bool isPinned) async {
    final db = await _db.database;
    await db.update('notes', {'is_pinned': isPinned ? 1 : 0}, where: 'id = ?', whereArgs: [noteId]);
  }

  // ─── Delete ───
  Future<void> deleteNote(String noteId) async {
    final db = await _db.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }

  // ─── Helpers ───
  Future<List<String>> _getNoteTags(String noteId) async {
    final db = await _db.database;
    final maps = await db.query('note_tags', where: 'note_id = ?', whereArgs: [noteId]);
    return maps.map((m) => m['tag'] as String).toList();
  }
}

// ─── Notebook Repository ───
class NotebookRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> insertNotebook(Notebook notebook) async {
    final db = await _db.database;
    await db.insert('notebooks', notebook.toMap());
  }

  Future<List<Notebook>> getAllNotebooks() async {
    final db = await _db.database;
    final maps = await db.query('notebooks', orderBy: 'sort_order ASC, created_at DESC');
    return maps.map((m) => Notebook.fromMap(m)).toList();
  }

  Future<void> updateNotebook(Notebook notebook) async {
    final db = await _db.database;
    await db.update('notebooks', notebook.toMap(), where: 'id = ?', whereArgs: [notebook.id]);
  }

  Future<void> deleteNotebook(String notebookId) async {
    final db = await _db.database;
    // Move notes to no-notebook
    await db.update('notes', {'notebook_id': null}, where: 'notebook_id = ?', whereArgs: [notebookId]);
    await db.delete('notebooks', where: 'id = ?', whereArgs: [notebookId]);
  }
}
