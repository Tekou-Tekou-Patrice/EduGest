class Sanction {
  final String id;
  final String studentId;
  final String studentName;
  final String type;
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
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'studentId': studentId,
      'studentName': studentName,
      'type': type,
      'reason': reason,
      'date': date.toIso8601String(),
    };
  }

  factory Sanction.fromMap(Map<String, dynamic> map) {
    return Sanction(
      id: map['id']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
