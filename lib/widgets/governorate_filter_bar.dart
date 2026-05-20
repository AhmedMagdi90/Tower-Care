import 'package:flutter/material.dart';

import '../services/ticket_formatters.dart';

class GovernorateFilterBar extends StatelessWidget {
  const GovernorateFilterBar({
    super.key,
    required this.activeGovernorates,
    required this.onToggle,
  });

  final Set<String> activeGovernorates;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final governorate in trackedGovernorates)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FilterChip(
                selected: activeGovernorates.contains(governorate),
                label: Text(governorate),
                selectedColor: governorateColor(
                  governorate,
                ).withValues(alpha: 0.18),
                checkmarkColor: governorateColor(governorate),
                side: BorderSide(color: governorateColor(governorate)),
                onSelected: (_) => onToggle(governorate),
              ),
            ),
        ],
      ),
    );
  }
}
