class Teacher {
  final String id;
  final String firstName;
  final String lastName;
  final String speciality; // Matière enseignée
  final String? email;
  final String? phone;

  Teacher({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.speciality,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'speciality': speciality,
      'email': email,
      'phone': phone,
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      speciality: map['speciality'],
      email: map['email'],
      phone: map['phone'],
    );
  }
}
