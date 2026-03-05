import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/calendar_repository.dart';

// ─── Repository Provider ─── //
final calendarRepositoryProvider = Provider((ref) => CalendarRepository());

// ─── Selected Day Provider ─── //
class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void updateDay(DateTime day) {
    state = day;
  }
}

final selectedDayProvider = NotifierProvider<SelectedDayNotifier, DateTime>(
  SelectedDayNotifier.new,
);

// ─── Event Providers ─── //
class EventsNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() async {
    return ref.read(calendarRepositoryProvider).getAllEvents();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(calendarRepositoryProvider).getAllEvents());
  }

  Future<void> addEvent(Event event) async {
    await ref.read(calendarRepositoryProvider).insertEvent(event);
    await refresh();
  }

  Future<void> updateEvent(Event event) async {
    await ref.read(calendarRepositoryProvider).updateEvent(event);
    await refresh();
  }

  Future<void> deleteEvent(String id) async {
    await ref.read(calendarRepositoryProvider).deleteEvent(id);
    await refresh();
  }
}

final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<Event>>(
  EventsNotifier.new,
);

// Filtered to Selected Day
final selectedDayEventsProvider = FutureProvider<List<Event>>((ref) async {
  // Watch the full event list to trigger rebuilds on changes
  ref.watch(eventsProvider);
  final selectedDay = ref.watch(selectedDayProvider);
  return ref.read(calendarRepositoryProvider).getEventsForDay(selectedDay);
});

// ─── Reminder Providers ─── //
class RemindersNotifier extends AsyncNotifier<List<Reminder>> {
  @override
  Future<List<Reminder>> build() async {
    return ref.read(calendarRepositoryProvider).getPendingReminders();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(calendarRepositoryProvider).getPendingReminders());
  }

  Future<void> addReminder(Reminder reminder) async {
    await ref.read(calendarRepositoryProvider).insertReminder(reminder);
    await refresh();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await ref.read(calendarRepositoryProvider).updateReminder(reminder);
    await refresh();
  }

  Future<void> deleteReminder(String id) async {
    await ref.read(calendarRepositoryProvider).deleteReminder(id);
    await refresh();
  }
  
  Future<void> markCompleted(Reminder reminder) async {
    final updated = Reminder(
      id: reminder.id,
      title: reminder.title,
      description: reminder.description,
      dateTime: reminder.dateTime,
      recurrenceRule: reminder.recurrenceRule,
      notificationId: reminder.notificationId,
      isCompleted: true,
      createdAt: reminder.createdAt,
    );
    await ref.read(calendarRepositoryProvider).updateReminder(updated);
    await refresh(); // It will disappear from pending list
  }
}

final pendingRemindersProvider = AsyncNotifierProvider<RemindersNotifier, List<Reminder>>(
  RemindersNotifier.new,
);
