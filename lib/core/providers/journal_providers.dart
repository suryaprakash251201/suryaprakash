import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/journal_repository.dart';

// ─── Repository Provider ───
final journalRepositoryProvider = Provider((ref) => JournalRepository());

// ─── Journal Entries Provider ───
class JournalEntriesNotifier extends AsyncNotifier<List<JournalEntry>> {
  @override
  Future<List<JournalEntry>> build() async {
    return ref.read(journalRepositoryProvider).getAllEntries();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(journalRepositoryProvider).getAllEntries());
  }

  Future<void> addEntry(JournalEntry entry) async {
    await ref.read(journalRepositoryProvider).insertEntry(entry);
    await refresh();
  }

  Future<void> updateEntry(JournalEntry entry) async {
    await ref.read(journalRepositoryProvider).updateEntry(entry);
    await refresh();
  }

  Future<void> deleteEntry(String id) async {
    await ref.read(journalRepositoryProvider).deleteEntry(id);
    await refresh();
  }
}

final journalEntriesProvider = AsyncNotifierProvider<JournalEntriesNotifier, List<JournalEntry>>(
  JournalEntriesNotifier.new,
);
