import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/home_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/expenses/expenses_screen.dart';
import '../../features/more/more_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TasksScreen(),
    CalendarScreen(),
    ExpensesScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161A22) : Colors.white,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFFD9DFEA),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: selected
                        ? const Color(0xFF4A56E2)
                        : (isDark ? const Color(0xFF8E99AB) : const Color(0xFF8B97AD)),
                    size: 23,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() => _currentIndex = index);
                },
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                animationDuration: const Duration(milliseconds: 320),
                height: 74,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.dashboard_outlined, color: Color(0xFF9AA5BC)),
                    selectedIcon: _selectedNavCircleIcon(
                      icon: Icons.dashboard,
                      iconColor: const Color(0xFF4A56E2),
                      isDark: isDark,
                    ),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.check_circle_outline, color: Color(0xFF9AA5BC)),
                    selectedIcon: _selectedNavCircleIcon(
                      icon: Icons.check_circle,
                      iconColor: const Color(0xFF00BFA5),
                      isDark: isDark,
                    ),
                    label: 'Tasks',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF9AA5BC)),
                    selectedIcon: _selectedNavCircleIcon(
                      icon: Icons.calendar_month,
                      iconColor: const Color(0xFFFF4FA3),
                      isDark: isDark,
                    ),
                    label: 'Calendar',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF9AA5BC)),
                    selectedIcon: _selectedNavCircleIcon(
                      icon: Icons.account_balance_wallet,
                      iconColor: const Color(0xFFFF9F1C),
                      isDark: isDark,
                    ),
                    label: 'Expenses',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.grid_view_outlined, color: Color(0xFF9AA5BC)),
                    selectedIcon: _selectedNavCircleIcon(
                      icon: Icons.grid_view,
                      iconColor: const Color(0xFF7C4DFF),
                      isDark: isDark,
                    ),
                    label: 'More',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectedNavCircleIcon({
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? const Color(0xFF2A3148)
            : const Color(0xFFE7EAF9),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: isDark ? 0.30 : 0.24),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}
