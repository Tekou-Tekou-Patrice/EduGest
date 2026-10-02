import 'dart:typed_data';

import '../models/absence.dart';
import '../models/academic_year_recap.dart';
import '../models/grade.dart';
import '../models/payment.dart';
import '../models/school_info.dart';
import '../models/student.dart';
import '../models/subject.dart';
import 'api_service.dart';
import 'export_service.dart';

class YearArchiveService {
  static const _archiveTypes = {
    'year_recap',
    'bulletins',
    'receipts',
    'year_data',
  };

  static Future<Set<String>> archiveAndPurge({
    required AcademicYearRecap year,
    SchoolInfo? schoolInfo,
    String languageCode = 'fr',
  }) async {
    final yearId = year.id;
    if (yearId == null) {
      throw StateError('Cette année scolaire n’a pas d’identifiant serveur.');
    }

    var existing = await ApiService.getAcademicYearArchives(yearId: yearId);
    if (!_archiveTypes.every(existing.contains)) {
      if (!existing.contains('year_data')) {
        final compressedBackup =
            await ApiService.exportCompressedAcademicYearBackup(yearId);
        await ApiService.uploadCompressedAcademicYearArchive(
          yearId: yearId,
          bytes: compressedBackup,
        );
        existing.add('year_data');
      }

      final data = await ApiService.exportBackup();
      final payments = _yearItems(data['payments'], yearId).map((item) {
        final recordedBy = item['recordedBy'];
        if (recordedBy is Map) {
          final firstName = recordedBy['firstName']?.toString() ?? '';
          final lastName = recordedBy['lastName']?.toString() ?? '';
          item['recordedByName'] =
              recordedBy['fullName']?.toString() ??
              '$firstName $lastName'.trim();
        }
        return Payment.fromMap(item);
      }).toList();
      final exams = _yearItems(
        data['exams'],
        yearId,
      ).map(Exam.fromMap).toList();
      final grades = _yearItems(
        data['grades'],
        yearId,
      ).map(Grade.fromMap).toList();
      final absences = _yearItems(
        data['absences'],
        yearId,
      ).map(Absence.fromMap).toList();
      final students = _mapItems(
        data['students'],
      ).map(Student.fromMap).toList();
      final subjects = _mapItems(
        data['subjects'],
      ).map(Subject.fromMap).toList();
      final studentsWithRecords = students
          .where(
            (student) =>
                grades.any((grade) => grade.studentId == student.id) ||
                exams.any((exam) => exam.className == student.className),
          )
          .toList();

      final gradesByStudent = <String, List<Grade>>{};
      for (final grade in grades) {
        gradesByStudent.putIfAbsent(grade.studentId, () => []).add(grade);
      }
      final absencesByStudent = <String, List<Absence>>{};
      for (final absence in absences) {
        absencesByStudent.putIfAbsent(absence.studentId, () => []).add(absence);
      }
      final archiveSchoolInfo = schoolInfo?.copyWith(currentYearId: year.label);

      final builders = <String, Future<Uint8List> Function()>{
        'year_recap': () async {
          final bytes = await ExportService.generateYearRecapPdf(
            yearRecap: year,
            schoolInfo: archiveSchoolInfo ?? schoolInfo,
            languageCode: languageCode,
            returnBytes: true,
          );
          if (bytes == null || bytes.isEmpty) {
            throw StateError('Le PDF du récapitulatif annuel est vide.');
          }
          return bytes;
        },
        'bulletins': () => ExportService.generateYearBulletinsArchivePdf(
          students: studentsWithRecords,
          gradesByStudent: gradesByStudent,
          exams: exams,
          absencesByStudent: absencesByStudent,
          yearLabel: year.label,
          subjects: subjects,
          schoolInfo: archiveSchoolInfo ?? schoolInfo,
          languageCode: languageCode,
        ),
        'receipts': () => ExportService.generateYearReceiptsArchivePdf(
          payments: payments,
          yearRecap: year,
          schoolInfo: archiveSchoolInfo ?? schoolInfo,
          languageCode: languageCode,
        ),
      };

      for (final type in const ['year_recap', 'bulletins', 'receipts']) {
        if (existing.contains(type)) continue;
        final bytes = await builders[type]!();
        if (bytes.isEmpty) {
          throw StateError('Le PDF $type généré est vide.');
        }
        await ApiService.uploadAcademicYearArchive(
          yearId: yearId,
          type: type,
          bytes: bytes,
        );
      }
      existing = await ApiService.getAcademicYearArchives(yearId: yearId);
    }

    if (!_archiveTypes.every(existing.contains)) {
      throw StateError(
        'La sauvegarde complète compressée et les trois PDF ne sont pas tous archivés. Aucune donnée n’a été supprimée.',
      );
    }
    await ApiService.finalizeAcademicYearArchive(yearId);
    return ApiService.getAcademicYearArchives(yearId: yearId);
  }

  static List<Map<String, dynamic>> _yearItems(dynamic value, int yearId) {
    return _mapItems(
      value,
    ).where((item) => _parseInt(item['academicYearId']) == yearId).toList();
  }

  static List<Map<String, dynamic>> _mapItems(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static int? _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
