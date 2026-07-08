enum UserRole { proviseur, censeur, secretaire, comptable, enseignant, fondateur }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': _roleToString(role),
      'photoUrl': photoUrl,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      role: _stringToRole(map['role']),
      photoUrl: map['photoUrl'],
    );
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.proviseur: return 'Proviseur';
      case UserRole.censeur: return 'Censeur';
      case UserRole.secretaire: return 'Secrétaire';
      case UserRole.comptable: return 'Comptable';
      case UserRole.enseignant: return 'Enseignant';
      case UserRole.fondateur: return 'Fondateur';
    }
  }

  static UserRole _stringToRole(String roleStr) {
    switch (roleStr) {
      case 'Proviseur': return UserRole.proviseur;
      case 'Censeur': return UserRole.censeur;
      case 'Secrétaire': return UserRole.secretaire;
      case 'Comptable': return UserRole.comptable;
      case 'Enseignant': return UserRole.enseignant;
      case 'Fondateur': return UserRole.fondateur;
      default: return UserRole.enseignant;
    }
  }
}
