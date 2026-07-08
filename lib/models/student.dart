class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String className;
  final String? photoUrl;
  final String? parentName;
  final String? parentPhone;
  final String? email;
  final String? phone;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.className,
    this.photoUrl,
    this.parentName,
    this.parentPhone,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'className': className,
      'photoUrl': photoUrl,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'email': email,
      'phone': phone,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      className: map['className'] ?? '',
      photoUrl: map['photoUrl'],
      parentName: map['parentName'],
      parentPhone: map['parentPhone'],
      email: map['email'],
      phone: map['phone'],
    );
  }

  Student copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? className,
    String? photoUrl,
    String? parentName,
    String? parentPhone,
    String? email,
    String? phone,
  }) {
    return Student(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      className: className ?? this.className,
      photoUrl: photoUrl ?? this.photoUrl,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
