import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/expense_providers.dart';
import 'add_edit_transaction_screen.dart';

String formatRupee(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  double _monthlyBudget = 30000;
  double _monthlyIncome = 50000;
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Expenses',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Transaction',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddEditTransactionScreen(),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildBudgetOverviewCard(context, ref, isDark),
                  const SizedBox(height: 20),
                  _buildIncomeVsExpenseRow(context, ref, isDark),
                  const SizedBox(height: 28),
                  Text(
                    'Analytics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildChartCard(context, ref, isDark),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(onPressed: () {}, child: const Text('See All')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildTransactionList(context, ref, isDark),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, ThemeData theme, bool isDark) {
    final budgetController = TextEditingController(
      text: _monthlyBudget.toInt().toString(),
    );
    final incomeController = TextEditingController(
      text: _monthlyIncome.toInt().toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Budget & Income',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set your monthly budget and income',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Monthly Income',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: incomeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                    fontSize: 18,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF252525)
                      : theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  hintText: '50000',
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Monthly Budget',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    fontSize: 18,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF252525)
                      : theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  hintText: '30000',
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _monthlyBudget =
                          double.tryParse(budgetController.text) ?? _monthlyBudget;
                      _monthlyIncome =
                          double.tryParse(incomeController.text) ?? _monthlyIncome;
                    });
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Settings',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetOverviewCard(BuildContext context, WidgetRef ref, bool isDark) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(selectedExpenseMonthProvider);
    final spentAsync = ref.watch(selectedMonthSpentProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [const Color(0xFF450920), const Color(0xFF450920)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
                      onPressed: () =>
                          ref.read(selectedExpenseMonthProvider.notifier).previousMonth(),
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                    ),
                    Flexible(
                      child: Text(
                        DateFormat('MMMM yyyy').format(selectedMonth).toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
                      onPressed: () =>
                          ref.read(selectedExpenseMonthProvider.notifier).nextMonth(),
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(selectedExpenseMonthProvider.notifier).jumpToCurrentMonth(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Today',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8FA2FF).withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Budget: ${formatRupee(_monthlyBudget)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE6ECFF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          spentAsync.when(
            data: (spent) {
              final safeBudget = _monthlyBudget <= 0 ? 1.0 : _monthlyBudget;
              double percentage = spent / safeBudget;
              if (percentage > 1.0) percentage = 1.0;
              final remaining = _monthlyBudget - spent;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatRupee(spent),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remaining >= 0
                        ? '${formatRupee(remaining)} remaining'
                        : '${formatRupee(-remaining)} over budget!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: remaining >= 0
                          ? const Color(0xFF53E08B)
                          : const Color(0xFFFF7A7A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor:
                          isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage > 0.9
                            ? const Color(0xFFE53935)
                            : (percentage > 0.7
                                ? const Color(0xFFFF9800)
                                : const Color(0xFF00B8D4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(percentage * 100).toInt()}% used',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeVsExpenseRow(BuildContext context, WidgetRef ref, bool isDark) {
    final theme = Theme.of(context);
    final spentAsync = ref.watch(selectedMonthSpentProvider);
    final incomeAsync = ref.watch(selectedMonthIncomeProvider);

    return Row(
      children: [
        Expanded(
          child: _miniSummaryCard(
            theme: theme,
            isDark: isDark,
            label: 'Income',
            icon: Icons.arrow_downward_rounded,
            iconColor: Colors.white,
            fillColor: const Color(0xFF007200),
            asyncValue: incomeAsync,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniSummaryCard(
            theme: theme,
            isDark: isDark,
            label: 'Expenses',
            icon: Icons.arrow_upward_rounded,
            iconColor: Colors.white,
            fillColor: const Color(0xFFC1121F),
            asyncValue: spentAsync,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniSummaryCard(
            theme: theme,
            isDark: isDark,
            label: 'Set Income',
            icon: Icons.account_balance_rounded,
            iconColor: const Color(0xFF00BCD4),
            fillColor: const Color(0xFF023047),
            fixedValue: formatRupee(_monthlyIncome),
            onTap: () => _showSettingsSheet(context, theme, isDark),
          ),
        ),
      ],
    );
  }

  Widget _miniSummaryCard({
    required ThemeData theme,
    required bool isDark,
    required String label,
    required IconData icon,
    required Color iconColor,
    Color? fillColor,
    AsyncValue<double>? asyncValue,
    String? fixedValue,
    VoidCallback? onTap,
  }) {
    final cardFillColor = isDark
        ? const Color(0xFF1A1A1A)
        : (fillColor ?? iconColor.withValues(alpha: 0.12));
    final cardTextColor =
        ThemeData.estimateBrightnessForColor(cardFillColor) == Brightness.dark
            ? Colors.white
            : theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardFillColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? theme.colorScheme.outline.withValues(alpha: 0.08)
                : (fillColor ?? iconColor).withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cardTextColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 10),
            if (asyncValue != null)
              asyncValue.when(
                data: (val) => Text(
                  formatRupee(val),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cardTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, _) => const Text('--'),
              )
            else if (fixedValue != null)
              Text(
                fixedValue,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cardTextColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, WidgetRef ref, bool isDark) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(selectedMonthTransactionsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Container(
      height: 270,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: transactionsAsync.when(
        data: (transactions) {
          final expenses = transactions.where((t) => !t.isIncome).toList();
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 40,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add expenses to see analytics',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          final categoryTotals = <String, double>{};
          for (final transaction in expenses) {
            categoryTotals[transaction.categoryId] =
                (categoryTotals[transaction.categoryId] ?? 0) + transaction.amount;
          }
          final totalExpense = categoryTotals.values.fold<double>(0, (a, b) => a + b);

          return categoriesAsync.when(
            data: (categories) {
              final categoryMap = {for (final c in categories) c.id: c};

              final ranked = categoryTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              final sections = <PieChartSectionData>[];
              for (var i = 0; i < ranked.length; i++) {
                final entry = ranked[i];
                final category = categoryMap[entry.key];
                final color = category != null
                    ? _safeColorFromHex(category.colorHex)
                    : Colors.grey;
                final percent = totalExpense == 0 ? 0 : (entry.value / totalExpense) * 100;
                final isTouched = i == _touchedPieIndex;

                sections.add(
                  PieChartSectionData(
                    color: color,
                    value: entry.value,
                    title: percent >= 12 ? '${percent.toStringAsFixed(0)}%' : '',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    radius: isTouched ? 54 : 46,
                  ),
                );
              }

              final topCategoryName = ranked.isNotEmpty
                  ? (categoryMap[ranked.first.key]?.name ?? 'Other')
                  : '--';
              final topCategoryAmount = ranked.isNotEmpty ? ranked.first.value : 0.0;
              final averageExpense = expenses.isEmpty ? 0.0 : totalExpense / expenses.length;

              return Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: PieChart(
                            PieChartData(
                              sections: sections,
                              centerSpaceRadius: 36,
                              sectionsSpace: 3,
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  if (!event.isInterestedForInteractions ||
                                      response == null ||
                                      response.touchedSection == null) {
                                    if (_touchedPieIndex != -1) {
                                      setState(() => _touchedPieIndex = -1);
                                    }
                                    return;
                                  }
                                  setState(() {
                                    _touchedPieIndex = response.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total ${formatRupee(totalExpense)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${expenses.length} transactions • Avg ${formatRupee(averageExpense)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: ranked.length > 4 ? 4 : ranked.length,
                                  itemBuilder: (context, index) {
                                    final entry = ranked[index];
                                    final category = categoryMap[entry.key];
                                    final color = category != null
                                        ? _safeColorFromHex(category.colorHex)
                                        : Colors.grey;
                                    final percent = totalExpense == 0
                                        ? 0
                                        : (entry.value / totalExpense) * 100;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 9,
                                                height: 9,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  category?.name ?? 'Other',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${percent.toStringAsFixed(0)}%',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: LinearProgressIndicator(
                                              minHeight: 5,
                                              value: (percent / 100).clamp(0, 1),
                                              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                                              valueColor: AlwaysStoppedAnimation<Color>(color),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Top category: $topCategoryName (${formatRupee(topCategoryAmount)})',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text('Error loading categories'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context, WidgetRef ref, bool isDark) {
    final transactionsAsync = ref.watch(selectedMonthTransactionsProvider);
    final theme = Theme.of(context);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No transactions this month',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddEditTransactionScreen(),
                        ),
                      ),
                      child: const Text('Add Transaction'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final transaction = transactions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Consumer(
                  builder: (context, ref, _) {
                    final categoryAsync = ref.watch(
                      categoryProvider(transaction.categoryId),
                    );
                    return categoryAsync.when(
                      data: (category) => _TransactionTile(
                        transaction: transaction,
                        category: category,
                        isDark: isDark,
                        theme: theme,
                      ),
                      loading: () => const SizedBox(height: 70),
                      error: (e, _) => const SizedBox(height: 70),
                    );
                  },
                ),
              );
            },
            childCount: transactions.length,
          ),
        );
      },
      loading: () =>
          const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
    );
  }

  Color _safeColorFromHex(String colorHex) {
    var hex = colorHex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return Colors.grey;
    return Color(int.parse(hex, radix: 16));
  }
}

class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  final Category? category;
  final bool isDark;
  final ThemeData theme;

  const _TransactionTile({
    required this.transaction,
    required this.category,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = category != null
        ? _safeColorFromHex(category!.colorHex)
        : Colors.grey;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(transactionListProvider.notifier).deleteTransaction(transaction.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: transaction.isIncome
                ? const Color(0xFF2EBD59).withValues(alpha: 0.35)
                : const Color(0xFFE74C3C).withValues(alpha: 0.35),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AddEditTransactionScreen(existingTransaction: transaction),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category != null
                        ? IconData(category!.iconCode, fontFamily: 'MaterialIcons')
                        : Icons.receipt,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Unknown',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (transaction.note != null &&
                          transaction.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          transaction.note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(transaction.date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${transaction.isIncome ? '+' : '-'}${formatRupee(transaction.amount)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: transaction.isIncome
                        ? const Color(0xFF1FA34A)
                        : const Color(0xFFE53935),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _safeColorFromHex(String colorHex) {
    var hex = colorHex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return Colors.grey;
    return Color(int.parse(hex, radix: 16));
  }
}
