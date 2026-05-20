import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/down_cell.dart';
import '../models/down_site.dart';

const trackedGovernorates = {
  'Minya',
  'Asyut',
  'Sohag',
  'Aswan',
  'Qena',
  'Beni Suef',
  'Luxor',
  'Faiyum',
  'New Valley',
};

const governorateColors = {
  'Minya': Color(0xFF8B5CF6), // Purple
  'Asyut': Color(0xFFEC4899), // Pink
  'Sohag': Color(0xFF1D9E75), // Green
  'Aswan': Color(0xFFE24B4A), // Red
  'Qena': Color(0xFF378ADD), // Blue
  'Beni Suef': Color(0xFF0D9488), // Teal
  'Luxor': Color(0xFFBA7517), // Orange
  'Faiyum': Color(0xFFD97706), // Amber
  'New Valley': Color(0xFF6366F1), // Indigo
  'Unknown': Color(0xFF6B7280),
};

final shortDateTimeFormat = DateFormat('dd MMM HH:mm');
final fileDateTimeFormat = DateFormat('yyyyMMdd_HHmmss');

Color governorateColor(String governorate) {
  final cleanName = governorate.trim();
  if (governorateColors.containsKey(cleanName)) {
    return governorateColors[cleanName]!;
  }
  final hash = cleanName.hashCode;
  final colors = [
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF0D9488),
    const Color(0xFFD97706),
    const Color(0xFF6366F1),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFF3B82F6),
  ];
  return colors[hash.abs() % colors.length];
}

String durationText(DateTime firstOcc) {
  final duration = DateTime.now().difference(firstOcc);
  if (duration.inDays > 0) {
    return '${duration.inDays}d ${duration.inHours % 24}h';
  }
  if (duration.inHours > 0) {
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }
  return '${duration.inMinutes.clamp(0, 59)}m';
}

Color durationColor(DateTime firstOcc) {
  final hours = DateTime.now().difference(firstOcc).inHours;
  if (hours < 6) return Colors.green;
  if (hours <= 24) return Colors.orange;
  return Colors.red;
}

BadgeColors outageBadgeColors(String text) {
  final value = text.toLowerCase();
  if (value.contains('gov')) {
    return const BadgeColors(Color(0xFFFCEBEB), Color(0xFFA32D2D));
  }
  if (value.contains('power')) {
    return const BadgeColors(Color(0xFFFAEEDA), Color(0xFF854F0B));
  }
  if (value.contains('access')) {
    return const BadgeColors(Color(0xFFE6F1FB), Color(0xFF185FA5));
  }
  if (value.contains('fiber')) {
    return const BadgeColors(Color(0xFFE1F5EE), Color(0xFF0F6E56));
  }
  if (value.contains('dependency')) {
    return const BadgeColors(Color(0xFFEEEDFE), Color(0xFF534AB7));
  }
  return const BadgeColors(Color(0xFFF1EFE8), Color(0xFF5F5E5A));
}

BadgeColors alertGroupBadgeColors(String text) {
  final value = text.toUpperCase();
  if (value.contains('BCCH MISSING')) {
    return const BadgeColors(Color(0xFFFCEBEB), Color(0xFFA32D2D));
  }
  if (value.contains('BASE STATION SERVICE PROBLEM')) {
    return const BadgeColors(Color(0xFFFAEEDA), Color(0xFF854F0B));
  }
  if (value.contains('BASE STATION HARDWARE PROBLEM')) {
    return const BadgeColors(Color(0xFFFFE6D8), Color(0xFF9A3412));
  }
  if (value.contains('CELL FAULTY')) {
    return const BadgeColors(Color(0xFFE6F1FB), Color(0xFF185FA5));
  }
  return const BadgeColors(Color(0xFFF1EFE8), Color(0xFF5F5E5A));
}

String downSiteShareText(DownSite site) {
  final handling = _cleanText(site.handlingComment);
  final buffer = StringBuffer()
    ..writeln('Down Site - ${site.governorate}')
    ..writeln('${site.node} | ${site.ttNumber}')
    ..writeln(
      'S${site.severity} | ${site.outageCat ?? '-'} | ${durationText(site.firstOcc)}',
    )
    ..writeln('First: ${shortDateTimeFormat.format(site.firstOcc)}');
  if (handling.isNotEmpty) {
    buffer.writeln('Handling: $handling');
  }
  if (site.actions.isNotEmpty) {
    buffer.writeln('Actions:');
    for (final action in site.actions) {
      buffer.writeln(
        '- ${action.engineerName}: ${action.actionText} '
        '(${shortDateTimeFormat.format(action.createdAt)})',
      );
    }
  }
  return buffer.toString().trim();
}

String downCellShareText(DownCell cell) {
  final buffer = StringBuffer()
    ..writeln('Down Cell - ${cell.governorate}')
    ..writeln('${cell.node} | ${cell.ttNumber}')
    ..writeln(
      'Cell: ${cell.cellNumber ?? '-'} | S${cell.severity} | ${durationText(cell.firstOcc)}',
    )
    ..writeln('First: ${shortDateTimeFormat.format(cell.firstOcc)}')
    ..writeln('Alert: ${cell.alertGroup}');
  if (cell.actions.isNotEmpty) {
    buffer.writeln('Actions:');
    for (final action in cell.actions) {
      buffer.writeln(
        '- ${action.engineerName}: ${action.actionText} '
        '(${shortDateTimeFormat.format(action.createdAt)})',
      );
    }
  }
  return buffer.toString().trim();
}

String _cleanText(String? value) {
  return (value ?? '').trim().replaceAll(RegExp(r'[;\s]+$'), '');
}

class BadgeColors {
  const BadgeColors(this.background, this.foreground);

  final Color background;
  final Color foreground;
}
