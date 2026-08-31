import 'package:intl/intl.dart';

class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String className;
  final DateTime? birthDate;
  final String? photoUrl;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String? registeredById;
  final String? registeredByName;
  final DateTime? registrationDate;
  /// Used only when creating the Parent account; it is never read back.
  final String? parentPassword;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.className,
    this.birthDate,
    this.photoUrl,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.registeredById,
    this.registeredByName,
    this.registrationDate,
    this.parentPassword,
  });

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'firstName': firstName,
      'lastName': lastName,
      'className': className,
      if (birthDate != null) 'birthDate': DateFormat('yyyy-MM-dd').format(birthDate!),
      'photoUrl': photoUrl,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'parentEmail': parentEmail,
      if (parentPassword != null && parentPassword!.isNotEmpty) 'parentPassword': parentPassword,
      if (registeredById != null) 'registeredById': int.tryParse(registeredById!),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id']?.toString() ?? '',
      firstName: map['firstName']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      birthDate: map['birthDate'] != null ? DateTime.tryParse(map['birthDate'].toString()) : null,
      photoUrl: map['photoUrl']?.toString(),
      parentName: map['parentName']?.toString(),
      parentPhone: map['parentPhone']?.toString(),
      parentEmail: map['parentEmail']?.toString() ?? map['email']?.toString(),
      registeredById: map['registeredById']?.toString(),
      registeredByName: map['registeredByName']?.toString(),
      registrationDate: map['registrationDate'] != null 
          ? DateTime.tryParse(map['registrationDate'].toString()) 
          : null,
    );
  }

  Student copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? className,
    DateTime? birthDate,
    String? photoUrl,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? registeredById,
    String? parentPassword,
  }) {
    return Student(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      className: className ?? this.className,
      birthDate: birthDate ?? this.birthDate,
      photoUrl: photoUrl ?? this.photoUrl,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      registeredById: registeredById ?? this.registeredById,
      registeredByName: registeredByName,
      registrationDate: registrationDate,
      parentPassword: parentPassword ?? this.parentPassword,
    );
  }
}
