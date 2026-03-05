import 'package:equatable/equatable.dart';

// ─── Category ───
class Category extends Equatable {
  final String id;
  final String name;
  final int iconCode;
  final String colorHex;
  final String type; // expense, task, note
  final double? budgetLimit;
  final int isIncomeScore; // 1 = Income, -1 = Expense, 0 = Both
  final int sortOrder;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorHex,
    required this.type,
    this.budgetLimit,
    this.isIncomeScore = -1,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      iconCode: map['icon_code'] as int,
      colorHex: map['color_hex'] as String,
      type: map['type'] as String,
      budgetLimit: map['budget_limit'] as double?,
      isIncomeScore: map['is_income_score'] as int? ?? -1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code': iconCode,
      'color_hex': colorHex,
      'type': type,
      'budget_limit': budgetLimit,
      'is_income_score': isIncomeScore,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [id, name, iconCode, colorHex, type, budgetLimit, sortOrder];
}

// ─── Transaction ───
class Transaction extends Equatable {
  final String id;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String? note;
  final bool isIncome;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const Transaction({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    this.isIncome = false,
    this.tags = const [],
    required this.createdAt,
    required this.modifiedAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      isIncome: (map['is_income'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      modifiedAt: DateTime.parse(map['modified_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'note': note,
      'is_income': isIncome ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, amount, categoryId, date, isIncome];
}

// ─── Monthly Budget ───
class MonthlyBudget extends Equatable {
  final String monthYearStr; // Format: "YYYY-MM"
  final double totalBudget;
  final DateTime createdAt;

  const MonthlyBudget({
    required this.monthYearStr,
    required this.totalBudget,
    required this.createdAt,
  });

  factory MonthlyBudget.fromMap(Map<String, dynamic> map) {
    return MonthlyBudget(
      monthYearStr: map['month_year_str'] as String,
      totalBudget: (map['total_budget'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month_year_str': monthYearStr,
      'total_budget': totalBudget,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [monthYearStr, totalBudget];
}

// ─── Project ───
class Project extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String colorHex;
  final int iconCode;
  final bool isArchived;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.colorHex,
    required this.iconCode,
    this.isArchived = false,
    required this.createdAt,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      colorHex: map['color_hex'] as String,
      iconCode: map['icon_code'] as int,
      isArchived: (map['is_archived'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color_hex': colorHex,
      'icon_code': iconCode,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, description, isArchived];
}

// ─── Task ───
class Task extends Equatable {
  final String id;
  final String title;
  final String? description;
  final int priority; // 0 = P0 (highest), 3 = P3 (lowest)
  final DateTime? dueDate;
  final String? dueTime;
  final String? projectId;
  final String? parentTaskId;
  final String status; // inbox, backlog, in_progress, done
  final int? estimatedMinutes;
  final DateTime? completedAt;
  final int sortOrder;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.priority = 3,
    this.dueDate,
    this.dueTime,
    this.projectId,
    this.parentTaskId,
    this.status = 'inbox',
    this.estimatedMinutes,
    this.completedAt,
    this.sortOrder = 0,
    this.tags = const [],
    required this.createdAt,
    required this.modifiedAt,
  });

  bool get isCompleted => status == 'done';
  bool get isOverdue =>
      dueDate != null &&
      !isCompleted &&
      dueDate!.isBefore(DateTime.now());

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: map['priority'] as int? ?? 3,
      dueDate:
          map['due_date'] != null
              ? DateTime.parse(map['due_date'] as String)
              : null,
      dueTime: map['due_time'] as String?,
      projectId: map['project_id'] as String?,
      parentTaskId: map['parent_task_id'] as String?,
      status: map['status'] as String? ?? 'inbox',
      estimatedMinutes: map['estimated_minutes'] as int?,
      completedAt:
          map['completed_at'] != null
              ? DateTime.parse(map['completed_at'] as String)
              : null,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      modifiedAt: DateTime.parse(map['modified_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'due_time': dueTime,
      'project_id': projectId,
      'parent_task_id': parentTaskId,
      'status': status,
      'estimated_minutes': estimatedMinutes,
      'completed_at': completedAt?.toIso8601String(),
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  Task copyWith({
    String? title,
    String? description,
    int? priority,
    DateTime? dueDate,
    String? dueTime,
    String? projectId,
    String? status,
    int? estimatedMinutes,
    DateTime? completedAt,
    int? sortOrder,
    List<String>? tags,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      projectId: projectId ?? this.projectId,
      parentTaskId: parentTaskId,
      status: status ?? this.status,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      completedAt: completedAt ?? this.completedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      modifiedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, title, status, priority, dueDate];
}

// ─── Note ───
class Note extends Equatable {
  final String id;
  final String title;
  final String? contentMarkdown;
  final String? notebookId;
  final String type; // text, checklist, voice, sketch
  final bool isPinned;
  final bool isLocked;
  final String? voiceMemoPath;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const Note({
    required this.id,
    required this.title,
    this.contentMarkdown,
    this.notebookId,
    this.type = 'text',
    this.isPinned = false,
    this.isLocked = false,
    this.voiceMemoPath,
    this.tags = const [],
    required this.createdAt,
    required this.modifiedAt,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      contentMarkdown: map['content_markdown'] as String?,
      notebookId: map['notebook_id'] as String?,
      type: map['type'] as String? ?? 'text',
      isPinned: (map['is_pinned'] as int?) == 1,
      isLocked: (map['is_locked'] as int?) == 1,
      voiceMemoPath: map['voice_memo_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      modifiedAt: DateTime.parse(map['modified_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content_markdown': contentMarkdown,
      'notebook_id': notebookId,
      'type': type,
      'is_pinned': isPinned ? 1 : 0,
      'is_locked': isLocked ? 1 : 0,
      'voice_memo_path': voiceMemoPath,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  Note copyWith({
    String? title,
    String? contentMarkdown,
    String? notebookId,
    String? type,
    bool? isPinned,
    bool? isLocked,
    List<String>? tags,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      notebookId: notebookId ?? this.notebookId,
      type: type ?? this.type,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      voiceMemoPath: voiceMemoPath,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      modifiedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, title, type, isPinned, notebookId];
}

class Notebook extends Equatable {
  final String id;
  final String name;
  final String colorHex;
  final int iconCode;
  final int sortOrder;
  final DateTime createdAt;

  const Notebook({
    required this.id,
    required this.name,
    this.colorHex = 'FF3F51B5', // Default Indigo
    this.iconCode = 983044, // Default material icon book
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Notebook.fromMap(Map<String, dynamic> map) {
    return Notebook(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String? ?? 'FF3F51B5',
      iconCode: map['icon_code'] as int? ?? 983044,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'icon_code': iconCode,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Notebook copyWith({
    String? name,
    String? colorHex,
    int? iconCode,
    int? sortOrder,
  }) {
    return Notebook(
      id: id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconCode: iconCode ?? this.iconCode,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, colorHex, iconCode, sortOrder];
}

// ─── Event ───
class Event extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAllDay;
  final String colorHex;
  final String? recurrenceRule;
  final int? reminderMinutesBefore;
  final DateTime createdAt;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.startDateTime,
    required this.endDateTime,
    this.isAllDay = false,
    required this.colorHex,
    this.recurrenceRule,
    this.reminderMinutesBefore,
    required this.createdAt,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      startDateTime: DateTime.parse(map['start_datetime'] as String),
      endDateTime: DateTime.parse(map['end_datetime'] as String),
      isAllDay: (map['is_all_day'] as int?) == 1,
      colorHex: map['color_hex'] as String,
      recurrenceRule: map['recurrence_rule'] as String?,
      reminderMinutesBefore: map['reminder_minutes_before'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_datetime': startDateTime.toIso8601String(),
      'end_datetime': endDateTime.toIso8601String(),
      'is_all_day': isAllDay ? 1 : 0,
      'color_hex': colorHex,
      'recurrence_rule': recurrenceRule,
      'reminder_minutes_before': reminderMinutesBefore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, startDateTime, endDateTime, isAllDay];
}

// ─── Reminder ───
class Reminder extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final String? recurrenceRule;
  final int? notificationId;
  final bool isCompleted;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.recurrenceRule,
    this.notificationId,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dateTime: DateTime.parse(map['datetime'] as String),
      recurrenceRule: map['recurrence_rule'] as String?,
      notificationId: map['notification_id'] as int?,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'datetime': dateTime.toIso8601String(),
      'recurrence_rule': recurrenceRule,
      'notification_id': notificationId,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, dateTime, isCompleted];
}

// ─── Habit ───
class Habit extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int iconCode;
  final String colorHex;
  final String frequency; // daily, weekly
  final int targetCount;
  final int streakCount;
  final int bestStreak;
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.name,
    this.description,
    required this.iconCode,
    required this.colorHex,
    this.frequency = 'daily',
    this.targetCount = 1,
    this.streakCount = 0,
    this.bestStreak = 0,
    required this.createdAt,
  });

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconCode: map['icon_code'] as int,
      colorHex: map['color_hex'] as String,
      frequency: map['frequency'] as String? ?? 'daily',
      targetCount: map['target_count'] as int? ?? 1,
      streakCount: map['streak_count'] as int? ?? 0,
      bestStreak: map['best_streak'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_code': iconCode,
      'color_hex': colorHex,
      'frequency': frequency,
      'target_count': targetCount,
      'streak_count': streakCount,
      'best_streak': bestStreak,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, frequency, streakCount];
}

// ─── Habit Log ───
class HabitLog extends Equatable {
  final String id;
  final String habitId;
  final DateTime date;
  final int count;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    this.count = 1,
  });

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      date: DateTime.parse(map['date'] as String),
      count: map['count'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String().split('T').first, // store as YYYY-MM-DD
      'count': count,
    };
  }

  @override
  List<Object?> get props => [id, habitId, date, count];
}

// ─── Journal Entry ───
class JournalEntry extends Equatable {
  final String id;
  final DateTime date;
  final String template; // gratitude, daily_review, freeform
  final String? content;
  final int? mood; // 1-5
  final DateTime createdAt;
  final DateTime modifiedAt;

  const JournalEntry({
    required this.id,
    required this.date,
    this.template = 'freeform',
    this.content,
    this.mood,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      template: map['template'] as String? ?? 'freeform',
      content: map['content'] as String?,
      mood: map['mood'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      modifiedAt: DateTime.parse(map['modified_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'template': template,
      'content': content,
      'mood': mood,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, date, template, mood];
}

// ─── Goal ───
class Goal extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime? deadline;
  final double progress;
  final String colorHex;
  final bool isCompleted;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.title,
    this.description,
    this.deadline,
    this.progress = 0.0,
    required this.colorHex,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      deadline:
          map['deadline'] != null
              ? DateTime.parse(map['deadline'] as String)
              : null,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      colorHex: map['color_hex'] as String,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'progress': progress,
      'color_hex': colorHex,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, progress, isCompleted];
}

// ─── Vault Item ───
class VaultItem extends Equatable {
  final String id;
  final String title;
  final String encryptedData;
  final String category; // password, document, id_card
  final int iconCode;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const VaultItem({
    required this.id,
    required this.title,
    required this.encryptedData,
    this.category = 'password',
    required this.iconCode,
    this.expiryDate,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory VaultItem.fromMap(Map<String, dynamic> map) {
    return VaultItem(
      id: map['id'] as String,
      title: map['title'] as String,
      encryptedData: map['encrypted_data'] as String,
      category: map['category'] as String? ?? 'password',
      iconCode: map['icon_code'] as int,
      expiryDate:
          map['expiry_date'] != null
              ? DateTime.parse(map['expiry_date'] as String)
              : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      modifiedAt: DateTime.parse(map['modified_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'encrypted_data': encryptedData,
      'category': category,
      'icon_code': iconCode,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, category, expiryDate];
}
