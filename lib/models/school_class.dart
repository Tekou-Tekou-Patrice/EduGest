class SchoolClass {
  final String id;
  final String name;
  final String level;
  final int capacity;
  final String? description;
  final String? teacherId;
  final String? teacherName;
  final List<String> teacherIds;
  final List<String> teacherNames;
  final int studentCount;
  final double tuitionFee;
  final bool examClass;

  SchoolClass({
    required this.id,
    required this.name,
    required this.level,
    this.capacity = 40,
    this.description,
    this.teacherId,
    this.teacherName,
    this.teacherIds = const [],
    this.teacherNames = const [],
    this.studentCount = 0,
    this.tuitionFee = 0,
    this.examClass = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'name': name,
      'level': level,
      'capacity': capacity,
      'description': description,
      'tuitionFee': tuitionFee,
      'examClass': examClass,
      if (teacherId != null && teacherId!.isNotEmpty)
        'teacherId': int.tryParse(teacherId!) ?? teacherId,
      'teacherIds': teacherIds
          .where((id) => id.isNotEmpty)
          .map((id) => int.tryParse(id) ?? id)
          .toList(),
    };
  }

  factory SchoolClass.fromMap(Map<String, dynamic> map) {
    return SchoolClass(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      level: map['level']?.toString() ?? '',
      capacity: map['capacity'] is int
          ? map['capacity'] as int
          : int.tryParse('${map['capacity']}') ?? 40,
      description: map['description']?.toString(),
      teacherId: map['teacherId']?.toString(),
      teacherName: map['teacherName']?.toString(),
      teacherIds: (map['teacherIds'] as List? ?? const [])
          .map((id) => id.toString())
          .toList(),
      teacherNames: (map['teacherNames'] as List? ?? const [])
          .map((name) => name.toString())
          .toList(),
      studentCount: map['studentCount'] is int
          ? map['studentCount'] as int
          : int.tryParse('${map['studentCount']}') ?? 0,
      tuitionFee: map['tuitionFee'] is num
          ? (map['tuitionFee'] as num).toDouble()
          : double.tryParse('${map['tuitionFee']}') ?? 0,
      examClass:
          map['examClass'] == true || map['examClass']?.toString() == 'true',
    );
  }
}
