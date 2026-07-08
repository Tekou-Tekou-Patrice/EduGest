class Payment {
  final String id;
  final String studentId;
  final String studentName;
  final double amount;
  final DateTime date;
  final String description; // ex: "Frais de scolarité - 1ère Tranche"

  Payment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      amount: map['amount'].toDouble(),
      date: DateTime.parse(map['date']),
      description: map['description'],
    );
  }
}
