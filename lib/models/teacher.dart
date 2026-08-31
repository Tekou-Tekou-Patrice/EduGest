class Teacher {
  final String id;
  final String firstName;
  final String lastName;
  final String speciality;
  final String? email;
  final String? phone;
  final String? password; // Ajouté pour le recrutement

  Teacher({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.speciality,
    this.email,
    this.phone,
    this.password,
  });

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'firstName': firstName,
      'lastName': lastName,
      'speciality': speciality,
      'email': email,
      'phone': phone,
      if (password != null) 'password': password,
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id']?.toString() ?? '',
      firstName: map['firstName']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      speciality: map['speciality']?.toString() ?? '',
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
    );
  }
}
