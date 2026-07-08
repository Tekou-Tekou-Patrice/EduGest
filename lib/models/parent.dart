class Parent {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String address;
  final List<String> studentIds; // Liste des IDs des enfants

  Parent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.address,
    this.studentIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'address': address,
      'studentIds': studentIds,
    };
  }

  factory Parent.fromMap(Map<String, dynamic> map) {
    return Parent(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      studentIds: List<String>.from(map['studentIds'] ?? []),
    );
  }
}
