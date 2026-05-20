import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tracker_provider.dart';
import '../services/excel_export_service.dart';
import '../services/share_service.dart';
import '../services/ticket_formatters.dart';
import '../widgets/down_cell_card.dart';
import '../widgets/down_site_card.dart';

class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
  final _shareService = ShareService();
  final _exportService = ExcelExportService();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackerProvider>();
    final siteCount = provider.actionDownSites.length;
    final cellCount = provider.actionDownCells.length;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              tabs: [
                Tab(text: 'Down Sites ($siteCount)'),
                Tab(text: 'Down Cells ($cellCount)'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: context.read<TrackerProvider>().loadActionTickets,
                  child: provider.actionDownSites.isEmpty
                      ? const _EmptyActions(
                          message: 'No down-site actions yet.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: provider.actionDownSites.length,
                          itemBuilder: (context, index) {
                            final site = provider.actionDownSites[index];
                            return DownSiteCard(
                              site: site,
                              onUpdateComment: (comment) => context
                                  .read<TrackerProvider>()
                                  .updateDownSiteComment(
                                    ttNumber: site.ttNumber,
                                    handlingComment: comment,
                                  ),
                              onSaveAction: (engineer, action) {
                                return context
                                    .read<TrackerProvider>()
                                    .addAction(
                                      ttNumber: site.ttNumber,
                                      ttType: 'down_site',
                                      engineerName: engineer,
                                      actionText: action,
                                    );
                              },
                              onShareWhatsApp: () {
                                _shareService.shareToWhatsApp(
                                  downSiteShareText(site),
                                );
                              },
                              onExportExcel: () async {
                                final path = await _exportService
                                    .exportDownSites([site]);
                                await _shareService.shareFile(
                                  path,
                                  text: 'Down site export',
                                );
                              },
                            );
                          },
                        ),
                ),
                RefreshIndicator(
                  onRefresh: context.read<TrackerProvider>().loadActionTickets,
                  child: provider.actionDownCells.isEmpty
                      ? const _EmptyActions(
                          message: 'No down-cell actions yet.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: provider.actionDownCells.length,
                          itemBuilder: (context, index) {
                            final cell = provider.actionDownCells[index];
                            return DownCellCard(
                              cell: cell,
                              onSaveAction: (engineer, action) {
                                return context
                                    .read<TrackerProvider>()
                                    .addAction(
                                      ttNumber: cell.ttNumber,
                                      ttType: 'down_cell',
                                      engineerName: engineer,
                                      actionText: action,
                                    );
                              },
                              onShareWhatsApp: () {
                                _shareService.shareToWhatsApp(
                                  downCellShareText(cell),
                                );
                              },
                              onExportExcel: () async {
                                final path = await _exportService
                                    .exportDownCells([cell]);
                                await _shareService.shareFile(
                                  path,
                                  text: 'Down cell export',
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActions extends StatelessWidget {
  const _EmptyActions({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
        Center(child: Text(message)),
      ],
    );
  }
}
