class SchoolInfo {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String? email;
  final String? logoUrl;
  final String currentYearId; // Lien vers l'année scolaire en cours

  SchoolInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.email,
    this.logoUrl,
    required this.currentYearId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
      'currentYearId': currentYearId,
    };
  }

  factory SchoolInfo.fromMap(Map<String, dynamic> map) {
    return SchoolInfo(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      logoUrl: map['logoUrl'],
      currentYearId: map['currentYearId'],
    );
  }
}
