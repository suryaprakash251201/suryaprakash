import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/vault_repository.dart';

// ─── Repository Provider ───
final vaultRepositoryProvider = Provider((ref) => VaultRepository());

// ─── Vault Category Filter Provider ───
class SelectedVaultCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void updateCategory(String category) {
    state = category;
  }
}

final selectedVaultCategoryProvider = NotifierProvider<SelectedVaultCategoryNotifier, String>(
  SelectedVaultCategoryNotifier.new,
);

// ─── Vault Items Provider ───
class VaultItemsNotifier extends AsyncNotifier<List<VaultItem>> {
  @override
  Future<List<VaultItem>> build() async {
    return _fetchFilteredItems();
  }

  Future<List<VaultItem>> _fetchFilteredItems() async {
    final allItems = await ref.read(vaultRepositoryProvider).getAllItems();
    final category = ref.watch(selectedVaultCategoryProvider);
    if (category == 'all') return allItems;
    return allItems.where((i) => i.category == category).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchFilteredItems());
  }

  Future<void> addItem(VaultItem item) async {
    await ref.read(vaultRepositoryProvider).insertItem(item);
    await refresh();
  }

  Future<void> updateItem(VaultItem item) async {
    await ref.read(vaultRepositoryProvider).updateItem(item);
    await refresh();
  }

  Future<void> deleteItem(String id) async {
    await ref.read(vaultRepositoryProvider).deleteItem(id);
    await refresh();
  }
}

final vaultItemsProvider = AsyncNotifierProvider<VaultItemsNotifier, List<VaultItem>>(
  VaultItemsNotifier.new,
);
