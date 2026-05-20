class ActionLog {
  const ActionLog({
    this.id,
    required this.ttNumber,
    required this.ttType,
    required this.engineerName,
    required this.actionText,
    required this.createdAt,
  });

  final int? id;
  final String ttNumber;
  final String ttType;
  final String engineerName;
  final String actionText;
  final DateTime createdAt;

  factory ActionLog.fromMap(Map<String, Object?> map) {
    return ActionLog(
      id: map['id'] as int?,
      ttNumber: (map['tt_number'] ?? '').toString(),
      ttType: (map['tt_type'] ?? '').toString(),
      engineerName: (map['engineer_name'] ?? '').toString(),
      actionText: (map['action_text'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'tt_number': ttNumber,
      'tt_type': ttType,
      'engineer_name': engineerName,
      'action_text': actionText,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
