import 'package:edugest/models/app_user.dart';

class School {
  final String id;
  final String name;
  final String? address;
  final UserRole? role;
  final String schoolLevel;

  const School({
    required this.id,
    required this.name,
    this.address,
    this.role,
    this.schoolLevel = 'COLLEGE',
  });

  String get roleLabel {
    if (role == null) return 'Rôle non défini';
    return AppUser.roleLabel(role!, schoolLevel: schoolLevel);
  }

  factory School.fromMap(Map<String, dynamic> map) {
    final rawRole =
        map['role']?.toString() ??
        map['membershipRole']?.toString() ??
        map['schoolRole']?.toString();

    return School(
      // The API membership DTO contains both `id` (membership id) and
      // `schoolId` (the id required by the school-selection endpoint).
      id: map['schoolId']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? map['schoolName']?.toString() ?? '',
      address: map['address']?.toString(),
      schoolLevel: _normalizeSchoolLevel(map['schoolLevel']),
      role: rawRole == null || rawRole.isEmpty
          ? null
          : AppUser.roleFromLabel(rawRole),
    );
  }

  static String _normalizeSchoolLevel(dynamic value) {
    switch (value?.toString().toUpperCase()) {
      case 'PRIMARY':
        return 'PRIMARY';
      case 'COLLEGE':
        return 'COLLEGE';
      case 'LYCEE':
        return 'LYCEE';
      default:
        return 'COLLEGE';
    }
  }
}
