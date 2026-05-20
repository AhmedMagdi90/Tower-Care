import 'package:flutter/material.dart';

import '../models/action_log.dart';
import '../services/ticket_formatters.dart';

class ActionHistoryPanel extends StatefulWidget {
  const ActionHistoryPanel({
    super.key,
    required this.actions,
    required this.onSave,
    required this.onShareWhatsApp,
    required this.onExportExcel,
  });

  final List<ActionLog> actions;
  final Future<void> Function(String engineerName, String actionText) onSave;
  final VoidCallback onShareWhatsApp;
  final VoidCallback onExportExcel;

  @override
  State<ActionHistoryPanel> createState() => _ActionHistoryPanelState();
}

class _ActionHistoryPanelState extends State<ActionHistoryPanel> {
  final _engineerController = TextEditingController();
  final _actionController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _engineerController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final engineer = _engineerController.text.trim();
    final action = _actionController.text.trim();
    if (engineer.isEmpty || action.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Engineer name and action are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(engineer, action);
    if (!mounted) return;
    _engineerController.clear();
    _actionController.clear();
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        if (widget.actions.isEmpty)
          Text(
            'No actions logged',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          for (final action in widget.actions)
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(_initials(action.engineerName)),
                ),
                title: Text(
                  action.engineerName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shortDateTimeFormat.format(action.createdAt)),
                    const SizedBox(height: 4),
                    Text(action.actionText),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 8),
        TextField(
          controller: _engineerController,
          decoration: const InputDecoration(
            hintText: 'Engineer name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _actionController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Action taken...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Share to WhatsApp',
              onPressed: widget.onShareWhatsApp,
              icon: const Icon(Icons.chat),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Export Excel',
              onPressed: widget.onExportExcel,
              icon: const Icon(Icons.table_view),
            ),
          ],
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }
}
