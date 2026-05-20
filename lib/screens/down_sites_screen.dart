import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/down_site.dart';
import '../providers/tracker_provider.dart';
import '../services/excel_export_service.dart';
import '../services/share_service.dart';
import '../services/ticket_formatters.dart';
import '../widgets/down_site_card.dart';
import '../widgets/governorate_filter_bar.dart';
import '../widgets/stat_card.dart';

class DownSitesScreen extends StatefulWidget {
  const DownSitesScreen({super.key});

  @override
  State<DownSitesScreen> createState() => _DownSitesScreenState();
}

class _DownSitesScreenState extends State<DownSitesScreen> {
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
                label: 'Down Sites (My Govs)',
                value: provider.downSitesMyGovs,
                color: const Color(0xFF1D9E75),
              ),
              const SizedBox(width: 8),
              StatCard(
                label: 'GOV Blocked',
                value: provider.govBlocked,
                color: const Color(0xFFE24B4A),
              ),
            ],
          ),
        ),
        GovernorateFilterBar(
          activeGovernorates: provider.downSiteGovernorates,
          allGovernorates: provider.allGovernorates,
          governorateSiteCounts: provider.governorateSiteCounts,
          onToggle: context.read<TrackerProvider>().toggleDownSiteGovernorate,
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
                  onChanged: context.read<TrackerProvider>().setDownSiteSearch,
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
                  ? '${provider.downSites.length} results | ${_selectedTts.length} selected'
                  : '${provider.downSites.length} results',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        if (provider.downSites.isNotEmpty)
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
                            provider.downSites.map((site) => site.ttNumber),
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
          child: provider.downSites.isEmpty
              ? const Center(child: Text('No down sites match the filters.'))
              : ListView.builder(
                  itemCount: provider.downSites.length,
                  itemBuilder: (context, index) {
                    final site = provider.downSites[index];
                    final card = DownSiteCard(
                      key: ValueKey('card-${site.ttNumber}'),
                      site: site,
                      onUpdateComment: (comment) {
                        return context
                            .read<TrackerProvider>()
                            .updateDownSiteComment(
                              ttNumber: site.ttNumber,
                              handlingComment: comment,
                            );
                      },
                      onSaveAction: (engineer, action) {
                        return context.read<TrackerProvider>().addAction(
                          ttNumber: site.ttNumber,
                          ttType: 'down_site',
                          engineerName: engineer,
                          actionText: action,
                        );
                      },
                      onShareWhatsApp: () {
                        _shareService.shareToWhatsApp(downSiteShareText(site));
                      },
                      onExportExcel: () async {
                        final path = await _exportService.exportDownSites([
                          site,
                        ]);
                        await _shareService.shareFile(
                          path,
                          text: 'Down site export',
                        );
                      },
                    );
                    if (!_selectionMode) return card;
                    return Row(
                      key: ValueKey('select-${site.ttNumber}'),
                      children: [
                        Checkbox(
                          value: _selectedTts.contains(site.ttNumber),
                          onChanged: (_) => setState(() {
                            _selectedTts.contains(site.ttNumber)
                                ? _selectedTts.remove(site.ttNumber)
                                : _selectedTts.add(site.ttNumber);
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
                    onPressed: provider.downSites.isEmpty
                        ? null
                        : () => _shareService.shareToWhatsApp(
                            _activeSites(
                              provider,
                            ).map(downSiteShareText).join('\n\n'),
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
                    onPressed: provider.downSites.isEmpty
                        ? null
                        : () async {
                            final path = await _exportService.exportDownSites(
                              _activeSites(provider),
                            );
                            await _shareService.shareFile(
                              path,
                              text: 'Down sites export',
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

  List<DownSite> _activeSites(TrackerProvider provider) {
    if (_selectedTts.isEmpty) return provider.downSites;
    return provider.downSites
        .where((site) => _selectedTts.contains(site.ttNumber))
        .toList();
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final provider = context.read<TrackerProvider>();
    var severity = provider.downSiteSeverity;
    var duration = provider.downSiteDurationHours;
    var categories = {...provider.selectedOutageCategories};

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
                      'Outage category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in provider.outageCategories)
                          FilterChip(
                            label: Text(category),
                            selected: categories.contains(category),
                            onSelected: (_) => setSheetState(() {
                              categories.contains(category)
                                  ? categories.remove(category)
                                  : categories.add(category);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          provider.setDownSiteAdvancedFilters(
                            severity: severity,
                            durationHours: duration,
                            categories: categories,
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
