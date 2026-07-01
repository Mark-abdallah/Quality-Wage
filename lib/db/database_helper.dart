import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/entry.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'quality_wage.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        project TEXT NOT NULL,
        technician TEXT NOT NULL,
        salary REAL NOT NULL DEFAULT 0,
        downPayment REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE technicians (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Seed data derived from the original Quality Attendance.xlsx
    const seedProjects = [
      'جوناس',
      'بيسكو',
      '3 Pyramids',
      'النور سيتي',
      'فندق شتايجن',
      'مدرسة المنارة',
    ];
    const seedTechnicians = [
      'أيمن',
      'سامي',
      'جورج',
      'رمزي',
      'بولا',
      'عنتر',
      'مكاريوس',
      'عازر',
    ];
    final batch = db.batch();
    for (final name in seedProjects) {
      batch.insert('projects', {'name': name},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final name in seedTechnicians) {
      batch.insert('technicians', {'name': name},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // ---------- Entries ----------
  Future<List<Entry>> getEntries() async {
    final db = await database;
    final rows = await db.query('entries', orderBy: 'date DESC, id DESC');
    return rows.map(Entry.fromMap).toList();
  }

  Future<int> insertEntry(Entry e) async {
    final db = await database;
    return db.insert('entries', e.toMap()..remove('id'));
  }

  Future<int> updateEntry(Entry e) async {
    final db = await database;
    return db.update('entries', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllEntries() async {
    final db = await database;
    await db.delete('entries');
  }

  // ---------- Lists ----------
  Future<List<String>> getProjects() async {
    final db = await database;
    final rows = await db.query('projects', orderBy: 'name COLLATE NOCASE');
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<List<String>> getTechnicians() async {
    final db = await database;
    final rows = await db.query('technicians', orderBy: 'name COLLATE NOCASE');
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<void> addProject(String name) async {
    final db = await database;
    await db.insert('projects', {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> addTechnician(String name) async {
    final db = await database;
    await db.insert('technicians', {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteProject(String name) async {
    final db = await database;
    await db.delete('projects', where: 'name = ?', whereArgs: [name]);
  }

  Future<void> deleteTechnician(String name) async {
    final db = await database;
    await db.delete('technicians', where: 'name = ?', whereArgs: [name]);
  }

  Future<void> renameProject(String oldName, String newName) async {
    final db = await database;
    await db.update('projects', {'name': newName},
        where: 'name = ?', whereArgs: [oldName]);
    await db.update('entries', {'project': newName},
        where: 'project = ?', whereArgs: [oldName]);
  }

  Future<void> renameTechnician(String oldName, String newName) async {
    final db = await database;
    await db.update('technicians', {'name': newName},
        where: 'name = ?', whereArgs: [oldName]);
    await db.update('entries', {'technician': newName},
        where: 'technician = ?', whereArgs: [oldName]);
  }
}
