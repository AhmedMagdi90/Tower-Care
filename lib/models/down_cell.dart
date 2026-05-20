import 'action_log.dart';

class DownCell {
  const DownCell({
    this.id,
    required this.node,
    required this.ttNumber,
    required this.governorate,
    required this.firstOcc,
    this.cellNumber,
    required this.alertGroup,
    required this.severity,
    required this.icdStatus,
    this.status = 'active',
    this.clearedAt,
    this.actions = const [],
  });

  final int? id;
  final String node;
  final String ttNumber;
  final String governorate;
  final DateTime firstOcc;
  final String? cellNumber;
  final String alertGroup;
  final int severity;
  final String icdStatus;
  final String status;
  final DateTime? clearedAt;
  final List<ActionLog> actions;

  factory DownCell.fromMap(
    Map<String, Object?> map, {
    List<ActionLog> actions = const [],
  }) {
    return DownCell(
      id: map['id'] as int?,
      node: (map['node'] ?? '').toString(),
      ttNumber: (map['tt_number'] ?? '').toString(),
      governorate: (map['governorate'] ?? 'Unknown').toString(),
      firstOcc:
          DateTime.tryParse((map['first_occ'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      cellNumber: _nullableString(map['cell_number']),
      alertGroup: (map['alert_group'] ?? '').toString(),
      severity: int.tryParse((map['severity'] ?? '').toString()) ?? 0,
      icdStatus: (map['icd_status'] ?? '').toString(),
      status: (map['status'] ?? 'active').toString(),
      clearedAt: map['cleared_at'] != null
          ? DateTime.tryParse(map['cleared_at'].toString())
          : null,
      actions: actions,
    );
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
