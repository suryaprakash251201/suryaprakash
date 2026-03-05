import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/note_repository.dart';

final noteRepositoryProvider = Provider((ref) => NoteRepository());
final notebookRepositoryProvider = Provider((ref) => NotebookRepository());

// ─── Note List Provider ───
class NoteListNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    return ref.read(noteRepositoryProvider).getAllNotes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(noteRepositoryProvider).getAllNotes());
  }

  Future<void> addNote(Note note) async {
    await ref.read(noteRepositoryProvider).insertNote(note);
    await refresh();
  }

  Future<void> updateNote(Note note) async {
    await ref.read(noteRepositoryProvider).updateNote(note);
    await refresh();
  }

  Future<void> deleteNote(String noteId) async {
    await ref.read(noteRepositoryProvider).deleteNote(noteId);
    await refresh();
  }

  Future<void> togglePin(String noteId, bool isPinned) async {
    await ref.read(noteRepositoryProvider).togglePin(noteId, isPinned);
    await refresh();
  }
}

final noteListProvider = AsyncNotifierProvider<NoteListNotifier, List<Note>>(
  NoteListNotifier.new,
);

// ─── Search ───
class NoteSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final noteSearchQueryProvider = NotifierProvider<NoteSearchQueryNotifier, String>(
  NoteSearchQueryNotifier.new,
);

final noteSearchResultsProvider = FutureProvider<List<Note>>((ref) async {
  final query = ref.watch(noteSearchQueryProvider);
  if (query.isEmpty) return [];
  return ref.read(noteRepositoryProvider).searchNotes(query);
});

// ─── Notebooks ───
class NotebookListNotifier extends AsyncNotifier<List<Notebook>> {
  @override
  Future<List<Notebook>> build() async {
    return ref.read(notebookRepositoryProvider).getAllNotebooks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(notebookRepositoryProvider).getAllNotebooks());
  }

  Future<void> addNotebook(Notebook notebook) async {
    await ref.read(notebookRepositoryProvider).insertNotebook(notebook);
    await refresh();
  }

  Future<void> updateNotebook(Notebook notebook) async {
    await ref.read(notebookRepositoryProvider).updateNotebook(notebook);
    await refresh();
  }

  Future<void> deleteNotebook(String notebookId) async {
    await ref.read(notebookRepositoryProvider).deleteNotebook(notebookId);
    await refresh();
    await ref.read(noteListProvider.notifier).refresh(); // as notes may be orphaned
  }
}

final notebookListProvider = AsyncNotifierProvider<NotebookListNotifier, List<Notebook>>(
  NotebookListNotifier.new,
);
