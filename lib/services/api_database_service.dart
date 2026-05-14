import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/api_log_model.dart';
import '../models/api_session_model.dart';

class ApiDatabaseService {
  static final ApiDatabaseService _instance = ApiDatabaseService._internal();
  factory ApiDatabaseService() => _instance;
  ApiDatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'api_debugger.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id TEXT PRIMARY KEY,
            name TEXT,
            startTime TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE logs (
            id TEXT PRIMARY KEY,
            sessionId TEXT,
            method TEXT,
            url TEXT,
            requestHeaders TEXT,
            requestBody TEXT,
            responseHeaders TEXT,
            responseBody TEXT,
            statusCode INTEGER,
            timestamp TEXT,
            durationMs INTEGER,
            screenName TEXT,
            isError INTEGER,
            FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE sessions ADD COLUMN name TEXT');
          // For existing records, set name equal to id fallback
          await db.execute('UPDATE sessions SET name = id WHERE name IS NULL');
        }
      },
    );
  }

  Future<void> insertSession(ApiSessionModel session) async {
    final db = await database;
    await db.insert('sessions', session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertLog(ApiLogModel log) async {
    final db = await database;
    await db.insert('logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ApiSessionModel>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('sessions', orderBy: 'startTime DESC');
    return List.generate(maps.length, (i) => ApiSessionModel.fromMap(maps[i]));
  }

  Future<List<ApiLogModel>> getLogsForSession(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'logs',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ApiLogModel.fromMap(maps[i]));
  }

  Future<int> getLogCountForSession(String sessionId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM logs WHERE sessionId = ?',
      [sessionId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('logs');
    await db.delete('sessions');
  }

  Future<void> clearSession(String sessionId) async {
    final db = await database;
    await db.delete('logs', where: 'sessionId = ?', whereArgs: [sessionId]);
    await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<void> updateSessionName(String sessionId, String newName) async {
    final db = await database;
    await db.update(
      'sessions',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }
}
