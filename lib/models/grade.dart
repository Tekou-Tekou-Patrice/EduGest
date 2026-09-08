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
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'studentId': studentId,
      'examId': examId,
      'score': score,
      'observations': observations,
    };
  }

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      examId: map['examId']?.toString() ?? '',
      score: map['score'] is num
          ? (map['score'] as num).toDouble()
          : double.tryParse('${map['score']}') ?? 0,
      observations: map['observations']?.toString(),
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
  final bool editable;
  final String? teacherName;

  Exam({
    required this.id,
    required this.title,
    required this.subject,
    required this.className,
    required this.date,
    this.coefficient = 1.0,
    this.editable = true,
    this.teacherName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'title': title,
      'subject': subject,
      'className': className,
      'date': date.toIso8601String(),
      'coefficient': coefficient,
      if (teacherName != null) 'teacherName': teacherName,
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      coefficient: map['coefficient'] is num
          ? (map['coefficient'] as num).toDouble()
          : double.tryParse('${map['coefficient']}') ?? 1.0,
      editable: map['editable'] != false,
      teacherName: map['teacherName']?.toString() ?? map['teacher_name']?.toString(),
    );
  }
}
