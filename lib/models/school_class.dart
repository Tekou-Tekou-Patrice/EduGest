class SchoolClass {
  final String id;
  final String name; // ex: "6ème A"
  final String level; // ex: "6ème"
  final String? mainTeacherId; // ID de l'enseignant principal
  final int? roomNumber;

  SchoolClass({
    required this.id,
    required this.name,
    required this.level,
    this.mainTeacherId,
    this.roomNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'mainTeacherId': mainTeacherId,
      'roomNumber': roomNumber,
    };
  }

  factory SchoolClass.fromMap(Map<String, dynamic> map) {
    return SchoolClass(
      id: map['id'],
      name: map['name'],
      level: map['level'],
      mainTeacherId: map['mainTeacherId'],
      roomNumber: map['roomNumber'],
    );
  }
}
