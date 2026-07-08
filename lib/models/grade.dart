class Grade {
  final String id;
  final String studentId;
  final String examId;
  final double score;
  final String? observations;

  Grade({
    required this.id,
    required this.studentId,
    required this.examId,
    required this.score,
    this.observations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'examId': examId,
      'score': score,
      'observations': observations,
    };
  }

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'],
      studentId: map['studentId'],
      examId: map['examId'],
      score: map['score'].toDouble(),
      observations: map['observations'],
    );
  }
}

class Exam {
  final String id;
  final String title;
  final String subject;
  final String className;
  final DateTime date;
  final double coefficient;

  Exam({
    required this.id,
    required this.title,
    required this.subject,
    required this.className,
    required this.date,
    this.coefficient = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'className': className,
      'date': date.toIso8601String(),
      'coefficient': coefficient,
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      className: map['className'],
      date: DateTime.parse(map['date']),
      coefficient: map['coefficient']?.toDouble() ?? 1.0,
    );
  }
}
