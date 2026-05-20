import 'action_log.dart';

class DownSite {
  const DownSite({
    this.id,
    required this.node,
    required this.ttNumber,
    required this.governorate,
    required this.firstOcc,
    this.outageCat,
    required this.alertGroup,
    required this.severity,
    required this.icdStatus,
    this.handlingComment,
    this.status = 'active',
    this.clearedAt,
    this.hasPowerTicket = false,
    this.actions = const [],
  });

  final int? id;
  final String node;
  final String ttNumber;
  final String governorate;
  final DateTime firstOcc;
  final String? outageCat;
  final String alertGroup;
  final int severity;
  final String icdStatus;
  final String? handlingComment;
  final String status;
  final DateTime? clearedAt;
  final bool hasPowerTicket;
  final List<ActionLog> actions;

  factory DownSite.fromMap(
    Map<String, Object?> map, {
    List<ActionLog> actions = const [],
    bool hasPowerTicket = false,
  }) {
    return DownSite(
      id: map['id'] as int?,
      node: (map['node'] ?? '').toString(),
      ttNumber: (map['tt_number'] ?? '').toString(),
      governorate: (map['governorate'] ?? 'Unknown').toString(),
      firstOcc:
          DateTime.tryParse((map['first_occ'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      outageCat: _nullableString(map['outage_cat']),
      alertGroup: (map['alert_group'] ?? '').toString(),
      severity: int.tryParse((map['severity'] ?? '').toString()) ?? 0,
      icdStatus: (map['icd_status'] ?? '').toString(),
      handlingComment: _nullableString(map['handling_comment']),
      status: (map['status'] ?? 'active').toString(),
      clearedAt: map['cleared_at'] != null
          ? DateTime.tryParse(map['cleared_at'].toString())
          : null,
      hasPowerTicket: hasPowerTicket,
      actions: actions,
    );
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
