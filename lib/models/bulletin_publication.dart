class BulletinPublication {
  final String id;
  final String className;
  final String period;
  final String? studentId;
  final String publishedBy;
  final String publishedByRole;
  final DateTime publishedAt;
  final bool published;

  BulletinPublication({
    required this.id,
    required this.className,
    required this.period,
    this.studentId,
    required this.publishedBy,
    required this.publishedByRole,
    required this.publishedAt,
    this.published = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'className': className,
      'period': period,
      if (studentId != null && studentId!.isNotEmpty) 'studentId': studentId,
      'publishedBy': publishedBy,
      'publishedByRole': publishedByRole,
      'publishedAt': publishedAt.toIso8601String(),
      'published': published,
    };
  }

  factory BulletinPublication.fromMap(Map<String, dynamic> map) {
    return BulletinPublication(
      id: map['id']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      period: map['period']?.toString() ?? '',
      studentId: map['studentId']?.toString(),
      publishedBy: map['publishedBy']?.toString() ?? 'Direction',
      publishedByRole: map['publishedByRole']?.toString() ?? 'Direction',
      publishedAt:
          DateTime.tryParse(map['publishedAt']?.toString() ?? '') ??
          DateTime.now(),
      published: map['published'] != false,
    );
  }
}
