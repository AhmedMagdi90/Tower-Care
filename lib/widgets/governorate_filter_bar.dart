import 'package:flutter/material.dart';
import '../services/ticket_formatters.dart';

class GovernorateFilterBar extends StatelessWidget {
  const GovernorateFilterBar({
    super.key,
    required this.activeGovernorates,
    required this.allGovernorates,
    required this.governorateSiteCounts,
    required this.onToggle,
  });

  final Set<String> activeGovernorates;
  final List<String> allGovernorates;
  final Map<String, int> governorateSiteCounts;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (allGovernorates.isEmpty) return const SizedBox.shrink();

    final String labelText;
    if (activeGovernorates.isEmpty) {
      labelText = 'No Governorates Selected';
    } else if (activeGovernorates.length == allGovernorates.length) {
      labelText = 'All Governorates (${allGovernorates.length})';
    } else {
      labelText = '${activeGovernorates.length} Governorates Selected';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: MenuAnchor(
          style: MenuStyle(
            elevation: WidgetStateProperty.all(8),
            backgroundColor: WidgetStateProperty.all(Colors.white),
            surfaceTintColor: WidgetStateProperty.all(Colors.white),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(vertical: 8),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          builder: (context, controller, child) {
            return OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300, width: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: Color(0xFF1D9E75),
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labelText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    controller.isOpen
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            );
          },
          menuChildren: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      for (final gov in allGovernorates) {
                        if (!activeGovernorates.contains(gov)) {
                          onToggle(gov);
                        }
                      }
                    },
                    icon: const Icon(Icons.select_all, size: 16),
                    label: const Text(
                      'Select All',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      for (final gov in allGovernorates) {
                        if (activeGovernorates.contains(gov)) {
                          onToggle(gov);
                        }
                      }
                    },
                    icon: const Icon(Icons.deselect, size: 16),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...allGovernorates.map((governorate) {
              final isSelected = activeGovernorates.contains(governorate);
              final siteCount = governorateSiteCounts[governorate] ?? 0;
              final displayLabel = siteCount > 0
                  ? '$governorate ($siteCount)'
                  : governorate;
              final color = governorateColor(governorate);

              return MenuItemButton(
                closeOnActivate: false,
                onPressed: () => onToggle(governorate),
                leadingIcon: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected
                      ? const Color(0xFF1D9E75)
                      : Colors.grey.shade400,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        displayLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected ? Colors.black87 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
