import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/tracker_provider.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackerProvider>();
    return RefreshIndicator(
      onRefresh: context.read<TrackerProvider>().refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last import',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _lastImportText(provider.lastImport),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.errorContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  provider.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: provider.isBusy ? null : () => _importFmReport(context),
            icon: provider.isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: const Text('Import Nokia FM Report'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: provider.isBusy ? null : () => _importSiteList(context),
            icon: const Icon(Icons.domain_add),
            label: const Text('Import Site List (one-time)'),
          ),
          const SizedBox(height: 16),
          Text(
            'Database stats',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _StatTile(label: 'Sites loaded', value: provider.sitesLoaded),
          _StatTile(
            label: 'Down Sites stored',
            value: provider.downSitesStored,
          ),
          _StatTile(
            label: 'Down Cells stored',
            value: provider.downCellsStored,
          ),
          _StatTile(label: 'Actions logged', value: provider.actionsLogged),
        ],
      ),
    );
  }

  Future<void> _importFmReport(BuildContext context) async {
    final bytes = await _pickExcelFileBytes();
    if (bytes == null || !context.mounted) return;
    try {
      final result = await context.read<TrackerProvider>().importNokiaFmReport(
        bytes,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${result.downSites} down sites, '
            '${result.downCells} down cells',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $error')));
    }
  }

  Future<void> _importSiteList(BuildContext context) async {
    final bytes = await _pickExcelFileBytes();
    if (bytes == null || !context.mounted) return;
    try {
      final count = await context.read<TrackerProvider>().importSiteList(bytes);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Imported $count sites')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Site import failed: $error')));
    }
  }

  Future<List<int>?> _pickExcelFileBytes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    return result?.files.single.bytes;
  }

  String _lastImportText(String? value) {
    if (value == null || value.isEmpty) return 'Never imported';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy HH:mm').format(parsed);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value.toString(),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
