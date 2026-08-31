class Payment {
  final String id;
  final String studentId;
  final String studentName;
  final double amount;
  final DateTime date;
  final String description;
  final String? recordedById;
  final String? recordedByName;
  final double? totalTuition;
  final double? totalPaid;
  final double? remaining;
  final bool tuitionCompleted;

  Payment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.date,
    required this.description,
    this.recordedById,
    this.recordedByName,
    this.totalTuition,
    this.totalPaid,
    this.remaining,
    this.tuitionCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'studentId': studentId,
      'studentName': studentName,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      if (recordedById != null) 'recordedById': int.tryParse(recordedById!),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      amount: _toDouble(map['amount']),
      date: _parseDate(map['date']),
      description: map['description']?.toString() ?? '',
      recordedById: map['recordedById']?.toString(),
      recordedByName: map['recordedByName']?.toString(),
      totalTuition: _nullableDouble(map['totalTuition']),
      totalPaid: _nullableDouble(map['totalPaid']),
      remaining: _nullableDouble(map['remaining']),
      tuitionCompleted: map['tuitionCompleted'] == true,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    return _toDouble(value);
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
