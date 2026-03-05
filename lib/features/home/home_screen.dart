import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/task_providers.dart';
import '../../core/providers/expense_providers.dart';
import '../../core/providers/calendar_providers.dart';
import '../tasks/add_edit_task_screen.dart';
import '../calendar/calendar_screen.dart';
import '../expenses/add_edit_transaction_screen.dart';
import '../expenses/expenses_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF3F0FF),
      body: Stack(
        children: [
          // Main Scroll Content
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 24),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, isDark),
                          const SizedBox(height: 32),

                          // Today's Focus (Primary Banner)
                          _buildTodayFocusBanner(context, ref, isDark),
                          const SizedBox(height: 32),

                          // Asymmetrical Quick Actions
                          _buildSectionTitle(context, 'Quick Actions', isDark),
                          const SizedBox(height: 16),
                          _buildAsymmetricalQuickActions(context, isDark),
                          const SizedBox(height: 32),

                          // Today's Overview
                          _buildSectionTitle(context, 'Today Overview', isDark),
                          const SizedBox(height: 16),
                          _buildTodayOverviewCard(context, ref, isDark),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOverviewCard(BuildContext context, WidgetRef ref, bool isDark) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(todayTasksProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final transactionsAsync = ref.watch(transactionListProvider);
    final today = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2D) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFD9DFEA),
        ),
      ),
      child: Column(
        children: [
          _todayInfoRow(
            context,
            isDark: isDark,
            icon: Icons.task_alt_rounded,
            iconColor: const Color(0xFF3B82F6),
            label: 'Today Tasks',
            value: tasksAsync.when(
              data: (tasks) => '${tasks.length}',
              loading: () => '...',
              error: (_, __) => '--',
            ),
            subtitle: tasksAsync.when(
              data: (tasks) => tasks.isEmpty ? 'No tasks planned' : 'Tasks planned for today',
              loading: () => 'Loading tasks',
              error: (_, __) => 'Could not load tasks',
            ),
          ),
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E8F1), height: 24),
          _todayInfoRow(
            context,
            isDark: isDark,
            icon: Icons.event_available_rounded,
            iconColor: const Color(0xFF8B5CF6),
            label: 'Today Event',
            value: eventsAsync.when(
              data: (events) {
                final todayEvents = events.where((e) => _isSameDate(e.startDateTime, today)).toList();
                return todayEvents.isEmpty ? '0' : '${todayEvents.length}';
              },
              loading: () => '...',
              error: (_, __) => '--',
            ),
            subtitle: eventsAsync.when(
              data: (events) {
                final todayEvents = events.where((e) => _isSameDate(e.startDateTime, today)).toList();
                if (todayEvents.isEmpty) return 'No events for today';
                return todayEvents.first.title;
              },
              loading: () => 'Loading events',
              error: (_, __) => 'Could not load events',
            ),
          ),
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E8F1), height: 24),
          _todayInfoRow(
            context,
            isDark: isDark,
            icon: Icons.payments_rounded,
            iconColor: const Color(0xFFE63946),
            label: 'Today Expense',
            value: transactionsAsync.when(
              data: (transactions) {
                final todayExpense = transactions
                    .where((t) => !t.isIncome && _isSameDate(t.date, today))
                    .fold<double>(0, (sum, t) => sum + t.amount);
                return formatRupee(todayExpense);
              },
              loading: () => '...',
              error: (_, __) => '--',
            ),
            subtitle: transactionsAsync.when(
              data: (transactions) {
                final count = transactions.where((t) => !t.isIncome && _isSameDate(t.date, today)).length;
                return count == 0 ? 'No expense today' : '$count expense entries today';
              },
              loading: () => 'Loading expenses',
              error: (_, __) => 'Could not load expenses',
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayInfoRow(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDark ? Colors.white70 : const Color(0xFF667085),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : const Color(0xFF7B859E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ── Header & Greeting ──
  Widget _buildHeader(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
          ),
          child: Text(
            DateFormat('E, MMM d').format(DateTime.now()).toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark
                ? [const Color(0xFF4DD8FF), const Color(0xFF6A7BFF)]
                : [const Color(0xFF1990FF), const Color(0xFF6D4DFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            '${_getGreeting()},\nSuryaprakash',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let’s make today meaningful.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF5E6782),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, bool isDark) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  // ── Today's Focus Banner (Hero) ──
  Widget _buildTodayFocusBanner(BuildContext context, WidgetRef ref, bool isDark) {
    final tasksAsync = ref.watch(todayTasksProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final transactionsAsync = ref.watch(transactionListProvider);
    final today = DateTime.now();

    if (tasksAsync.isLoading || eventsAsync.isLoading || transactionsAsync.isLoading) {
      return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
    }

    if (tasksAsync.hasError || eventsAsync.hasError || transactionsAsync.hasError) {
      return _animatedBanner(
        _HeroBannerCard(
          title: 'Daily Snapshot',
          subtitle: 'Tap to refresh your dashboard.',
          extraText: 'Some data is temporarily unavailable',
          icon: Icons.dashboard_customize_rounded,
          gradient: const [Color(0xFF5A5A72), Color(0xFF3B4261)],
          onTap: () {},
        ),
      );
    }

    final tasks = tasksAsync.value ?? const <Task>[];
    final events = eventsAsync.value ?? const <Event>[];
    final transactions = transactionsAsync.value ?? const <Transaction>[];

    final todayEvents = events.where((e) => _isSameDate(e.startDateTime, today)).toList();
    final todayExpense = transactions
        .where((t) => !t.isIncome && _isSameDate(t.date, today))
        .fold<double>(0, (sum, t) => sum + t.amount);

    if (tasks.isNotEmpty) {
      final nextTask = tasks.first;
      final extra = [
        if (nextTask.dueTime != null) 'Due at ${nextTask.dueTime}',
        if (todayEvents.isNotEmpty) '${todayEvents.length} event${todayEvents.length > 1 ? 's' : ''} today',
      ].join(' • ');

      return _animatedBanner(
        _HeroBannerCard(
          title: 'On Track',
          subtitle: nextTask.title,
          extraText: extra.isEmpty ? 'Tap to complete your next priority' : extra,
          icon: Icons.track_changes_rounded,
          gradient: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddEditTaskScreen(existingTask: nextTask)),
          ),
        ),
      );
    }

    if (todayEvents.isNotEmpty) {
      return _animatedBanner(
        _HeroBannerCard(
          title: 'Event Day',
          subtitle: todayEvents.first.title,
          extraText: '${todayEvents.length} event${todayEvents.length > 1 ? 's' : ''} scheduled today',
          icon: Icons.event_available_rounded,
          gradient: const [Color(0xFF7F5CFF), Color(0xFFB15CFF)],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CalendarScreen()),
          ),
        ),
      );
    }

    if (todayExpense > 0) {
      return _animatedBanner(
        _HeroBannerCard(
          title: 'Spend Check',
          subtitle: 'Today spent ${formatRupee(todayExpense)}',
          extraText: 'Tap to review your expense flow',
          icon: Icons.account_balance_wallet_rounded,
          gradient: const [Color(0xFF7B1E3A), Color(0xFFC1121F)],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExpensesScreen()),
          ),
        ),
      );
    }

    return _animatedBanner(
      _HeroBannerCard(
        title: 'All Caught Up!',
        subtitle: 'Enjoy your free time.',
        extraText: 'Start a quick task to keep momentum',
        icon: Icons.celebration_rounded,
        gradient: const [Color(0xFF7F5CFF), Color(0xFFB15CFF)],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
        ),
      ),
    );
  }

  Widget _animatedBanner(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, builtChild) => Transform.scale(scale: value, child: builtChild),
      child: child,
    );
  }

  // ── Asymmetrical Quick Actions ──
  Widget _buildAsymmetricalQuickActions(BuildContext context, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GlassActionPill(
                icon: Icons.add_task_rounded,
                label: 'New Task',
                gradient: const [Color(0xFF0D2D4A), Color(0xFF154E75)],
                iconColor: const Color(0xFF33E6FF),
                isDark: isDark,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditTaskScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassActionPill(
                icon: Icons.receipt_long_rounded,
                label: 'Expense',
                gradient: const [Color(0xFF3A1634), Color(0xFF61245A)],
                iconColor: const Color(0xFFFF61BC),
                isDark: isDark,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditTransactionScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GlassActionPill(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                gradient: const [Color(0xFF241F4A), Color(0xFF3F3476)],
                iconColor: const Color(0xFF9C84FF),
                isDark: isDark,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalendarScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassActionPill(
                icon: Icons.edit_note_rounded,
                label: 'Quick Note',
                gradient: const [Color(0xFF3A321A), Color(0xFF5B4B1E)],
                iconColor: const Color(0xFFFFD95C),
                isDark: isDark,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Financial Summary (Neon Glassmorphism) ──
  Widget _buildNeonFinancialSummary(BuildContext context, WidgetRef ref, bool isDark) {
    final theme = Theme.of(context);
    final spentAsync = ref.watch(currentMonthSpentProvider);
    final incomeAsync = ref.watch(currentMonthIncomeProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              // Spent
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFFFF4D6D).withValues(alpha: 0.18), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFE63946), size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text('Spent', style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    spentAsync.when(
                      data: (spent) => Text(formatRupee(spent), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFFE63946), letterSpacing: -1)),
                      loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, _) => const Text('--'),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(width: 1, height: 60, color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
              const SizedBox(width: 20),
              // Income
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFF2ECC71).withValues(alpha: 0.18), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF1E9E57), size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text('Income', style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    incomeAsync.when(
                      data: (income) => Text(formatRupee(income), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF1E9E57), letterSpacing: -1)),
                      loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, _) => const Text('--'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Today's Tasks List ──
  Widget _buildTodayTasks(BuildContext context, WidgetRef ref, bool isDark) {
    final tasksAsync = ref.watch(todayTasksProvider);

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text("No high priority tasks today.", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
            ),
          );
        }
        return Column(
          children: tasks.take(4).map((task) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ModernListTile(
              title: task.title,
              subtitle: task.dueTime ?? 'Project: Inbox',
              icon: Icons.crop_square_rounded,
              color: task.priority == 0 ? const Color(0xFFFF0844) : (task.priority == 1 ? const Color(0xFFFEE140) : const Color(0xFF00F2FE)),
              isDark: isDark,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditTaskScreen(existingTask: task))),
              onIconTap: () => ref.read(taskListProvider.notifier).completeTask(task.id),
            ),
          )).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _LightHomeBackground extends StatelessWidget {
  const _LightHomeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF121731),
            Color(0xFF1D2250),
          ],
        ),
      ),
    );
  }
}

// ── Hero Banner Component ──
class _HeroBannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? extraText;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _HeroBannerCard({
    required this.title,
    required this.subtitle,
    this.extraText,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1)),
                ),
                Icon(icon, color: Colors.white, size: 28),
              ],
            ),
            const SizedBox(height: 24),
            Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5)),
            if (extraText != null) ...[
              const SizedBox(height: 8),
              Text(extraText!, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Glass Action Pill ──
class _GlassActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color iconColor;
  final bool isDark;
  final bool isFullWidth;
  final VoidCallback onTap;

  const _GlassActionPill({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.iconColor,
    required this.isDark,
    this.isFullWidth = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisAlignment: isFullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFF1F4FF), fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modern List Tile ──
class _ModernListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onIconTap;

  const _ModernListTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
    required this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onIconTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }
}

// ── Aurora Background Effect ──
class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pink Blob
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(color: const Color(0xFFFF0844).withValues(alpha: 0.2), shape: BoxShape.circle),
          ),
        ),
        // Blue Blob
        Positioned(
          top: 200,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(color: const Color(0xFF00C6FF).withValues(alpha: 0.2), shape: BoxShape.circle),
          ),
        ),
        // Purple Blob
        Positioned(
          bottom: 100,
          right: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(color: const Color(0xFF6A11CB).withValues(alpha: 0.15), shape: BoxShape.circle),
          ),
        ),
        // Massive Blur Filter covering everything
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
