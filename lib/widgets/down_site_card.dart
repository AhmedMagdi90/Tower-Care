import 'package:flutter/material.dart';

import '../models/down_site.dart';
import '../services/ticket_formatters.dart';
import 'action_history_panel.dart';
import 'pill_badge.dart';

class DownSiteCard extends StatefulWidget {
  const DownSiteCard({
    super.key,
    required this.site,
    required this.onSaveAction,
    required this.onUpdateComment,
    required this.onShareWhatsApp,
    required this.onExportExcel,
  });

  final DownSite site;
  final Future<void> Function(String engineerName, String actionText)
  onSaveAction;
  final Future<void> Function(String handlingComment) onUpdateComment;
  final VoidCallback onShareWhatsApp;
  final VoidCallback onExportExcel;

  @override
  State<DownSiteCard> createState() => _DownSiteCardState();
}

class _DownSiteCardState extends State<DownSiteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final site = widget.site;
    final outage = site.outageCat ?? 'Other';
    final outageColors = outageBadgeColors(outage);
    final govColor = governorateColor(site.governorate);
    final handlingComment = (site.handlingComment ?? '').trim();

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
                      site.node,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PillBadge(
                    text: 'S${site.severity}',
                    background: site.severity >= 5
                        ? const Color(0xFFFCEBEB)
                        : const Color(0xFFFAEEDA),
                    foreground: site.severity >= 5
                        ? const Color(0xFFA32D2D)
                        : const Color(0xFF854F0B),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                site.ttNumber,
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
                    text: site.governorate,
                    background: govColor.withValues(alpha: 0.12),
                    foreground: govColor,
                  ),
                  PillBadge(
                    text: shortDateTimeFormat.format(site.firstOcc),
                    background: const Color(0xFFEFF6FF),
                    foreground: const Color(0xFF1D4ED8),
                  ),
                  PillBadge(
                    text: durationText(site.firstOcc),
                    background: durationColor(
                      site.firstOcc,
                    ).withValues(alpha: 0.12),
                    foreground: durationColor(site.firstOcc),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: PillBadge(
                  text: outage,
                  background: outageColors.background,
                  foreground: outageColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showCommentDialog(handlingComment),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        handlingComment.isEmpty
                            ? Icons.add_comment_outlined
                            : Icons.edit_note,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          handlingComment.isEmpty
                              ? 'Add comment'
                              : handlingComment,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: handlingComment.isEmpty
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: handlingComment.isEmpty
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Text('${site.actions.length} actions'),
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
                  actions: site.actions,
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

  Future<void> _showCommentDialog(String currentComment) async {
    final controller = TextEditingController(text: currentComment);
    final comment = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update comment'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Example: RDG problem',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (comment == null) return;
    await widget.onUpdateComment(comment);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment updated')),
    );
  }
}
