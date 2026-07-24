class Sanction {
  final String id;
  final String studentId;
  final String studentName;
  final String type; // Avertissement, Blâme, Exclusion, etc.
  final String reason;
  final DateTime date;

  Sanction({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.type,
    required this.reason,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'type': type,
      'reason': reason,
      'date': date.toIso8601String(),
    };
  }

  factory Sanction.fromMap(Map<String, dynamic> map) {
    return Sanction(
      id: map['id'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      type: map['type'],
      reason: map['reason'],
      date: DateTime.parse(map['date']),
    );
  }
}
