import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/journal.dart';

class JournalDatabase {
  static final JournalDatabase instance = JournalDatabase._init();
  static Database? _database;

  JournalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('journal.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE journals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<Journal> create(Journal journal) async {
    final db = await instance.database;
    final id = await db.insert('journals', journal.toMap());
    return journal.copyWith(id: id);
  }

  Future<List<Journal>> readAll() async {
    final db = await instance.database;
    final result = await db.query('journals', orderBy: 'id DESC');
    return result.map((json) => Journal.fromMap(json)).toList();
  }

  Future<int> update(Journal journal) async {
    final db = await instance.database;
    return db.update(
      'journals',
      journal.toMap(),
      where: 'id = ?',
      whereArgs: [journal.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return db.delete('journals', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
