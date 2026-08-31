class ScheduleItem {
  final String id;
  final String day;
  final String startTime;
  final String endTime;
  final String subject;
  final String className;
  final String teacherName;
  final String room;
  final bool isBreak;

  ScheduleItem({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.className,
    this.teacherName = '',
    this.room = 'A1',
    this.isBreak = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'subject': subject,
      'className': className,
      'teacherName': teacherName,
      'room': room,
      'isBreak': isBreak,
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id']?.toString() ?? '',
      day: map['day']?.toString() ?? '',
      startTime: map['startTime']?.toString() ?? '',
      endTime: map['endTime']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      teacherName: map['teacherName']?.toString() ?? '',
      room: map['room']?.toString() ?? 'A1',
      isBreak: map['isBreak'] == true || map['break'] == true,
    );
  }
}
