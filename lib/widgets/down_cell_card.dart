import 'package:flutter/material.dart';

import '../models/down_cell.dart';
import '../services/ticket_formatters.dart';
import 'action_history_panel.dart';
import 'pill_badge.dart';

class DownCellCard extends StatefulWidget {
  const DownCellCard({
    super.key,
    required this.cell,
    required this.onSaveAction,
    required this.onShareWhatsApp,
    required this.onExportExcel,
  });

  final DownCell cell;
  final Future<void> Function(String engineerName, String actionText)
  onSaveAction;
  final VoidCallback onShareWhatsApp;
  final VoidCallback onExportExcel;

  @override
  State<DownCellCard> createState() => _DownCellCardState();
}

class _DownCellCardState extends State<DownCellCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cell = widget.cell;
    final alertColors = alertGroupBadgeColors(cell.alertGroup);
    final govColor = governorateColor(cell.governorate);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 5, backgroundColor: govColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cell.node,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PillBadge(
                    text: 'S${cell.severity}',
                    background: cell.severity >= 5
                        ? const Color(0xFFFCEBEB)
                        : const Color(0xFFFAEEDA),
                    foreground: cell.severity >= 5
                        ? const Color(0xFFA32D2D)
                        : const Color(0xFF854F0B),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                cell.ttNumber,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  PillBadge(
                    text: cell.governorate,
                    background: govColor.withValues(alpha: 0.12),
                    foreground: govColor,
                  ),
                  if ((cell.cellNumber ?? '').isNotEmpty)
                    PillBadge(
                      text: 'Cell ${cell.cellNumber}',
                      background: const Color(0xFFEFF6FF),
                      foreground: const Color(0xFF1D4ED8),
                    ),
                  PillBadge(
                    text: shortDateTimeFormat.format(cell.firstOcc),
                    background: const Color(0xFFEFF6FF),
                    foreground: const Color(0xFF1D4ED8),
                  ),
                  PillBadge(
                    text: durationText(cell.firstOcc),
                    background: durationColor(
                      cell.firstOcc,
                    ).withValues(alpha: 0.12),
                    foreground: durationColor(cell.firstOcc),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: PillBadge(
                  text: cell.alertGroup,
                  background: alertColors.background,
                  foreground: alertColors.foreground,
                ),
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Text('${cell.actions.length} actions'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _expanded = true),
                    child: const Text('Add action'),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: ActionHistoryPanel(
                  actions: cell.actions,
                  onSave: widget.onSaveAction,
                  onShareWhatsApp: widget.onShareWhatsApp,
                  onExportExcel: widget.onExportExcel,
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
