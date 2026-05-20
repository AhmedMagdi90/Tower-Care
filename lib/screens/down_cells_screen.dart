import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/down_cell.dart';
import '../providers/tracker_provider.dart';
import '../services/excel_export_service.dart';
import '../services/share_service.dart';
import '../services/ticket_formatters.dart';
import '../widgets/down_cell_card.dart';
import '../widgets/governorate_filter_bar.dart';
import '../widgets/stat_card.dart';

class DownCellsScreen extends StatefulWidget {
  const DownCellsScreen({super.key});

  @override
  State<DownCellsScreen> createState() => _DownCellsScreenState();
}

class _DownCellsScreenState extends State<DownCellsScreen> {
  final _searchController = TextEditingController();
  final _shareService = ShareService();
  final _exportService = ExcelExportService();
  final Set<String> _selectedTts = {};
  bool _selectionMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackerProvider>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              StatCard(
                label: 'Down Cells (My Govs)',
                value: provider.downCellsMyGovs,
                color: const Color(0xFF378ADD),
              ),
              const SizedBox(width: 8),
              StatCard(
                label: 'Unique Sites Affected',
                value: provider.uniqueSitesAffected,
                color: const Color(0xFFE24B4A),
              ),
            ],
          ),
        ),
        GovernorateFilterBar(
          activeGovernorates: provider.downCellGovernorates,
          allGovernorates: provider.allGovernorates,
          governorateSiteCounts: provider.governorateSiteCounts,
          onToggle: context.read<TrackerProvider>().toggleDownCellGovernorate,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search node or TT number',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: context.read<TrackerProvider>().setDownCellSearch,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Filters',
                onPressed: () => _showFilterSheet(context),
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              _selectionMode
                  ? '${provider.downCells.length} results | ${_selectedTts.length} selected'
                  : '${provider.downCells.length} results',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        if (provider.downCells.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectionMode = !_selectionMode;
                      if (!_selectionMode) _selectedTts.clear();
                    });
                  },
                  icon: Icon(_selectionMode ? Icons.close : Icons.checklist),
                  label: Text(_selectionMode ? 'Cancel select' : 'Select'),
                ),
                if (_selectionMode) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTts
                          ..clear()
                          ..addAll(
                            provider.downCells.map((cell) => cell.ttNumber),
                          );
                      });
                    },
                    child: const Text('Select all'),
                  ),
                  TextButton(
                    onPressed: () => setState(_selectedTts.clear),
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),
        Expanded(
          child: provider.downCells.isEmpty
              ? const Center(child: Text('No down cells match the filters.'))
              : ListView.builder(
                  itemCount: provider.downCells.length,
                  itemBuilder: (context, index) {
                    final cell = provider.downCells[index];
                    final card = DownCellCard(
                      key: ValueKey('card-${cell.ttNumber}'),
                      cell: cell,
                      onSaveAction: (engineer, action) {
                        return context.read<TrackerProvider>().addAction(
                          ttNumber: cell.ttNumber,
                          ttType: 'down_cell',
                          engineerName: engineer,
                          actionText: action,
                        );
                      },
                      onShareWhatsApp: () {
                        _shareService.shareToWhatsApp(downCellShareText(cell));
                      },
                      onExportExcel: () async {
                        final path = await _exportService.exportDownCells([
                          cell,
                        ]);
                        await _shareService.shareFile(
                          path,
                          text: 'Down cell export',
                        );
                      },
                    );
                    if (!_selectionMode) return card;
                    return Row(
                      key: ValueKey('select-${cell.ttNumber}'),
                      children: [
                        Checkbox(
                          value: _selectedTts.contains(cell.ttNumber),
                          onChanged: (_) => setState(() {
                            _selectedTts.contains(cell.ttNumber)
                                ? _selectedTts.remove(cell.ttNumber)
                                : _selectedTts.add(cell.ttNumber);
                          }),
                        ),
                        Expanded(child: card),
                      ],
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                    ),
                    onPressed: provider.downCells.isEmpty
                        ? null
                        : () => _shareService.shareToWhatsApp(
                            _activeCells(
                              provider,
                            ).map(downCellShareText).join('\n\n'),
                          ),
                    icon: const Icon(Icons.chat),
                    label: Text(
                      _selectedTts.isEmpty ? 'Share All' : 'Share Selected',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFBA7517),
                    ),
                    onPressed: provider.downCells.isEmpty
                        ? null
                        : () async {
                            final path = await _exportService.exportDownCells(
                              _activeCells(provider),
                            );
                            await _shareService.shareFile(
                              path,
                              text: 'Down cells export',
                            );
                          },
                    icon: const Icon(Icons.table_view),
                    label: Text(
                      _selectedTts.isEmpty ? 'Export All' : 'Export Selected',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<DownCell> _activeCells(TrackerProvider provider) {
    if (_selectedTts.isEmpty) return provider.downCells;
    return provider.downCells
        .where((cell) => _selectedTts.contains(cell.ttNumber))
        .toList();
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final provider = context.read<TrackerProvider>();
    var severity = provider.downCellSeverity;
    var duration = provider.downCellDurationHours;
    var groups = {...provider.selectedAlertGroups};

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Severity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: severity == null,
                          onSelected: (_) =>
                              setSheetState(() => severity = null),
                        ),
                        ChoiceChip(
                          label: const Text('Critical (5)'),
                          selected: severity == 5,
                          onSelected: (_) => setSheetState(() => severity = 5),
                        ),
                        ChoiceChip(
                          label: const Text('Major (4)'),
                          selected: severity == 4,
                          onSelected: (_) => setSheetState(() => severity = 4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Duration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final option in [null, 1, 6, 24, 72])
                          ChoiceChip(
                            label: Text(option == null ? 'All' : '>$option h'),
                            selected: duration == option,
                            onSelected: (_) =>
                                setSheetState(() => duration = option),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Alert group',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final group in provider.alertGroups)
                          FilterChip(
                            label: Text(group),
                            selected: groups.contains(group),
                            onSelected: (_) => setSheetState(() {
                              groups.contains(group)
                                  ? groups.remove(group)
                                  : groups.add(group);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          provider.setDownCellAdvancedFilters(
                            severity: severity,
                            durationHours: duration,
                            groups: groups,
                          );
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Apply filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
