import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/down_cell.dart';
import '../models/down_site.dart';
import 'ticket_formatters.dart';

class ExcelExportService {
  Future<String> exportDownSites(List<DownSite> sites) async {
    final excel = Excel.createExcel();
    const sheetName = 'Down Sites';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheet.appendRow(
      _textRow([
        'Node',
        'TT Number',
        'TT Type',
        'Governorate',
        'First Occurrence',
        'Duration',
        'Outage Category',
        'Alert Group',
        'Handling Comment',
      ]),
    );

    for (final site in sites) {
      sheet.appendRow(
        _textRow([
          site.node,
          site.ttNumber,
          'Down Site',
          site.governorate,
          shortDateTimeFormat.format(site.firstOcc),
          durationText(site.firstOcc),
          site.outageCat ?? '',
          site.alertGroup,
          site.handlingComment ?? '',
        ]),
      );
    }

    return _writeWorkbook(excel, 'down_sites');
  }

  Future<String> exportDownCells(List<DownCell> cells) async {
    final excel = Excel.createExcel();
    const sheetName = 'Down Cells';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheet.appendRow(
      _textRow([
        'Node',
        'TT Number',
        'Governorate',
        'Cell Number',
        'First Occurrence',
        'Duration',
        'Alert Group',
      ]),
    );

    for (final cell in cells) {
      sheet.appendRow(
        _textRow([
          cell.node,
          cell.ttNumber,
          cell.governorate,
          cell.cellNumber ?? '',
          shortDateTimeFormat.format(cell.firstOcc),
          durationText(cell.firstOcc),
          cell.alertGroup,
        ]),
      );
    }

    return _writeWorkbook(excel, 'down_cells');
  }

  List<CellValue?> _textRow(List<String> values) {
    return values.map<CellValue?>((value) => TextCellValue(value)).toList();
  }

  Future<String> _writeWorkbook(Excel excel, String prefix) async {
    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Excel export failed.');
    }
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${prefix}_${fileDateTimeFormat.format(DateTime.now())}.xlsx';
    final file = File(p.join(directory.path, fileName));
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
