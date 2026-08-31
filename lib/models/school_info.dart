class SchoolInfo {
  final String id;
  final String name;
  final String? code;
  final String address;
  final String phone;
  final String? email;
  final String? logoUrl;
  final String currentYearId;
  final int? currentYearNumericId;
  final DateTime? startDate;
  final DateTime? archiveDate;
  final String yearStatus; // ACTIVE, WAITING, NONE, CLOSED
  final bool waitingForNewYear;

  SchoolInfo({
    required this.id,
    required this.name,
    this.code,
    required this.address,
    required this.phone,
    this.email,
    this.logoUrl,
    required this.currentYearId,
    this.currentYearNumericId,
    this.startDate,
    this.archiveDate,
    this.yearStatus = 'ACTIVE',
    this.waitingForNewYear = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
      'currentYearId': currentYearId,
      'currentYearNumericId': currentYearNumericId,
      'startDate': startDate?.toIso8601String().substring(0, 10),
      'archiveDate': archiveDate?.toIso8601String().substring(0, 10),
      'yearStatus': yearStatus,
      'waitingForNewYear': waitingForNewYear,
    };
  }

  factory SchoolInfo.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        final str = value.toString().trim();
        if (str.isEmpty) return null;
        return DateTime.parse(str);
      } catch (_) {
        return null;
      }
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return SchoolInfo(
      id: map['id']?.toString() ?? 'SCHOOL_1',
      name: map['name']?.toString() ?? '',
      code: map['code']?.toString(),
      address: map['address']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString(),
      logoUrl: map['logoUrl']?.toString(),
      currentYearId: map['currentYearId']?.toString() ?? '',
      currentYearNumericId: parseInt(map['currentYearNumericId']),
      startDate: parseDate(map['startDate']),
      archiveDate: parseDate(map['archiveDate']),
      yearStatus: map['yearStatus']?.toString() ?? 'ACTIVE',
      waitingForNewYear: map['waitingForNewYear'] == true,
    );
  }

  SchoolInfo copyWith({
    String? id,
    String? name,
    String? code,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? currentYearId,
    int? currentYearNumericId,
    DateTime? startDate,
    DateTime? archiveDate,
    String? yearStatus,
    bool? waitingForNewYear,
  }) {
    return SchoolInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      currentYearId: currentYearId ?? this.currentYearId,
      currentYearNumericId: currentYearNumericId ?? this.currentYearNumericId,
      startDate: startDate ?? this.startDate,
      archiveDate: archiveDate ?? this.archiveDate,
      yearStatus: yearStatus ?? this.yearStatus,
      waitingForNewYear: waitingForNewYear ?? this.waitingForNewYear,
    );
  }
}
