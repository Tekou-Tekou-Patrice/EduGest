class Absence {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final DateTime date;
  final String period;
  final String reason;
  final bool isJustified;

  Absence({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.date,
    required this.period,
    required this.reason,
    this.isJustified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'date': date.toIso8601String(),
      'period': period,
      'reason': reason,
      'isJustified': isJustified,
      'justified': isJustified,
    };
  }

  factory Absence.fromMap(Map<String, dynamic> map) {
    final justified = map['isJustified'] ?? map['justified'] ?? false;
    return Absence(
      id: map['id']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      period: map['period']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      isJustified: justified == true,
    );
  }
}
