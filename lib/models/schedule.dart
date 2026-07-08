class ScheduleItem {
  final String id;
  final String day; // ex: "Lundi", "Mardi"
  final String startTime; // ex: "08:00"
  final String endTime; // ex: "10:00"
  final String subject;
  final String className;
  final String teacherName;
  final bool isBreak;

  ScheduleItem({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.className,
    this.teacherName = "",
    this.isBreak = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'subject': subject,
      'className': className,
      'teacherName': teacherName,
      'isBreak': isBreak,
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'],
      day: map['day'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      subject: map['subject'],
      className: map['className'],
      teacherName: map['teacherName'] ?? "",
      isBreak: map['isBreak'] ?? false,
    );
  }
}
