import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

class DatabaseService {
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    try {
      final dbPath = await getDatabasesPath();
      return openDatabase(
        join(dbPath, AppConstants.databaseName),
        version: AppConstants.databaseVersion,
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute("ALTER TABLE goals ADD COLUMN metric TEXT NOT NULL DEFAULT 'custom'");
            await db.execute('ALTER TABLE goals ADD COLUMN autoTrack INTEGER NOT NULL DEFAULT 0');
          }
        },
      );
    } catch (e) {
      final dbPath = await getDatabasesPath();
      await deleteDatabase(join(dbPath, AppConstants.databaseName));
      return _open();
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE day_entries(
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        sleepHours REAL NOT NULL,
        waterLiters REAL NOT NULL,
        calories INTEGER NOT NULL,
        weightKg REAL NOT NULL,
        steps INTEGER NOT NULL,
        sportMinutes INTEGER NOT NULL,
        studyMinutes INTEGER NOT NULL,
        workMinutes INTEGER NOT NULL,
        gameMinutes INTEGER NOT NULL,
        screenMinutes INTEGER NOT NULL,
        mood INTEGER NOT NULL,
        stress INTEGER NOT NULL,
        energy INTEGER NOT NULL,
        note TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE habits(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        completedDayKeys TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE goals(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        target REAL NOT NULL,
        current REAL NOT NULL,
        unit TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        metric TEXT NOT NULL DEFAULT 'custom',
        autoTrack INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}
