import 'package:edugest/models/app_user.dart';

class School {
  final String id;
  final String name;
  final String? address;
  final UserRole? role;

  const School({
    required this.id,
    required this.name,
    this.address,
    this.role,
  });

  String get roleLabel {
    switch (role) {
      case UserRole.membre:
        return 'Membre';
      case UserRole.proviseur:
        return 'Proviseur';
      case UserRole.censeur:
        return 'Censeur';
      case UserRole.secretaire:
        return 'Secrétaire';
      case UserRole.comptable:
        return 'Comptable';
      case UserRole.enseignant:
        return 'Enseignant';
      case UserRole.fondateur:
        return 'Fondateur';
      case UserRole.surveillant:
        return 'Surveillant';
      case UserRole.surveillantGeneral:
        return 'Surveillant Général';
      case UserRole.parent:
        return 'Parent';
      case UserRole.eleve:
        return 'Élève';
      case null:
        return 'Rôle non défini';
    }
  }

  factory School.fromMap(Map<String, dynamic> map) {
    final rawRole = map['role']?.toString() ??
        map['membershipRole']?.toString() ??
        map['schoolRole']?.toString();

    return School(
      // The API membership DTO contains both `id` (membership id) and
      // `schoolId` (the id required by the school-selection endpoint).
      id: map['schoolId']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? map['schoolName']?.toString() ?? '',
      address: map['address']?.toString(),
      role: rawRole == null || rawRole.isEmpty
          ? null
          : AppUser.roleFromLabel(rawRole),
    );
  }
}
