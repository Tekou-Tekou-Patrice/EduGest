class AuditLog {
  final String id;
  final String action;
  final String entityType;
  final String entityId;
  final String description;
  final String? oldValue;
  final String? newValue;
  final String performedBy;
  final String performedByRole;
  final String? performedById;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.description,
    this.oldValue,
    this.newValue,
    required this.performedBy,
    required this.performedByRole,
    this.performedById,
    required this.timestamp,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id']?.toString() ?? '',
      action: map['action']?.toString() ?? 'ACTION',
      entityType: map['entityType']?.toString() ?? 'GENERAL',
      entityId: map['entityId']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      oldValue: map['oldValue']?.toString(),
      newValue: map['newValue']?.toString(),
      performedBy: map['performedBy']?.toString() ?? 'Utilisateur',
      performedByRole: map['performedByRole']?.toString() ?? '',
      performedById: map['performedById']?.toString(),
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'description': description,
      'oldValue': oldValue,
      'newValue': newValue,
      'performedBy': performedBy,
      'performedByRole': performedByRole,
      'performedById': performedById,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
