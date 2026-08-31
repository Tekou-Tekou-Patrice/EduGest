import 'package:intl/intl.dart';

class AcademicYearRecap {
  final int? id;
  final String label;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool active;
  final String status;
  final double totalRevenue;
  final double totalExpenses;
  final double balance;
  final int studentCount;
  final int teacherCount;
  final int absenceCount;
  final int sanctionCount;
  final int examCount;
  final int lessonCount;
  final String? schoolName;
  final DateTime? closedAt;

  AcademicYearRecap({
    this.id,
    required this.label,
    this.startDate,
    this.endDate,
    this.active = false,
    this.status = 'CLOSED',
    this.totalRevenue = 0.0,
    this.totalExpenses = 0.0,
    this.balance = 0.0,
    this.studentCount = 0,
    this.teacherCount = 0,
    this.absenceCount = 0,
    this.sanctionCount = 0,
    this.examCount = 0,
    this.lessonCount = 0,
    this.schoolName,
    this.closedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'startDate': startDate?.toIso8601String().substring(0, 10),
      'endDate': endDate?.toIso8601String().substring(0, 10),
      'active': active,
      'status': status,
      'totalRevenue': totalRevenue,
      'totalExpenses': totalExpenses,
      'balance': balance,
      'studentCount': studentCount,
      'teacherCount': teacherCount,
      'absenceCount': absenceCount,
      'sanctionCount': sanctionCount,
      'examCount': examCount,
      'lessonCount': lessonCount,
      'schoolName': schoolName,
      'closedAt': closedAt?.toIso8601String(),
    };
  }

  factory AcademicYearRecap.fromMap(Map<String, dynamic> map) {
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

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return AcademicYearRecap(
      id: map['id'] != null ? parseInt(map['id']) : null,
      label: map['label']?.toString() ?? '',
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate'] ?? map['archiveDate']),
      active: map['active'] == true,
      status: map['status']?.toString() ?? (map['active'] == true ? 'ACTIVE' : 'CLOSED'),
      totalRevenue: parseDouble(map['totalRevenue']),
      totalExpenses: parseDouble(map['totalExpenses']),
      balance: parseDouble(map['balance'] ?? (parseDouble(map['totalRevenue']) - parseDouble(map['totalExpenses']))),
      studentCount: parseInt(map['studentCount']),
      teacherCount: parseInt(map['teacherCount']),
      absenceCount: parseInt(map['absenceCount']),
      sanctionCount: parseInt(map['sanctionCount']),
      examCount: parseInt(map['examCount']),
      lessonCount: parseInt(map['lessonCount']),
      schoolName: map['schoolName']?.toString(),
      closedAt: parseDate(map['closedAt']),
    );
  }

  String get formattedStartDate => startDate != null ? DateFormat('dd/MM/yyyy').format(startDate!) : '-';
  String get formattedEndDate => endDate != null ? DateFormat('dd/MM/yyyy').format(endDate!) : '-';
  String get formattedClosedAt => closedAt != null ? DateFormat('dd/MM/yyyy à HH:mm').format(closedAt!) : formattedEndDate;

  String get formattedRevenue => '${NumberFormat('#,###', 'fr_FR').format(totalRevenue.round())} FCFA';
  String get formattedExpenses => '${NumberFormat('#,###', 'fr_FR').format(totalExpenses.round())} FCFA';
  String get formattedBalance => '${NumberFormat('#,###', 'fr_FR').format(balance.round())} FCFA';
}
