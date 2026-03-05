import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'suryaprakash.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // ─── Categories ───
    batch.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL DEFAULT 983044,
        color_hex TEXT NOT NULL DEFAULT 'FF3F51B5',
        type TEXT NOT NULL DEFAULT 'expense',
        budget_limit REAL,
        is_income_score INTEGER NOT NULL DEFAULT -1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // ─── Projects ───
    batch.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        color_hex TEXT NOT NULL DEFAULT 'FF3F51B5',
        icon_code INTEGER NOT NULL DEFAULT 983044,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // ─── Tasks ───
    batch.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        priority INTEGER NOT NULL DEFAULT 3,
        due_date TEXT,
        due_time TEXT,
        project_id TEXT,
        parent_task_id TEXT,
        status TEXT NOT NULL DEFAULT 'inbox',
        estimated_minutes INTEGER,
        completed_at TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        modified_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL,
        FOREIGN KEY (parent_task_id) REFERENCES tasks(id) ON DELETE CASCADE
      )
    ''');

    // ─── Task Tags ───
    batch.execute('''
      CREATE TABLE task_tags (
        task_id TEXT NOT NULL,
        tag TEXT NOT NULL,
        PRIMARY KEY (task_id, tag),
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      )
    ''');

    // ─── Transactions (Expenses) ───
    batch.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category_id TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        is_income INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        modified_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    // ─── Transaction Tags ───
    batch.execute('''
      CREATE TABLE transaction_tags (
        transaction_id TEXT NOT NULL,
        tag TEXT NOT NULL,
        PRIMARY KEY (transaction_id, tag),
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
      )
    ''');

    // ─── Monthly Budgets ───
    batch.execute('''
      CREATE TABLE monthly_budgets (
        month_year_str TEXT PRIMARY KEY,
        total_budget REAL NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // ─── Notebooks ───
    batch.execute('''
      CREATE TABLE notebooks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL DEFAULT 'FF3F51B5',
        icon_code INTEGER NOT NULL DEFAULT 983044,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // ─── Notes ───
    batch.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content_markdown TEXT,
        notebook_id TEXT,
        type TEXT NOT NULL DEFAULT 'text',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_locked INTEGER NOT NULL DEFAULT 0,
        voice_memo_path TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        modified_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (notebook_id) REFERENCES notebooks(id) ON DELETE SET NULL
      )
    ''');

    // ─── Note Tags ───
    batch.execute('''
      CREATE TABLE note_tags (
        note_id TEXT NOT NULL,
        tag TEXT NOT NULL,
        PRIMARY KEY (note_id, tag),
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');

    // ─── Reminders ───
    batch.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        datetime TEXT NOT NULL,
        recurrence_rule TEXT,
        notification_id INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // ─── Events ───
    batch.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        start_datetime TEXT NOT NULL,
        end_datetime TEXT NOT NULL,
        is_all_day INTEGER NOT NULL DEFAULT 0,
        color_hex TEXT NOT NULL DEFAULT 'FF3F51B5',
        recurrence_rule TEXT,
        reminder_minutes_before INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // ─── Habits ───
    batch.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon_code INTEGER NOT NULL DEFAULT 983044,
        color_hex TEXT NOT NULL DEFAULT 'FF009688',
        frequency TEXT NOT NULL DEFAULT 'daily',
        target_count INTEGER NOT NULL DEFAULT 1,
        streak_count INTEGER NOT NULL DEFAULT 0,
        best_streak INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // ─── Habit Logs ───
    batch.execute('''
      CREATE TABLE habit_logs (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE,
        UNIQUE(habit_id, date)
      )
    ''');

    // ─── Journal Entries ───
    batch.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        template TEXT NOT NULL DEFAULT 'freeform',
        content TEXT,
        mood INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        modified_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // ─── Vault Items ───
    batch.execute('''
      CREATE TABLE vault_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        encrypted_data TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'password',
        icon_code INTEGER NOT NULL DEFAULT 983044,
        expiry_date TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        modified_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // ─── Goals ───
    batch.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        deadline TEXT,
        progress REAL NOT NULL DEFAULT 0.0,
        color_hex TEXT NOT NULL DEFAULT 'FF3F51B5',
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // ─── Milestones ───
    batch.execute('''
      CREATE TABLE milestones (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');

    // ─── Seed default categories ───
    batch.execute('''
      INSERT INTO categories (id, name, icon_code, color_hex, type) VALUES
        ('cat_food', 'Food & Dining', 984380, 'FFFF7043', 'expense'),
        ('cat_transport', 'Transport', 984653, 'FF42A5F5', 'expense'),
        ('cat_shopping', 'Shopping', 984140, 'FFAB47BC', 'expense'),
        ('cat_bills', 'Bills & Utilities', 984273, 'FF66BB6A', 'expense'),
        ('cat_health', 'Health', 984003, 'FFEF5350', 'expense'),
        ('cat_entertainment', 'Entertainment', 983895, 'FFFFCA28', 'expense'),
        ('cat_education', 'Education', 984169, 'FF26C6DA', 'expense'),
        ('cat_other', 'Other', 983044, 'FF78909C', 'expense')
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // For phase 3 dev, dropping and rebuilding financial tables to match new schema
      await db.execute('DROP TABLE IF EXISTS transaction_tags');
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS monthly_budgets');
      await db.execute('DROP TABLE IF EXISTS categories');

      await db.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon_code INTEGER NOT NULL DEFAULT 983044,
          color_hex TEXT NOT NULL DEFAULT 'FF3F51B5',
          type TEXT NOT NULL DEFAULT 'expense',
          budget_limit REAL,
          is_income_score INTEGER NOT NULL DEFAULT -1,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');

      await db.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          amount REAL NOT NULL,
          category_id TEXT NOT NULL,
          date TEXT NOT NULL,
          note TEXT,
          is_income INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          modified_at TEXT NOT NULL DEFAULT (datetime('now')),
          FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE transaction_tags (
          transaction_id TEXT NOT NULL,
          tag TEXT NOT NULL,
          PRIMARY KEY (transaction_id, tag),
          FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE monthly_budgets (
          month_year_str TEXT PRIMARY KEY,
          total_budget REAL NOT NULL,
          created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');

      await db.execute('''
        INSERT INTO categories (id, name, icon_code, color_hex, type, is_income_score) VALUES
          ('cat_food', 'Food & Dining', 984380, 'FFFF7043', 'expense', -1),
          ('cat_transport', 'Transport', 984653, 'FF42A5F5', 'expense', -1),
          ('cat_shopping', 'Shopping', 984140, 'FFAB47BC', 'expense', -1),
          ('cat_bills', 'Bills & Utilities', 984273, 'FF66BB6A', 'expense', -1),
          ('cat_health', 'Health', 984003, 'FFEF5350', 'expense', -1),
          ('cat_salary', 'Salary', 983084, 'FF4CAF50', 'income', 1),
          ('cat_gift', 'Gift/Bonus', 983226, 'xFFFFD54F', 'income', 1),
          ('cat_other', 'Other', 983044, 'FF78909C', 'expense', 0)
      ''');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
