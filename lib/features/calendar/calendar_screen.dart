import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/calendar_providers.dart';
import 'add_edit_event_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : theme.colorScheme.surface;
    
    // Watch providers
    final selectedDay = ref.watch(selectedDayProvider);
    final eventsAsync = ref.watch(eventsProvider); // For markers
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Event',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => AddEditEventScreen(selectedDate: selectedDay)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Today',
            onPressed: () {
              setState(() => _focusedDay = DateTime.now());
              ref.read(selectedDayProvider.notifier).updateDay(DateTime.now());
            },
          ),
          PopupMenuButton<CalendarFormat>(
            icon: const Icon(Icons.calendar_view_week),
            itemBuilder: (context) => [
              const PopupMenuItem(value: CalendarFormat.month, child: Text('Month View')),
              const PopupMenuItem(value: CalendarFormat.week, child: Text('Week View')),
              const PopupMenuItem(value: CalendarFormat.twoWeeks, child: Text('2 Week View')),
            ],
            onSelected: (format) => setState(() => _calendarFormat = format),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTableCalendar(theme, isDark, selectedDay, eventsAsync.asData?.value ?? []),
          const SizedBox(height: 8),
          Expanded(
            child: _buildEventList(theme, isDark, selectedDay),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCalendar(ThemeData theme, bool isDark, DateTime selectedDay, List<Event> allEvents) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: TableCalendar<Event>(
        rowHeight: 40,
        daysOfWeekHeight: 24,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        eventLoader: (day) {
          return allEvents.where((e) {
            final eStart = DateTime(e.startDateTime.year, e.startDateTime.month, e.startDateTime.day);
            final eEnd = DateTime(e.endDateTime.year, e.endDateTime.month, e.endDateTime.day);
            final d = DateTime(day.year, day.month, day.day);
            return d.isAtSameMomentAs(eStart) || d.isAtSameMomentAs(eEnd) || (d.isAfter(eStart) && d.isBefore(eEnd));
          }).toList();
        },
        onDaySelected: (selected, focused) {
          if (!isSameDay(selectedDay, selected)) {
            ref.read(selectedDayProvider.notifier).updateDay(selected);
            setState(() => _focusedDay = focused);
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) setState(() => _calendarFormat = format);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ]
          ),
          weekendTextStyle: TextStyle(color: theme.colorScheme.error.withValues(alpha: 0.8)),
          outsideDaysVisible: false,
          markerDecoration: BoxDecoration(
            color: theme.colorScheme.tertiary,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
          leftChevronIcon: Icon(Icons.chevron_left, color: theme.colorScheme.onSurface),
          rightChevronIcon: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildEventList(ThemeData theme, bool isDark, DateTime selectedDay) {
    final dayEventsAsync = ref.watch(selectedDayEventsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Text(
            DateFormat('EEEE, MMMM d').format(selectedDay),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: dayEventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return _buildEmptyState(theme);
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 100),
                physics: const BouncingScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return _EventCard(event: events[index], isDark: isDark, theme: theme);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading events: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 40, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          Text(
            'No events scheduled',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  final Event event;
  final bool isDark;
  final ThemeData theme;

  const _EventCard({required this.event, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(int.parse('0x${event.colorHex}'));
    final timeStr = event.isAllDay 
      ? 'All Day' 
      : '${DateFormat('h:mm a').format(event.startDateTime)} - ${DateFormat('h:mm a').format(event.endDateTime)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(event.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) {
          ref.read(eventsProvider.notifier).deleteEvent(event.id);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => AddEditEventScreen(existingEvent: event)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (event.description != null && event.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.description!,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

