import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import '../models/action_log.dart';
import '../models/down_cell.dart';
import '../models/down_site.dart';
import '../services/excel_import_service.dart';
import '../services/ticket_formatters.dart';

class TrackerProvider extends ChangeNotifier {
  TrackerProvider({DatabaseHelper? database, ExcelImportService? importService})
    : _database = database ?? DatabaseHelper.instance,
      _importService =
          importService ??
          ExcelImportService(database ?? DatabaseHelper.instance);

  final DatabaseHelper _database;
  final ExcelImportService _importService;

  bool isBusy = false;
  String? lastImport;
  String? errorMessage;

  List<DownSite> downSites = [];
  List<DownCell> downCells = [];
  List<DownSite> actionDownSites = [];
  List<DownCell> actionDownCells = [];
  List<String> outageCategories = [];
  List<String> alertGroups = [];

  Set<String> downSiteGovernorates = {...trackedGovernorates};
  Set<String> downCellGovernorates = {...trackedGovernorates};
  String downSiteSearch = '';
  String downCellSearch = '';
  Set<String> selectedOutageCategories = {};
  Set<String> selectedAlertGroups = {};
  int? downSiteSeverity;
  int? downCellSeverity;
  int? downSiteDurationHours;
  int? downCellDurationHours;

  int sitesLoaded = 0;
  int downSitesStored = 0;
  int downCellsStored = 0;
  int actionsLogged = 0;
  int downSitesMyGovs = 0;
  int govBlocked = 0;
  int downCellsMyGovs = 0;
  int uniqueSitesAffected = 0;

  Future<void> initialize() async {
    await _runBusy(() async {
      await _loadLastImport();
      await refreshAll();
    });
  }

  Future<void> refreshAll() async {
    await _loadStats();
    await _loadFilterOptions();
    await loadDownSites();
    await loadDownCells();
    await loadActionTickets();
  }

  Future<void> loadDownSites() async {
    downSites = await _database.getDownSites(
      governorates: downSiteGovernorates,
      search: downSiteSearch,
      outageCategories: selectedOutageCategories,
      severity: downSiteSeverity,
      durationHours: downSiteDurationHours,
    );
    await _loadStats();
    notifyListeners();
  }

  Future<void> loadDownCells() async {
    downCells = await _database.getDownCells(
      governorates: downCellGovernorates,
      search: downCellSearch,
      alertGroups: selectedAlertGroups,
      severity: downCellSeverity,
      durationHours: downCellDurationHours,
    );
    await _loadStats();
    notifyListeners();
  }

  Future<void> loadActionTickets() async {
    actionDownSites = await _database.getDownSitesWithActions();
    actionDownCells = await _database.getDownCellsWithActions();
    await _loadStats();
    notifyListeners();
  }

  Future<int> importSiteList(List<int> bytes) async {
    return _runBusy(() async {
      final count = await _importService.importSiteList(bytes);
      await refreshAll();
      return count;
    });
  }

  Future<ImportResult> importNokiaFmReport(List<int> bytes) async {
    return _runBusy(() async {
      final result = await _importService.importNokiaFmReport(bytes);
      await _loadLastImport();
      await refreshAll();
      return result;
    });
  }

  Future<void> addAction({
    required String ttNumber,
    required String ttType,
    required String engineerName,
    required String actionText,
  }) async {
    final trimmedAction = actionText.trim();
    await _database.addAction(
      ActionLog(
        ttNumber: ttNumber,
        ttType: ttType,
        engineerName: engineerName.trim(),
        actionText: trimmedAction,
        createdAt: DateTime.now(),
      ),
    );
    if (ttType == 'down_site') {
      await _database.updateDownSiteHandlingComment(
        ttNumber: ttNumber,
        handlingComment: trimmedAction,
      );
      await loadDownSites();
    } else {
      await loadDownCells();
    }
    await loadActionTickets();
  }

  Future<void> updateDownSiteComment({
    required String ttNumber,
    required String handlingComment,
  }) async {
    await _database.updateDownSiteHandlingComment(
      ttNumber: ttNumber,
      handlingComment: handlingComment.trim(),
    );
    await loadDownSites();
    await loadActionTickets();
  }

  Future<void> setDownSiteSearch(String value) async {
    downSiteSearch = value;
    await loadDownSites();
  }

  Future<void> setDownCellSearch(String value) async {
    downCellSearch = value;
    await loadDownCells();
  }

  Future<void> toggleDownSiteGovernorate(String governorate) async {
    _toggle(downSiteGovernorates, governorate);
    await loadDownSites();
  }

  Future<void> toggleDownCellGovernorate(String governorate) async {
    _toggle(downCellGovernorates, governorate);
    await loadDownCells();
  }

  Future<void> setDownSiteAdvancedFilters({
    required int? severity,
    required int? durationHours,
    required Set<String> categories,
  }) async {
    downSiteSeverity = severity;
    downSiteDurationHours = durationHours;
    selectedOutageCategories = categories;
    await loadDownSites();
  }

  Future<void> setDownCellAdvancedFilters({
    required int? severity,
    required int? durationHours,
    required Set<String> groups,
  }) async {
    downCellSeverity = severity;
    downCellDurationHours = durationHours;
    selectedAlertGroups = groups;
    await loadDownCells();
  }

  Future<void> _loadLastImport() async {
    final prefs = await SharedPreferences.getInstance();
    lastImport = prefs.getString('last_import');
  }

  Future<void> _loadFilterOptions() async {
    outageCategories = await _database.distinctValues(
      'down_sites',
      'outage_cat',
    );
    alertGroups = await _database.distinctValues('down_cells', 'alert_group');
  }

  Future<void> _loadStats() async {
    sitesLoaded = await _database.count('sites');
    downSitesStored = await _database.count('down_sites');
    downCellsStored = await _database.count('down_cells');
    actionsLogged = await _database.count('actions');
    downSitesMyGovs = await _database.downSitesForGovernorates(
      trackedGovernorates,
    );
    govBlocked = await _database.govBlockedCount();
    downCellsMyGovs = await _database.downCellsForGovernorates(
      trackedGovernorates,
    );
    uniqueSitesAffected = await _database.uniqueSitesAffected(
      trackedGovernorates,
    );
  }

  Future<T> _runBusy<T>(Future<T> Function() task) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await task();
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void _toggle(Set<String> set, String value) {
    if (set.contains(value)) {
      set.remove(value);
    } else {
      set.add(value);
    }
  }
}
