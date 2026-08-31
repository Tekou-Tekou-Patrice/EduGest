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
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'name': name,
      'coefficient': coefficient,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      coefficient: map['coefficient'] is num
          ? (map['coefficient'] as num).toDouble()
          : double.tryParse(map['coefficient']?.toString() ?? '1.0') ?? 1.0,
    );
  }
}
