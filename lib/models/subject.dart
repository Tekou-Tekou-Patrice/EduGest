class Subject {
  final String id;
  final String name;
  final double coefficient;

  Subject({
    required this.id,
    required this.name,
    this.coefficient = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'coefficient': coefficient,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      name: map['name'],
      coefficient: map['coefficient']?.toDouble() ?? 1.0,
    );
  }
}
