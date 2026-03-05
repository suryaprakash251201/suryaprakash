import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/expense_repository.dart';
import 'package:intl/intl.dart';

// ─── Repositories ─── //
final expenseRepositoryProvider = Provider((ref) => ExpenseRepository());
final categoryRepositoryProvider = Provider((ref) => CategoryRepository());

// ─── Transaction Providers ─── //
class TransactionListNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    return ref.read(expenseRepositoryProvider).getAllTransactions();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(expenseRepositoryProvider).getAllTransactions());
  }

  Future<void> addTransaction(Transaction transaction) async {
    await ref.read(expenseRepositoryProvider).insertTransaction(transaction);
    await refresh();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await ref.read(expenseRepositoryProvider).updateTransaction(transaction);
    await refresh();
  }

  Future<void> deleteTransaction(String id) async {
    await ref.read(expenseRepositoryProvider).deleteTransaction(id);
    await refresh();
  }
}

final transactionListProvider = AsyncNotifierProvider<TransactionListNotifier, List<Transaction>>(
  TransactionListNotifier.new,
);

// ─── Selected Month Provider (Expenses) ─── //
class SelectedExpenseMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void jumpToCurrentMonth() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, 1);
  }
}

final selectedExpenseMonthProvider = NotifierProvider<SelectedExpenseMonthNotifier, DateTime>(
  SelectedExpenseMonthNotifier.new,
);

// Filtered to Current Month
final currentMonthTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  ref.watch(transactionListProvider); // Rebuild when list changes
  final now = DateTime.now();
  return ref.read(expenseRepositoryProvider).getTransactionsForMonth(now.year, now.month);
});

// Filtered to Selected Month
final selectedMonthTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  ref.watch(transactionListProvider);
  final selectedMonth = ref.watch(selectedExpenseMonthProvider);
  return ref.read(expenseRepositoryProvider).getTransactionsForMonth(selectedMonth.year, selectedMonth.month);
});

// Calculate total spent this month
final currentMonthSpentProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(currentMonthTransactionsProvider.future);
  return transactions.where((t) => !t.isIncome).fold<double>(0.0, (sum, item) => sum + item.amount);
});

// Calculate total spent for selected month
final selectedMonthSpentProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(selectedMonthTransactionsProvider.future);
  return transactions.where((t) => !t.isIncome).fold<double>(0.0, (sum, item) => sum + item.amount);
});

// Calculate total income this month
final currentMonthIncomeProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(currentMonthTransactionsProvider.future);
  return transactions.where((t) => t.isIncome).fold<double>(0.0, (sum, item) => sum + item.amount);
});

// Calculate total income for selected month
final selectedMonthIncomeProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(selectedMonthTransactionsProvider.future);
  return transactions.where((t) => t.isIncome).fold<double>(0.0, (sum, item) => sum + item.amount);
});

// ─── Budget Providers ─── //
final currentMonthBudgetProvider = FutureProvider<MonthlyBudget?>((ref) async {
  // Can be combined to trigger updates when transactions are added
  ref.watch(transactionListProvider);
  final str = DateFormat('yyyy-MM').format(DateTime.now());
  return ref.read(expenseRepositoryProvider).getMonthlyBudget(str);
});

final selectedMonthBudgetProvider = FutureProvider<MonthlyBudget?>((ref) async {
  ref.watch(transactionListProvider);
  final selectedMonth = ref.watch(selectedExpenseMonthProvider);
  final monthStr = DateFormat('yyyy-MM').format(selectedMonth);
  return ref.read(expenseRepositoryProvider).getMonthlyBudget(monthStr);
});

// ─── Category Provider ─── //
class CategoryListNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return ref.read(categoryRepositoryProvider).getAllCategories();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(categoryRepositoryProvider).getAllCategories());
  }

  Future<void> addCategory(Category category) async {
    await ref.read(categoryRepositoryProvider).insertCategory(category);
    await refresh();
  }
}

final categoryListProvider = AsyncNotifierProvider<CategoryListNotifier, List<Category>>(
  CategoryListNotifier.new,
);

// Helper provider to fetch a single category sync/async
final categoryProvider = FutureProvider.family<Category?, String>((ref, id) async {
  return ref.read(categoryRepositoryProvider).getCategory(id);
});
