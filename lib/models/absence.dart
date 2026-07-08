class Absence {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final DateTime date;
  final String period; // ex: "08:00 - 10:00"
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
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'date': date.toIso8601String(),
      'period': period,
      'reason': reason,
      'isJustified': isJustified,
    };
  }

  factory Absence.fromMap(Map<String, dynamic> map) {
    return Absence(
      id: map['id'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      className: map['className'],
      date: DateTime.parse(map['date']),
      period: map['period'],
      reason: map['reason'],
      isJustified: map['isJustified'] ?? false,
    );
  }
}
