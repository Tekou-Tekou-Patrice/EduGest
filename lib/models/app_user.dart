enum UserRole {
  membre,
  proviseur,
  censeur,
  secretaire,
  comptable,
  enseignant,
  fondateur,
  surveillant,
  surveillantGeneral,
  parent,
  eleve,
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final bool active;
  final String? photoUrl;
  final String? token;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.active = true,
    this.photoUrl,
    this.token,
  });

  AppUser copyWith({UserRole? role}) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      role: role ?? this.role,
      phone: phone,
      active: active,
      photoUrl: photoUrl,
      token: token,
    );
  }

  String get displayRole => _roleToString(role);

  String get initials {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static UserRole roleFromLabel(String roleStr) => _stringToRole(roleStr);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': _roleToString(role),
      'phone': phone,
      'active': active,
      'photoUrl': photoUrl,
      'token': token,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '0',
      name: (map['name'] ?? map['fullName'] ?? map['username'] ?? '')
          .toString(),
      email: (map['email'] ?? '').toString(),
      role: _stringToRole(map['role']?.toString() ?? ''),
      phone: map['phone']?.toString(),
      active: map['active'] == true || map['active'] == null,
      photoUrl: map['photoUrl']?.toString(),
      token: map['token']?.toString(),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser.fromMap(json);

  static String _roleToString(UserRole role) {
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
    }
  }

  static UserRole _stringToRole(String roleStr) {
    final normalized = roleStr
        .trim()
        .toUpperCase()
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('Ê', 'E');
    switch (normalized) {
      case 'MEMBRE':
        return UserRole.membre;
      case 'PROVISEUR':
        return UserRole.proviseur;
      case 'CENSEUR':
        return UserRole.censeur;
      case 'SECRETAIRE':
        return UserRole.secretaire;
      case 'COMPTABLE':
        return UserRole.comptable;
      case 'ENSEIGNANT':
        return UserRole.enseignant;
      case 'FONDATEUR':
        return UserRole.fondateur;
      case 'SURVEILLANT':
        return UserRole.surveillant;
      case 'SURVEILLANT_GENERAL':
      case 'SURVEILLANT GENERAL':
        return UserRole.surveillantGeneral;
      case 'PARENT':
        return UserRole.parent;
      default:
        return UserRole.eleve;
    }
  }
}
