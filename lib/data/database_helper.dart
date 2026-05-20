import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/action_log.dart';
import '../models/down_cell.dart';
import '../models/down_site.dart';
import '../models/site_record.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static const _databaseName = 'nokia_fm_tracker.db';
  static const _databaseVersion = 1;

  Database? _database;
  final Map<String, Map<String, Object?>> _webSites = {};
  final Map<String, Map<String, Object?>> _webDownSites = {};
  final Map<String, Map<String, Object?>> _webDownCells = {};
  final List<Map<String, Object?>> _webActions = [];
  int _webDownSiteId = 1;
  int _webDownCellId = 1;
  int _webActionId = 1;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not available in the web preview.');
    }
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _create,
    );
    return _database!;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sites (
        site_name TEXT PRIMARY KEY,
        governorate TEXT,
        lat REAL,
        long REAL,
        site_type TEXT,
        power_type TEXT,
        transmission TEXT,
        num_sectors INTEGER,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE down_sites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        node TEXT NOT NULL,
        tt_number TEXT NOT NULL UNIQUE,
        governorate TEXT NOT NULL,
        first_occ TEXT NOT NULL,
        outage_cat TEXT,
        alert_group TEXT NOT NULL,
        severity INTEGER NOT NULL,
        icd_status TEXT NOT NULL,
        handling_comment TEXT,
        imported_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE down_cells (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        node TEXT NOT NULL,
        tt_number TEXT NOT NULL UNIQUE,
        governorate TEXT NOT NULL,
        first_occ TEXT NOT NULL,
        cell_number TEXT,
        alert_group TEXT NOT NULL,
        severity INTEGER NOT NULL,
        icd_status TEXT NOT NULL,
        imported_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tt_number TEXT NOT NULL,
        tt_type TEXT NOT NULL CHECK(tt_type IN ('down_site', 'down_cell')),
        engineer_name TEXT NOT NULL,
        action_text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_sites_name ON sites(site_name)');
    await db.execute(
      'CREATE INDEX idx_down_sites_gov ON down_sites(governorate)',
    );
    await db.execute(
      'CREATE INDEX idx_down_cells_gov ON down_cells(governorate)',
    );
    await db.execute(
      'CREATE INDEX idx_actions_tt ON actions(tt_number, tt_type)',
    );
  }

  Future<int> upsertSite(SiteRecord site) async {
    if (kIsWeb) {
      _webSites[site.siteName.toUpperCase()] = site.toMap();
      return 1;
    }
    final db = await database;
    return db.insert(
      'sites',
      site.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> upsertDownSite(Map<String, Object?> row) async {
    if (kIsWeb) {
      final ttNumber = row['tt_number']?.toString() ?? '';
      if (ttNumber.isEmpty) return 0;
      final existing = _webDownSites[ttNumber];
      _webDownSites[ttNumber] = {
        ...row,
        'id': existing?['id'] ?? _webDownSiteId++,
      };
      return 1;
    }
    final db = await database;
    return db.insert(
      'down_sites',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> upsertDownCell(Map<String, Object?> row) async {
    if (kIsWeb) {
      final ttNumber = row['tt_number']?.toString() ?? '';
      if (ttNumber.isEmpty) return 0;
      final existing = _webDownCells[ttNumber];
      _webDownCells[ttNumber] = {
        ...row,
        'id': existing?['id'] ?? _webDownCellId++,
      };
      return 1;
    }
    final db = await database;
    return db.insert(
      'down_cells',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> governorateForNode(String node) async {
    if (kIsWeb) {
      final row = _webSites[node.trim().toUpperCase()];
      final governorate = row?['governorate']?.toString().trim() ?? '';
      return governorate.isEmpty ? 'Unknown' : governorate;
    }
    final db = await database;
    final normalized = node.trim();
    final rows = await db.query(
      'sites',
      columns: ['governorate'],
      where: 'UPPER(site_name) = UPPER(?)',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) return 'Unknown';
    final governorate = rows.first['governorate']?.toString().trim() ?? '';
    return governorate.isEmpty ? 'Unknown' : governorate;
  }

  Future<List<DownSite>> getDownSites({
    required Set<String> governorates,
    String search = '',
    Set<String> outageCategories = const {},
    int? severity,
    int? durationHours,
  }) async {
    if (kIsWeb) {
      final actions = await _actionsByTicket('down_site');
      return _filterWebRows(
            rows: _webDownSites.values,
            governorates: governorates,
            search: search,
            categoryColumn: 'outage_cat',
            categories: outageCategories,
            severity: severity,
            durationHours: durationHours,
          )
          .map(
            (row) => DownSite.fromMap(
              row,
              actions: actions[row['tt_number']?.toString()] ?? const [],
            ),
          )
          .toList();
    }
    final db = await database;
    final query = _buildTicketQuery(
      table: 'down_sites',
      governorates: governorates,
      search: search,
      categoryColumn: 'outage_cat',
      categories: outageCategories,
      severity: severity,
      durationHours: durationHours,
    );
    final rows = await db.query(
      'down_sites',
      where: query.where,
      whereArgs: query.args,
      orderBy: 'first_occ ASC',
    );
    final actions = await _actionsByTicket('down_site');
    return rows
        .map(
          (row) => DownSite.fromMap(
            row,
            actions: actions[row['tt_number']?.toString()] ?? const [],
          ),
        )
        .toList();
  }

  Future<List<DownCell>> getDownCells({
    required Set<String> governorates,
    String search = '',
    Set<String> alertGroups = const {},
    int? severity,
    int? durationHours,
  }) async {
    if (kIsWeb) {
      final actions = await _actionsByTicket('down_cell');
      return _filterWebRows(
            rows: _webDownCells.values,
            governorates: governorates,
            search: search,
            categoryColumn: 'alert_group',
            categories: alertGroups,
            severity: severity,
            durationHours: durationHours,
          )
          .map(
            (row) => DownCell.fromMap(
              row,
              actions: actions[row['tt_number']?.toString()] ?? const [],
            ),
          )
          .toList();
    }
    final db = await database;
    final query = _buildTicketQuery(
      table: 'down_cells',
      governorates: governorates,
      search: search,
      categoryColumn: 'alert_group',
      categories: alertGroups,
      severity: severity,
      durationHours: durationHours,
    );
    final rows = await db.query(
      'down_cells',
      where: query.where,
      whereArgs: query.args,
      orderBy: 'first_occ ASC',
    );
    final actions = await _actionsByTicket('down_cell');
    return rows
        .map(
          (row) => DownCell.fromMap(
            row,
            actions: actions[row['tt_number']?.toString()] ?? const [],
          ),
        )
        .toList();
  }

  _SqlQuery _buildTicketQuery({
    required String table,
    required Set<String> governorates,
    required String search,
    required String categoryColumn,
    required Set<String> categories,
    int? severity,
    int? durationHours,
  }) {
    final clauses = <String>[];
    final args = <Object?>[];

    if (governorates.isNotEmpty) {
      clauses.add(
        'governorate IN (${List.filled(governorates.length, '?').join(',')})',
      );
      args.addAll(governorates);
    }

    final term = search.trim();
    if (term.isNotEmpty) {
      clauses.add('(node LIKE ? OR tt_number LIKE ?)');
      args.addAll(['%$term%', '%$term%']);
    }

    if (categories.isNotEmpty) {
      clauses.add(
        '$categoryColumn IN (${List.filled(categories.length, '?').join(',')})',
      );
      args.addAll(categories);
    }

    if (severity != null) {
      clauses.add('severity = ?');
      args.add(severity);
    }

    if (durationHours != null) {
      clauses.add('first_occ <= ?');
      args.add(
        DateTime.now()
            .subtract(Duration(hours: durationHours))
            .toIso8601String(),
      );
    }

    return _SqlQuery(clauses.isEmpty ? null : clauses.join(' AND '), args);
  }

  Future<Map<String, List<ActionLog>>> _actionsByTicket(String ttType) async {
    if (kIsWeb) {
      final rows =
          _webActions
              .where((row) => row['tt_type']?.toString() == ttType)
              .toList()
            ..sort(
              (a, b) => (b['created_at'] ?? '').toString().compareTo(
                (a['created_at'] ?? '').toString(),
              ),
            );
      final grouped = <String, List<ActionLog>>{};
      for (final row in rows) {
        final action = ActionLog.fromMap(row);
        grouped.putIfAbsent(action.ttNumber, () => []).add(action);
      }
      return grouped;
    }
    final db = await database;
    final rows = await db.query(
      'actions',
      where: 'tt_type = ?',
      whereArgs: [ttType],
      orderBy: 'created_at DESC',
    );
    final grouped = <String, List<ActionLog>>{};
    for (final row in rows) {
      final action = ActionLog.fromMap(row);
      grouped.putIfAbsent(action.ttNumber, () => []).add(action);
    }
    return grouped;
  }

  Future<int> addAction(ActionLog action) async {
    if (kIsWeb) {
      _webActions.add(action.toMap()..['id'] = _webActionId++);
      return 1;
    }
    final db = await database;
    return db.insert('actions', action.toMap()..remove('id'));
  }

  Future<int> updateDownSiteHandlingComment({
    required String ttNumber,
    required String handlingComment,
  }) async {
    if (kIsWeb) {
      final existing = _webDownSites[ttNumber];
      if (existing == null) return 0;
      _webDownSites[ttNumber] = {
        ...existing,
        'handling_comment': handlingComment,
      };
      return 1;
    }
    final db = await database;
    return db.update(
      'down_sites',
      {'handling_comment': handlingComment},
      where: 'tt_number = ?',
      whereArgs: [ttNumber],
    );
  }

  Future<List<DownSite>> getDownSitesWithActions() async {
    final actions = await _actionsByTicket('down_site');
    if (kIsWeb) {
      final rows =
          _webDownSites.values
              .where(
                (row) =>
                    actions.containsKey(row['tt_number']?.toString()) ||
                    (row['handling_comment']?.toString().trim().isNotEmpty ??
                        false),
              )
              .toList()
            ..sort(
              (a, b) => (a['first_occ'] ?? '').toString().compareTo(
                (b['first_occ'] ?? '').toString(),
              ),
            );
      return rows
          .map(
            (row) => DownSite.fromMap(
              row,
              actions: actions[row['tt_number']?.toString()] ?? const [],
            ),
          )
          .toList();
    }

    final db = await database;
    final rows = await db.rawQuery('''
      SELECT ds.*
      FROM down_sites ds
      WHERE EXISTS (
        SELECT 1
        FROM actions a
        WHERE a.tt_number = ds.tt_number AND a.tt_type = 'down_site'
      )
      OR TRIM(COALESCE(ds.handling_comment, '')) != ''
      ORDER BY ds.first_occ ASC
    ''');
    return rows
        .map(
          (row) => DownSite.fromMap(
            row,
            actions: actions[row['tt_number']?.toString()] ?? const [],
          ),
        )
        .toList();
  }

  Future<List<DownCell>> getDownCellsWithActions() async {
    final actions = await _actionsByTicket('down_cell');
    if (kIsWeb) {
      final rows =
          _webDownCells.values
              .where((row) => actions.containsKey(row['tt_number']?.toString()))
              .toList()
            ..sort(
              (a, b) => (a['first_occ'] ?? '').toString().compareTo(
                (b['first_occ'] ?? '').toString(),
              ),
            );
      return rows
          .map(
            (row) => DownCell.fromMap(
              row,
              actions: actions[row['tt_number']?.toString()] ?? const [],
            ),
          )
          .toList();
    }

    final db = await database;
    final rows = await db.rawQuery('''
      SELECT dc.*
      FROM down_cells dc
      WHERE EXISTS (
        SELECT 1
        FROM actions a
        WHERE a.tt_number = dc.tt_number AND a.tt_type = 'down_cell'
      )
      ORDER BY dc.first_occ ASC
    ''');
    return rows
        .map(
          (row) => DownCell.fromMap(
            row,
            actions: actions[row['tt_number']?.toString()] ?? const [],
          ),
        )
        .toList();
  }

  Future<List<String>> distinctValues(String table, String column) async {
    if (kIsWeb) {
      final rows = switch (table) {
        'down_sites' => _webDownSites.values,
        'down_cells' => _webDownCells.values,
        'sites' => _webSites.values,
        _ => const Iterable<Map<String, Object?>>.empty(),
      };
      final values =
          rows
              .map((row) => row[column]?.toString().trim() ?? '')
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      return values;
    }
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT $column AS value FROM $table '
      'WHERE $column IS NOT NULL AND TRIM($column) != "" ORDER BY $column',
    );
    return rows.map((row) => row['value'].toString()).toList();
  }

  Future<List<Map<String, Object?>>> getGovernorateSiteCounts() async {
    if (kIsWeb) {
      final counts = <String, int>{};
      for (final site in _webSites.values) {
        final gov = site['governorate']?.toString().trim() ?? 'Unknown';
        if (gov.isNotEmpty) {
          counts[gov] = (counts[gov] ?? 0) + 1;
        }
      }
      if (counts.isEmpty) {
        final allGovs = <String>{};
        for (final ds in _webDownSites.values) {
          final gov = ds['governorate']?.toString().trim() ?? '';
          if (gov.isNotEmpty && gov != 'Unknown') allGovs.add(gov);
        }
        for (final dc in _webDownCells.values) {
          final gov = dc['governorate']?.toString().trim() ?? '';
          if (gov.isNotEmpty && gov != 'Unknown') allGovs.add(gov);
        }
        if (allGovs.isEmpty) {
          return [
            {'governorate': 'Minya', 'site_count': 179},
            {'governorate': 'Asyut', 'site_count': 164},
            {'governorate': 'Sohag', 'site_count': 145},
            {'governorate': 'Aswan', 'site_count': 137},
            {'governorate': 'Qena', 'site_count': 118},
            {'governorate': 'Beni Suef', 'site_count': 103},
            {'governorate': 'Luxor', 'site_count': 82},
            {'governorate': 'Faiyum', 'site_count': 71},
            {'governorate': 'New Valley', 'site_count': 26},
          ];
        }
        return allGovs
            .map((gov) => {'governorate': gov, 'site_count': 0})
            .toList();
      }
      return counts.entries
          .map((e) => {'governorate': e.key, 'site_count': e.value})
          .toList()
        ..sort(
          (a, b) => (b['site_count'] as int).compareTo(a['site_count'] as int),
        );
    }

    final db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT governorate, COUNT(*) AS site_count 
      FROM sites 
      WHERE governorate IS NOT NULL AND TRIM(governorate) != "" AND UPPER(governorate) != "UNKNOWN"
      GROUP BY governorate 
      ORDER BY site_count DESC
    ''');

    if (rows.isEmpty) {
      final List<Map<String, Object?>> dsGovs = await db.rawQuery('''
        SELECT DISTINCT governorate FROM down_sites 
        WHERE governorate IS NOT NULL AND TRIM(governorate) != "" AND UPPER(governorate) != "UNKNOWN"
      ''');
      final List<Map<String, Object?>> dcGovs = await db.rawQuery('''
        SELECT DISTINCT governorate FROM down_cells 
        WHERE governorate IS NOT NULL AND TRIM(governorate) != "" AND UPPER(governorate) != "UNKNOWN"
      ''');
      final allGovs = <String>{};
      for (final r in dsGovs) {
        allGovs.add(r['governorate'].toString());
      }
      for (final r in dcGovs) {
        allGovs.add(r['governorate'].toString());
      }
      if (allGovs.isEmpty) {
        return [
          {'governorate': 'Minya', 'site_count': 179},
          {'governorate': 'Asyut', 'site_count': 164},
          {'governorate': 'Sohag', 'site_count': 145},
          {'governorate': 'Aswan', 'site_count': 137},
          {'governorate': 'Qena', 'site_count': 118},
          {'governorate': 'Beni Suef', 'site_count': 103},
          {'governorate': 'Luxor', 'site_count': 82},
          {'governorate': 'Faiyum', 'site_count': 71},
          {'governorate': 'New Valley', 'site_count': 26},
        ];
      }
      return allGovs
          .map((gov) => {'governorate': gov, 'site_count': 0})
          .toList();
    }
    return rows;
  }

  Future<void> updateUnknownGovernorates() async {
    if (kIsWeb) {
      for (final ds in _webDownSites.values) {
        if (ds['governorate'] == 'Unknown') {
          final node = ds['node']?.toString() ?? '';
          ds['governorate'] = await governorateForNode(node);
        }
      }
      for (final dc in _webDownCells.values) {
        if (dc['governorate'] == 'Unknown') {
          final node = dc['node']?.toString() ?? '';
          dc['governorate'] = await governorateForNode(node);
        }
      }
      return;
    }
    final db = await database;
    final List<Map<String, Object?>> dsRows = await db.query(
      'down_sites',
      columns: ['id', 'node'],
      where: 'governorate = ? OR governorate IS NULL',
      whereArgs: ['Unknown'],
    );
    for (final row in dsRows) {
      final id = row['id'] as int;
      final node = row['node'] as String;
      final gov = await governorateForNode(node);
      if (gov != 'Unknown') {
        await db.update(
          'down_sites',
          {'governorate': gov},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }

    final List<Map<String, Object?>> dcRows = await db.query(
      'down_cells',
      columns: ['id', 'node'],
      where: 'governorate = ? OR governorate IS NULL',
      whereArgs: ['Unknown'],
    );
    for (final row in dcRows) {
      final id = row['id'] as int;
      final node = row['node'] as String;
      final gov = await governorateForNode(node);
      if (gov != 'Unknown') {
        await db.update(
          'down_cells',
          {'governorate': gov},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }

  Future<int> count(String table) async {
    if (kIsWeb) {
      return switch (table) {
        'sites' => _webSites.length,
        'down_sites' => _webDownSites.length,
        'down_cells' => _webDownCells.length,
        'actions' => _webActions.length,
        _ => 0,
      };
    }
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> downSitesForGovernorates(Set<String> governorates) async {
    if (governorates.isEmpty) return 0;
    if (kIsWeb) {
      return _webDownSites.values
          .where((row) => governorates.contains(row['governorate']))
          .length;
    }
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM down_sites '
      'WHERE governorate IN (${List.filled(governorates.length, '?').join(',')})',
      governorates.toList(),
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> downCellsForGovernorates(Set<String> governorates) async {
    if (governorates.isEmpty) return 0;
    if (kIsWeb) {
      return _webDownCells.values
          .where((row) => governorates.contains(row['governorate']))
          .length;
    }
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM down_cells '
      'WHERE governorate IN (${List.filled(governorates.length, '?').join(',')})',
      governorates.toList(),
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> govBlockedCount() async {
    if (kIsWeb) {
      return _webDownSites.values
          .where(
            (row) => (row['outage_cat'] ?? '')
                .toString()
                .toLowerCase()
                .contains('gov'),
          )
          .length;
    }
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM down_sites WHERE outage_cat LIKE ?',
      ['%GOV%'],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> uniqueSitesAffected(Set<String> governorates) async {
    if (governorates.isEmpty) return 0;
    if (kIsWeb) {
      return _webDownCells.values
          .where((row) => governorates.contains(row['governorate']))
          .map((row) => row['node']?.toString() ?? '')
          .where((node) => node.isNotEmpty)
          .toSet()
          .length;
    }
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(DISTINCT node) AS count FROM down_cells '
      'WHERE governorate IN (${List.filled(governorates.length, '?').join(',')})',
      governorates.toList(),
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  List<Map<String, Object?>> _filterWebRows({
    required Iterable<Map<String, Object?>> rows,
    required Set<String> governorates,
    required String search,
    required String categoryColumn,
    required Set<String> categories,
    int? severity,
    int? durationHours,
  }) {
    final term = search.trim().toLowerCase();
    final threshold = durationHours == null
        ? null
        : DateTime.now().subtract(Duration(hours: durationHours));
    final filtered =
        rows.where((row) {
          if (governorates.isNotEmpty &&
              !governorates.contains(row['governorate']?.toString())) {
            return false;
          }
          if (term.isNotEmpty) {
            final node = row['node']?.toString().toLowerCase() ?? '';
            final ttNumber = row['tt_number']?.toString().toLowerCase() ?? '';
            if (!node.contains(term) && !ttNumber.contains(term)) return false;
          }
          if (categories.isNotEmpty &&
              !categories.contains(row[categoryColumn]?.toString())) {
            return false;
          }
          if (severity != null &&
              int.tryParse(row['severity']?.toString() ?? '') != severity) {
            return false;
          }
          if (threshold != null) {
            final firstOcc = DateTime.tryParse(
              row['first_occ']?.toString() ?? '',
            );
            if (firstOcc == null || firstOcc.isAfter(threshold)) return false;
          }
          return true;
        }).toList()..sort(
          (a, b) => (a['first_occ'] ?? '').toString().compareTo(
            (b['first_occ'] ?? '').toString(),
          ),
        );
    return filtered;
  }
}

class _SqlQuery {
  const _SqlQuery(this.where, this.args);

  final String? where;
  final List<Object?> args;
}
