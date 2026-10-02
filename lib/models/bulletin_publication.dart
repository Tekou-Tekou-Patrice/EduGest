class BulletinPublication {
  final String id;
  final String className;
  final String period;
  final String? studentId;
  final String publishedBy;
  final String publishedByRole;
  final String languageCode;
  final DateTime publishedAt;
  final bool published;
  final double? promotionThreshold;
  final String? promotionTargetClassName;

  BulletinPublication({
    required this.id,
    required this.className,
    required this.period,
    this.studentId,
    required this.publishedBy,
    required this.publishedByRole,
    this.languageCode = 'fr',
    required this.publishedAt,
    this.published = true,
    this.promotionThreshold,
    this.promotionTargetClassName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty && id != '0') 'id': int.tryParse(id) ?? id,
      'className': className,
      'period': period,
      if (studentId != null && studentId!.isNotEmpty) 'studentId': studentId,
      'publishedBy': publishedBy,
      'publishedByRole': publishedByRole,
      'languageCode': languageCode,
      'publishedAt': publishedAt.toIso8601String(),
      'published': published,
      if (promotionThreshold != null) 'promotionThreshold': promotionThreshold,
      if (promotionTargetClassName != null)
        'promotionTargetClassName': promotionTargetClassName,
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
      languageCode: map['languageCode']?.toString() == 'en' ? 'en' : 'fr',
      publishedAt:
          DateTime.tryParse(map['publishedAt']?.toString() ?? '') ??
          DateTime.now(),
      published: map['published'] != false,
      promotionThreshold: map['promotionThreshold'] is num
          ? (map['promotionThreshold'] as num).toDouble()
          : double.tryParse('${map['promotionThreshold']}'),
      promotionTargetClassName: map['promotionTargetClassName']?.toString(),
    );
  }
}
