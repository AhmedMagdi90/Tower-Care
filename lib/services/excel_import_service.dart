import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import '../models/site_record.dart';

class ImportResult {
  const ImportResult({required this.downSites, required this.downCells});

  final int downSites;
  final int downCells;
}

class ExcelImportService {
  ExcelImportService(this._db);

  final DatabaseHelper _db;

  Future<int> importSiteList(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.firstOrNull;
    if (sheet == null) return 0;

    final rows = sheet.rows;
    if (rows.length < 2) return 0;

    final headers = _headers(rows.first);
    var inserted = 0;
    for (final row in rows.skip(1)) {
      final siteName = _cellText(row, _index(headers, ['SiteName']));
      if (siteName.isEmpty) continue;

      await _db.upsertSite(
        SiteRecord(
          siteName: siteName,
          governorate: _cellText(row, _index(headers, ['Governorate'])),
          lat: _cellDouble(row, _index(headers, ['Lat', 'Latitude'])),
          long: _cellDouble(row, _index(headers, ['Long', 'Longitude'])),
          siteType: _emptyToNull(_cellText(row, _index(headers, ['SiteType']))),
          powerType: _emptyToNull(
            _cellText(row, _index(headers, ['PowerType'])),
          ),
          transmission: _emptyToNull(
            _cellText(
              row,
              _index(headers, ['TransmissionType', 'Transmission']),
            ),
          ),
          numSectors: _cellInt(
            row,
            _index(headers, ['NumberOfSectors', 'NumSectors']),
          ),
          address: _emptyToNull(_cellText(row, _index(headers, ['Address']))),
        ),
      );
      inserted++;
    }
    return inserted;
  }

  Future<ImportResult> importNokiaFmReport(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    var downCells = 0;
    var downSites = 0;

    if (excel.tables.isNotEmpty) {
      downCells = await _importDownCells(excel.tables.values.elementAt(0));
    }
    if (excel.tables.length > 1) {
      downSites = await _importDownSites(excel.tables.values.elementAt(1));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_import', DateTime.now().toIso8601String());
    return ImportResult(downSites: downSites, downCells: downCells);
  }

  Future<int> _importDownSites(Sheet sheet) async {
    final rows = sheet.rows;
    if (rows.length < 2) return 0;
    final headers = _headers(rows.first);
    final importedAt = DateTime.now().toIso8601String();
    var count = 0;

    for (final row in rows.skip(1)) {
      final node = _cellText(row, _index(headers, ['Node']));
      final ttNumber = _cellText(
        row,
        _index(headers, ['Ttnumber', 'TTNumber']),
      );
      if (node.isEmpty || ttNumber.isEmpty) continue;

      await _db.upsertDownSite({
        'node': node,
        'tt_number': ttNumber,
        'governorate': await _db.governorateForNode(node),
        'first_occ': _cellDateTime(
          row,
          _index(headers, ['Firstoccurrence', 'FirstOccurrence']),
        ).toIso8601String(),
        'outage_cat': _emptyToNull(
          _cellText(row, _index(headers, ['Outagecategory', 'OutageCategory'])),
        ),
        'alert_group': _cellText(
          row,
          _index(headers, ['Alertgroup', 'AlertGroup']),
        ),
        'severity': _cellInt(row, _index(headers, ['Severity'])) ?? 0,
        'icd_status': _cellText(
          row,
          _index(headers, ['Icdstatus', 'IcdStatus']),
        ),
        'handling_comment': _emptyToNull(
          _cellText(
            row,
            _index(headers, ['Handlingcomment', 'HandlingComment']),
          ),
        ),
        'imported_at': importedAt,
      });
      count++;
    }
    return count;
  }

  Future<int> _importDownCells(Sheet sheet) async {
    final rows = sheet.rows;
    if (rows.length < 2) return 0;
    final headers = _headers(rows.first);
    final importedAt = DateTime.now().toIso8601String();
    var count = 0;

    for (final row in rows.skip(1)) {
      final node = _cellText(row, _index(headers, ['Node']));
      final ttNumber = _cellText(
        row,
        _index(headers, ['Ttnumber', 'TTNumber']),
      );
      if (node.isEmpty || ttNumber.isEmpty) continue;

      await _db.upsertDownCell({
        'node': node,
        'tt_number': ttNumber,
        'governorate': await _db.governorateForNode(node),
        'first_occ': _cellDateTime(
          row,
          _index(headers, ['Firstoccurrence', 'FirstOccurrence']),
        ).toIso8601String(),
        'cell_number': _emptyToNull(
          _cellText(row, _index(headers, ['Cellnumber', 'CellNumber'])),
        ),
        'alert_group': _cellText(
          row,
          _index(headers, ['Alertgroup', 'AlertGroup']),
        ),
        'severity': _cellInt(row, _index(headers, ['Severity'])) ?? 0,
        'icd_status': _cellText(
          row,
          _index(headers, ['Icdstatus', 'IcdStatus']),
        ),
        'imported_at': importedAt,
      });
      count++;
    }
    return count;
  }

  Map<String, int> _headers(List<Data?> row) {
    return {
      for (var i = 0; i < row.length; i++)
        if (_valueText(row[i]?.value).isNotEmpty)
          _normalizeHeader(_valueText(row[i]?.value)): i,
    };
  }

  int _index(Map<String, int> headers, List<String> aliases) {
    for (final alias in aliases) {
      final index = headers[_normalizeHeader(alias)];
      if (index != null) return index;
    }
    return -1;
  }

  String _cellText(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return _valueText(row[index]?.value).trim();
  }

  int? _cellInt(List<Data?> row, int index) {
    final text = _cellText(row, index);
    return int.tryParse(text) ?? double.tryParse(text)?.round();
  }

  double? _cellDouble(List<Data?> row, int index) {
    final text = _cellText(row, index);
    return double.tryParse(text);
  }

  DateTime _cellDateTime(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return DateTime.now();
    final value = row[index]?.value;
    if (value is DateTimeCellValue) return value.asDateTimeLocal();
    if (value is DateCellValue) return value.asDateTimeLocal();
    if (value is IntCellValue) return _excelSerialDate(value.value);
    if (value is DoubleCellValue) return _excelSerialDate(value.value);

    final text = _valueText(value).trim();
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;

    for (final pattern in _datePatterns) {
      try {
        return DateFormat(pattern).parseLoose(text);
      } on FormatException {
        continue;
      }
    }
    return DateTime.now();
  }

  DateTime _excelSerialDate(num serial) {
    return DateTime(1899, 12, 30).add(
      Duration(milliseconds: (serial * Duration.millisecondsPerDay).round()),
    );
  }

  String _valueText(CellValue? value) {
    return switch (value) {
      null => '',
      TextCellValue() => value.value.toString(),
      DateTimeCellValue() => value.asDateTimeLocal().toIso8601String(),
      DateCellValue() => value.asDateTimeLocal().toIso8601String(),
      TimeCellValue() => value.toString(),
      FormulaCellValue() => value.formula,
      IntCellValue() => value.value.toString(),
      DoubleCellValue() => value.value.toString(),
      BoolCellValue() => value.value.toString(),
    };
  }

  String _normalizeHeader(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

const _datePatterns = [
  'M/d/yyyy H:mm:ss',
  'M/d/yyyy h:mm:ss a',
  'dd/MM/yyyy HH:mm:ss',
  'dd-MM-yyyy HH:mm:ss',
  'yyyy-MM-dd HH:mm:ss',
  'dd MMM yyyy HH:mm:ss',
  'dd-MMM-yyyy HH:mm:ss',
];

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
