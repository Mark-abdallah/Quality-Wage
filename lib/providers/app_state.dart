import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/entry.dart';
import '../services/excel_service.dart';

class AppState extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  Locale _locale = const Locale('ar');
  Locale get locale => _locale;

  List<Entry> _entries = [];
  List<String> _projects = [];
  List<String> _technicians = [];

  DateTime? _from;
  DateTime? _to;
  DateTime? get fromDate => _from;
  DateTime? get toDate => _to;

  List<String> get projects => _projects;
  List<String> get technicians => _technicians;

  bool _loading = true;
  bool get loading => _loading;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale') ?? 'ar';
    _locale = Locale(code);
    await refresh();
    _loading = false;
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    _locale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
    notifyListeners();
  }

  Future<void> refresh() async {
    _entries = await _db.getEntries();
    _projects = await _db.getProjects();
    _technicians = await _db.getTechnicians();
    notifyListeners();
  }

  // ---------- Filtering ----------
  void setDateRange(DateTime? from, DateTime? to) {
    _from = from;
    _to = to;
    notifyListeners();
  }

  void clearDateRange() {
    _from = null;
    _to = null;
    notifyListeners();
  }

  bool _inRange(String iso) {
    if (_from == null && _to == null) return true;
    final d = DateTime.tryParse(iso);
    if (d == null) return true;
    if (_from != null && d.isBefore(DateTime(_from!.year, _from!.month, _from!.day))) {
      return false;
    }
    if (_to != null && d.isAfter(DateTime(_to!.year, _to!.month, _to!.day, 23, 59, 59))) {
      return false;
    }
    return true;
  }

  List<Entry> get filteredEntries =>
      _entries.where((e) => _inRange(e.date)).toList();

  List<Entry> get allEntries => _entries;

  // ---------- Reports ----------
  List<TechRow> get technicianReport {
    final map = <String, TechRow>{};
    for (final t in _technicians) {
      map[t] = TechRow(name: t, total: 0, rest: 0);
    }
    for (final e in filteredEntries) {
      final row = map.putIfAbsent(
          e.technician, () => TechRow(name: e.technician, total: 0, rest: 0));
      map[e.technician] =
          row.copyWith(total: row.total + e.salary, rest: row.rest + e.rest);
    }
    final list = map.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  List<ProjectRow> get projectReport {
    final map = <String, ProjectRow>{};
    for (final p in _projects) {
      map[p] = ProjectRow(name: p, total: 0);
    }
    for (final e in filteredEntries) {
      final row =
          map.putIfAbsent(e.project, () => ProjectRow(name: e.project, total: 0));
      map[e.project] = row.copyWith(total: row.total + e.salary);
    }
    final list = map.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  double get grandTotalSalary =>
      filteredEntries.fold(0.0, (s, e) => s + e.salary);
  double get grandTotalRest => filteredEntries.fold(0.0, (s, e) => s + e.rest);

  // ---------- Entry CRUD ----------
  Future<void> addEntry(Entry e) async {
    await _db.insertEntry(e);
    await refresh();
  }

  Future<void> updateEntry(Entry e) async {
    await _db.updateEntry(e);
    await refresh();
  }

  Future<void> deleteEntry(int id) async {
    await _db.deleteEntry(id);
    await refresh();
  }

  // ---------- Lists CRUD ----------
  Future<void> addProject(String name) async {
    await _db.addProject(name.trim());
    await refresh();
  }

  Future<void> addTechnician(String name) async {
    await _db.addTechnician(name.trim());
    await refresh();
  }

  Future<void> deleteProject(String name) async {
    await _db.deleteProject(name);
    await refresh();
  }

  Future<void> deleteTechnician(String name) async {
    await _db.deleteTechnician(name);
    await refresh();
  }

  Future<void> renameProject(String oldName, String newName) async {
    await _db.renameProject(oldName, newName.trim());
    await refresh();
  }

  Future<void> renameTechnician(String oldName, String newName) async {
    await _db.renameTechnician(oldName, newName.trim());
    await refresh();
  }

  // ---------- Excel ----------
  Future<String> exportExcel() async {
    return ExcelService.export(
      entries: _entries,
      projects: _projects,
      technicians: _technicians,
    );
  }

  /// Replaces all data with the imported content.
  Future<void> importExcel(List<int> bytes) async {
    final result = ExcelService.import(bytes);
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('entries');
      await txn.delete('projects');
      await txn.delete('technicians');
      for (final p in result.projects) {
        await txn.insert('projects', {'name': p},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final t in result.technicians) {
        await txn.insert('technicians', {'name': t},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final e in result.entries) {
        await txn.insert('entries', e.toMap()..remove('id'));
      }
    });
    await refresh();
  }
}

class TechRow {
  final String name;
  final double total;
  final double rest;
  const TechRow({required this.name, required this.total, required this.rest});
  TechRow copyWith({double? total, double? rest}) =>
      TechRow(name: name, total: total ?? this.total, rest: rest ?? this.rest);
}

class ProjectRow {
  final String name;
  final double total;
  const ProjectRow({required this.name, required this.total});
  ProjectRow copyWith({double? total}) =>
      ProjectRow(name: name, total: total ?? this.total);
}
