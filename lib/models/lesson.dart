class Lesson {
  final String id;
  final String title;
  final String content;
  final String className;
  final String subject;
  final DateTime date;
  final String? teacherId;
  final String? teacherName;

  Lesson({
    required this.id,
    required this.title,
    required this.content,
    required this.className,
    required this.subject,
    required this.date,
    this.teacherId,
    this.teacherName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'title': title,
      'content': content,
      'className': className,
      'subject': subject,
      'date': date.toIso8601String(),
      'teacherId': teacherId,
      'teacherName': teacherName,
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      teacherId: map['teacherId']?.toString(),
      teacherName: map['teacherName']?.toString(),
    );
  }
}
