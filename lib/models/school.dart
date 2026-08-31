class School {
  final String id;
  final String name;
  final String? address;

  const School({required this.id, required this.name, this.address});

  factory School.fromMap(Map<String, dynamic> map) {
    return School(
      // The API membership DTO contains both `id` (membership id) and
      // `schoolId` (the id required by the school-selection endpoint).
      id: map['schoolId']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? map['schoolName']?.toString() ?? '',
      address: map['address']?.toString(),
    );
  }
}
