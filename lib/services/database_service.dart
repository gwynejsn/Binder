import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// this file is intended for configuring, initialization, and accessing the sqlite
// we are using sqflite plugin
// read more on the docs!
// https://docs.flutter.dev/cookbook/persistence/sqlite#example
// https://pub.dev/packages/sqflite
class DatabaseService {
  Database? _database;

  Future<Database> getDatabase() async {
    // if the database is already opened, just return it
    // para no duplicates!
    if (_database != null) {
      return _database!;
    }

    // otherwise, initialize and open it
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    // using of join is good practice (sabi sa docs)
    final path = join(dbPath, 'binder.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // enables foreign keys so cascading deletes work (this is a sql command)
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // create Todos table
        await db.execute('''
          CREATE TABLE todos (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            notes TEXT,
            priority TEXT NOT NULL,
            deadline TEXT,
            binder_id TEXT,
            is_completed INTEGER NOT NULL DEFAULT 0,
            completed_pomodoros INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // create Attachments table
        await db.execute('''
          CREATE TABLE todo_attachments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            todo_id TEXT NOT NULL,
            path TEXT,
            asset_id TEXT,
            thumb_uri TEXT,
            FOREIGN KEY (todo_id) REFERENCES todos (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
