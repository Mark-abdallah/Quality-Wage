import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../models/entry.dart';

class ImportResult {
  final List<Entry> entries;
  final List<String> projects;
  final List<String> technicians;
  const ImportResult({
    required this.entries,
    required this.projects,
    required this.technicians,
  });
}

class ExcelService {
  static const sData = 'Data entry';
  static const sTech = 'Tech Report';
  static const sProject = 'Project Report';
  static const sDataBase = 'Data Base';

  /// Builds an .xlsx file matching the original workbook layout and returns
  /// the saved file path (in the app documents / temp directory).
  static Future<String> export({
    required List<Entry> entries,
    required List<String> projects,
    required List<String> technicians,
  }) async {
    final excel = Excel.createExcel();
    // Excel.createExcel() adds a default 'Sheet1'; remove it later.

    _buildDataEntry(excel, entries);
    _buildTechReport(excel, entries, technicians);
    _buildProjectReport(excel, entries, projects);
    _buildDataBase(excel, projects, technicians);

    // Remove the auto-created default sheet if present.
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    excel.setDefaultSheet(sData);

    final bytes = excel.encode();
    final dir = await _outputDir();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/Quality_Attendance_$stamp.xlsx');
    await file.writeAsBytes(bytes ?? <int>[], flush: true);
    return file.path;
  }

  static void _buildDataEntry(Excel excel, List<Entry> entries) {
    final sheet = excel[sData];
    sheet.appendRow(<CellValue?>[
      TextCellValue('Date'),
      TextCellValue('Project Name'),
      TextCellValue('Technician Name'),
      TextCellValue('Salary'),
      TextCellValue('Down payment'),
      TextCellValue('Rest'),
    ]);
    for (final e in entries) {
      sheet.appendRow(<CellValue?>[
        _dateCell(e.date),
        TextCellValue(e.project),
        TextCellValue(e.technician),
        DoubleCellValue(e.salary),
        DoubleCellValue(e.downPayment),
        DoubleCellValue(e.rest),
      ]);
    }
  }

  static void _buildTechReport(
      Excel excel, List<Entry> entries, List<String> technicians) {
    final sheet = excel[sTech];
    sheet.appendRow(<CellValue?>[
      TextCellValue('Technician Name'),
      TextCellValue('Total'),
      TextCellValue('Rest'),
    ]);
    for (final t in technicians) {
      double total = 0;
      double rest = 0;
      for (final e in entries) {
        if (e.technician == t) {
          total += e.salary;
          rest += e.rest;
        }
      }
      sheet.appendRow(<CellValue?>[
        TextCellValue(t),
        DoubleCellValue(total),
        DoubleCellValue(rest),
      ]);
    }
  }

  static void _buildProjectReport(
      Excel excel, List<Entry> entries, List<String> projects) {
    final sheet = excel[sProject];
    sheet.appendRow(<CellValue?>[
      TextCellValue('Project Name'),
      TextCellValue('Total'),
    ]);
    for (final pName in projects) {
      double total = 0;
      for (final e in entries) {
        if (e.project == pName) total += e.salary;
      }
      sheet.appendRow(<CellValue?>[
        TextCellValue(pName),
        DoubleCellValue(total),
      ]);
    }
  }

  static void _buildDataBase(
      Excel excel, List<String> projects, List<String> technicians) {
    final sheet = excel[sDataBase];
    sheet.appendRow(<CellValue?>[
      TextCellValue('Project Name'),
      TextCellValue('Technician Name'),
    ]);
    final rows = projects.length > technicians.length
        ? projects.length
        : technicians.length;
    for (var i = 0; i < rows; i++) {
      sheet.appendRow(<CellValue?>[
        TextCellValue(i < projects.length ? projects[i] : ''),
        TextCellValue(i < technicians.length ? technicians[i] : ''),
      ]);
    }
  }

  /// Parses an .xlsx file into entries + lists.
  static ImportResult import(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);

    final entries = <Entry>[];
    final projects = <String>{};
    final technicians = <String>{};

    // Data entry sheet (case-insensitive lookup).
    final dataSheet = _findSheet(excel, sData);
    if (dataSheet != null) {
      final rows = dataSheet.rows;
      for (var i = 1; i < rows.length; i++) {
        final r = rows[i];
        if (r.isEmpty) continue;
        final date = _cellDate(_at(r, 0));
        final project = _cellString(_at(r, 1));
        final technician = _cellString(_at(r, 2));
        final salary = _cellDouble(_at(r, 3));
        final down = _cellDouble(_at(r, 4));
        if (date.isEmpty && project.isEmpty && technician.isEmpty) continue;
        entries.add(Entry(
          date: date.isEmpty ? _todayIso() : date,
          project: project,
          technician: technician,
          salary: salary,
          downPayment: down,
        ));
        if (project.isNotEmpty) projects.add(project);
        if (technician.isNotEmpty) technicians.add(technician);
      }
    }

    // Data Base sheet for explicit lists.
    final dbSheet = _findSheet(excel, sDataBase);
    if (dbSheet != null) {
      final rows = dbSheet.rows;
      for (var i = 1; i < rows.length; i++) {
        final r = rows[i];
        final proj = _cellString(_at(r, 0));
        final tech = _cellString(_at(r, 1));
        if (proj.isNotEmpty) projects.add(proj);
        if (tech.isNotEmpty) technicians.add(tech);
      }
    }

    return ImportResult(
      entries: entries,
      projects: projects.toList(),
      technicians: technicians.toList(),
    );
  }

  // ---------- helpers ----------
  static Future<Directory> _outputDir() async {
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) return ext;
    } catch (_) {}
    return getApplicationDocumentsDirectory();
  }

  static Sheet? _findSheet(Excel excel, String name) {
    for (final key in excel.tables.keys) {
      if (key.trim().toLowerCase() == name.toLowerCase()) {
        return excel.tables[key] as Sheet?;
      }
    }
    return null;
  }

  static CellValue? _at(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return null;
    return row[index]?.value;
  }

  static DateCellValue _dateCell(String iso) {
    final parts = iso.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]) ?? DateTime.now().year;
      final m = int.tryParse(parts[1]) ?? 1;
      final d = int.tryParse(parts[2]) ?? 1;
      return DateCellValue(year: y, month: m, day: d);
    }
    final now = DateTime.now();
    return DateCellValue(year: now.year, month: now.month, day: now.day);
  }

  static String _cellString(CellValue? v) {
    if (v == null) return '';
    if (v is TextCellValue) return v.value.toString().trim();
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return _trimNum(v.value);
    return v.toString().trim();
  }

  static double _cellDouble(CellValue? v) {
    if (v == null) return 0;
    if (v is IntCellValue) return v.value.toDouble();
    if (v is DoubleCellValue) return v.value;
    if (v is TextCellValue) {
      return double.tryParse(v.value.toString().trim()) ?? 0;
    }
    return double.tryParse(v.toString().trim()) ?? 0;
  }

  static String _cellDate(CellValue? v) {
    if (v == null) return '';
    if (v is DateCellValue) {
      return _iso(v.year, v.month, v.day);
    }
    if (v is DateTimeCellValue) {
      return _iso(v.year, v.month, v.day);
    }
    if (v is IntCellValue) {
      return _fromSerial(v.value.toDouble());
    }
    if (v is DoubleCellValue) {
      return _fromSerial(v.value);
    }
    final s = _cellString(v);
    // Try to normalise a textual date.
    final parsed = DateTime.tryParse(s);
    if (parsed != null) {
      return _iso(parsed.year, parsed.month, parsed.day);
    }
    return s;
  }

  static String _fromSerial(double serial) {
    // Excel serial date (1900 date system).
    final epoch = DateTime(1899, 12, 30);
    final date = epoch.add(Duration(days: serial.round()));
    return _iso(date.year, date.month, date.day);
  }

  static String _iso(int y, int m, int d) =>
      '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

  static String _todayIso() {
    final n = DateTime.now();
    return _iso(n.year, n.month, n.day);
  }

  static String _trimNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
