import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/grade.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../models/payment.dart';
import '../models/absence.dart';
import '../models/academic_year_recap.dart';
import '../models/school_info.dart';
import '../service/school_notifier.dart';
import 'package:intl/intl.dart';

class ExportService {
  static String _text(String languageCode, String french, String english) =>
      languageCode == 'en' ? english : french;

  static String _periodText(String languageCode, String period) {
    final translations = {
      '1er Trimestre': 'Term 1',
      '2ème Trimestre': 'Term 2',
      '3ème Trimestre': 'Term 3',
      'Bilan Annuel': 'Annual review',
    };
    if (languageCode != 'en') return period;
    if (translations.containsKey(period)) return translations[period]!;
    if (period.startsWith('Séquence ')) {
      return 'Sequence ${period.split(' ').last}';
    }
    return period;
  }

  static String _formattedDate(DateTime? date, String languageCode) {
    if (date == null) return '-';
    final format = languageCode == 'en' ? 'MM/dd/yyyy' : 'dd/MM/yyyy';
    return DateFormat(format, languageCode).format(date);
  }

  static String _formattedAmount(double amount, String languageCode) =>
      '${NumberFormat('#,###', languageCode).format(amount.round())} FCFA';

  static Future<Uint8List> generateYearReceiptsArchivePdf({
    required List<Payment> payments,
    required AcademicYearRecap yearRecap,
    SchoolInfo? schoolInfo,
    String languageCode = 'fr',
  }) async {
    final pdf = pw.Document();
    final sortedPayments = [...payments]
      ..sort((a, b) => a.date.compareTo(b.date));
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(
              _text(languageCode, 'ARCHIVE DES REÇUS', 'RECEIPT ARCHIVE'),
              schoolName: schoolInfo?.name ?? yearRecap.schoolName,
              academicYear: yearRecap.label,
              languageCode: languageCode,
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              '${sortedPayments.length} ${_text(languageCode, 'reçu(s) de paiement', 'payment receipt(s)')}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              '${_text(languageCode, 'Total encaissé', 'Total collected')}: ${_formattedAmount(sortedPayments.fold(0.0, (sum, item) => sum + item.amount), languageCode)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            if (sortedPayments.isEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                _text(
                  languageCode,
                  'Aucun paiement enregistré pour cette année.',
                  'No payments were recorded for this year.',
                ),
              ),
            ],
          ],
        ),
      ),
    );
    for (final payment in sortedPayments) {
      final dateStr = DateFormat(
        languageCode == 'en' ? 'MM/dd/yyyy h:mm a' : 'dd/MM/yyyy HH:mm',
        languageCode,
      ).format(payment.date);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          build: (_) => pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  _text(languageCode, 'REÇU DE PAIEMENT', 'PAYMENT RECEIPT'),
                  schoolName: schoolInfo?.name ?? yearRecap.schoolName,
                  academicYear: yearRecap.label,
                  languageCode: languageCode,
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "${_text(languageCode, 'Reçu N°', 'Receipt No.')} : ${payment.id}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text("${_text(languageCode, 'Date', 'Date')}: $dateStr"),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  "${_text(languageCode, 'Reçu de', 'Received from')} : ${payment.studentName}",
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "${_text(languageCode, 'La somme de', 'Amount')} : ${_formattedAmount(payment.amount, languageCode)}",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "${_text(languageCode, 'Motif', 'Reason')} : ${payment.description}",
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                ),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      _text(languageCode, 'Le Client', 'Customer'),
                      style: pw.TextStyle(
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.Text(
                      _text(languageCode, 'La Caisse', 'Cashier'),
                      style: pw.TextStyle(
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                if (payment.recordedByName != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    payment.recordedByName!,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return pdf.save();
  }

  static Future<Uint8List> generateYearBulletinsArchivePdf({
    required List<Student> students,
    required Map<String, List<Grade>> gradesByStudent,
    required List<Exam> exams,
    required Map<String, List<Absence>> absencesByStudent,
    required String yearLabel,
    List<Subject>? subjects,
    SchoolInfo? schoolInfo,
    String languageCode = 'fr',
  }) async {
    final pdf = pw.Document();
    final effectiveCoefficients = {
      for (final subject in subjects ?? <Subject>[])
        subject.name.trim().toLowerCase(): subject.coefficient,
    };
    final groupedStudents = <String, List<Student>>{};
    for (final student in students) {
      groupedStudents.putIfAbsent(student.className, () => []).add(student);
    }

    if (students.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Text(
              _text(
                languageCode,
                'Aucun élève à archiver pour $yearLabel.',
                'No students to archive for $yearLabel.',
              ),
            ),
          ),
        ),
      );
    }

    for (final classStudents in groupedStudents.values) {
      final averages = <String, double>{
        for (final student in classStudents)
          student.id: _calculateWeightedAverage(
            gradesByStudent[student.id] ?? const [],
            exams,
            subjectCoeffs: effectiveCoefficients,
          ),
      };
      final ranked = [...classStudents]
        ..sort((a, b) => (averages[b.id] ?? 0).compareTo(averages[a.id] ?? 0));
      final classValues = averages.values.toList();
      final classAverage = classValues.isEmpty
          ? 0.0
          : classValues.reduce((a, b) => a + b) / classValues.length;
      final classMin = classValues.isEmpty
          ? 0.0
          : classValues.reduce((a, b) => a < b ? a : b);
      final classMax = classValues.isEmpty
          ? 0.0
          : classValues.reduce((a, b) => a > b ? a : b);

      for (final student in ranked) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            build: (_) => _buildBulletinWidget(
              student: student,
              grades: gradesByStudent[student.id] ?? const [],
              exams: exams,
              absences: absencesByStudent[student.id] ?? const [],
              subjects: subjects,
              schoolInfo: schoolInfo,
              academicYearLabel: yearLabel,
              period: 'Bilan Annuel',
              rank: ranked.indexOf(student) + 1,
              totalStudents: ranked.length,
              classMin: classMin,
              classMax: classMax,
              classAvg: classAverage,
              languageCode: languageCode,
            ),
          ),
        );
      }
    }
    return pdf.save();
  }

  static Future<void> generatePdf({
    required Exam exam,
    required List<Grade> grades,
    required List<Student> students,
    String languageCode = 'fr',
  }) async {
    final pdf = pw.Document();
    final studentMap = {for (var s in students) s.id: s.fullName};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(
              _text(languageCode, "BORDEREAU DE NOTES", "GRADE REPORT"),
              languageCode: languageCode,
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${_text(languageCode, 'Examen', 'Exam')} : ${exam.title}",
                    ),
                    pw.Text(
                      "${_text(languageCode, 'Matière', 'Subject')} : ${exam.subject}",
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${_text(languageCode, 'Classe', 'Class')} : ${exam.className}",
                    ),
                    pw.Text(
                      "${_text(languageCode, 'Date', 'Date')} : ${_formattedDate(exam.date, languageCode)}",
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 25),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey,
              ),
              headers: [
                _text(languageCode, 'Rang', 'Rank'),
                _text(
                  languageCode,
                  'Nom et Prénom de l\'élève',
                  'Student name',
                ),
                _text(languageCode, 'Note / 20', 'Grade / 20'),
                _text(languageCode, 'Appréciation', 'Comment'),
              ],
              data: List<List<dynamic>>.generate(grades.length, (index) {
                final g = grades[index];
                return [
                  index + 1,
                  studentMap[g.studentId] ??
                      "${_text(languageCode, 'Inconnu', 'Unknown')} (${g.studentId})",
                  g.score.toStringAsFixed(2),
                  _getAppreciation(g.score, languageCode),
                ];
              }),
            ),
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${_text(languageCode, 'Moyenne de classe', 'Class average')} : ${_calculateAverage(grades).toStringAsFixed(2)} / 20",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      _text(
                        languageCode,
                        "Signature et Cachet de la Direction",
                        "Management signature and stamp",
                      ),
                      style: pw.TextStyle(
                        decoration: pw.TextDecoration.underline,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          '${_text(languageCode, 'Bordereau', 'Grade_Report')}_${exam.title.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<void> generateBulletinPdf({
    required Student student,
    required List<Grade> grades,
    required List<Exam> exams,
    List<Absence> absences = const [],
    List<Subject>? subjects,
    Map<String, double>? subjectCoefficients,
    SchoolInfo? schoolInfo,
    String? academicYearLabel,
    String period = "1er Trimestre",
    int? rank,
    int? totalStudents,
    double? classMin,
    double? classMax,
    double? classAvg,
    double promotionThreshold = 10,
    String? promotionTargetClassName,
    String? reportClassName,
    String languageCode = 'fr',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return _buildBulletinWidget(
            student: student,
            grades: grades,
            exams: exams,
            absences: absences,
            subjects: subjects,
            subjectCoefficients: subjectCoefficients,
            schoolInfo: schoolInfo,
            period: period,
            rank: rank,
            totalStudents: totalStudents,
            classMin: classMin,
            classMax: classMax,
            classAvg: classAvg,
            promotionThreshold: promotionThreshold,
            promotionTargetClassName: promotionTargetClassName,
            reportClassName: reportClassName,
            languageCode: languageCode,
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          '${_text(languageCode, 'Bulletin', 'Report_Card')}_${student.lastName}_${student.firstName}.pdf',
    );
  }

  static Future<void> generateAllClassBulletinsPdf({
    required List<Student> students,
    required Map<String, List<Grade>> gradesByStudent,
    required List<Exam> exams,
    required Map<String, List<Absence>> absencesByStudent,
    required String className,
    List<Subject>? subjects,
    Map<String, double>? subjectCoefficients,
    SchoolInfo? schoolInfo,
    String period = "1er Trimestre",
    double promotionThreshold = 10,
    String? promotionTargetClassName,
    String languageCode = 'fr',
  }) async {
    final pdf = pw.Document();

    final Map<String, double> effectiveCoeffs = {};
    if (subjectCoefficients != null) {
      effectiveCoeffs.addAll(subjectCoefficients);
    }
    if (subjects != null) {
      for (var s in subjects) {
        effectiveCoeffs[s.name.trim().toLowerCase()] = s.coefficient;
      }
    }

    // Calcul des moyennes pour le classement
    final Map<String, double> averages = {};
    for (var s in students) {
      final sGrades = gradesByStudent[s.id] ?? [];
      averages[s.id] = _calculateWeightedAverage(
        sGrades,
        exams,
        subjectCoeffs: effectiveCoeffs,
      );
    }

    final sortedStudentIds = students.map((s) => s.id).toList()
      ..sort((a, b) => (averages[b] ?? 0).compareTo(averages[a] ?? 0));

    final validAverages = averages.values.where((v) => v > 0).toList();
    final double classMin = validAverages.isNotEmpty
        ? validAverages.reduce((a, b) => a < b ? a : b)
        : 0;
    final double classMax = validAverages.isNotEmpty
        ? validAverages.reduce((a, b) => a > b ? a : b)
        : 0;
    final double classAvg = validAverages.isNotEmpty
        ? validAverages.reduce((a, b) => a + b) / validAverages.length
        : 0;

    for (var student in students) {
      final studentGrades = gradesByStudent[student.id] ?? [];
      final studentAbsences = absencesByStudent[student.id] ?? [];
      final rank = sortedStudentIds.indexOf(student.id) + 1;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (pw.Context context) {
            return _buildBulletinWidget(
              student: student,
              grades: studentGrades,
              exams: exams,
              absences: studentAbsences,
              subjects: subjects,
              subjectCoefficients: effectiveCoeffs,
              schoolInfo: schoolInfo,
              period: period,
              rank: rank,
              totalStudents: students.length,
              classMin: classMin,
              classMax: classMax,
              classAvg: classAvg,
              promotionThreshold: promotionThreshold,
              promotionTargetClassName: promotionTargetClassName,
              reportClassName: className,
              languageCode: languageCode,
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          '${_text(languageCode, 'Bulletins_Classe', 'Class_Report_Cards')}_${className.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildBulletinWidget({
    required Student student,
    required List<Grade> grades,
    required List<Exam> exams,
    required List<Absence> absences,
    List<Subject>? subjects,
    Map<String, double>? subjectCoefficients,
    SchoolInfo? schoolInfo,
    String? academicYearLabel,
    String period = "1er Trimestre",
    int? rank,
    int? totalStudents,
    double? classMin,
    double? classMax,
    double? classAvg,
    double promotionThreshold = 10,
    String? promotionTargetClassName,
    String? reportClassName,
    String languageCode = 'fr',
  }) {
    final schoolName =
        schoolInfo?.name ?? currentSchoolNotifier.value?.name ?? "EDUGUEST";
    final schoolAddress =
        schoolInfo?.address ??
        currentSchoolNotifier.value?.address ??
        _text(languageCode, "Établissement Scolaire", "School");
    final schoolPhone =
        schoolInfo?.phone ?? currentSchoolNotifier.value?.phone ?? "";
    final currentYear =
        academicYearLabel ??
        schoolInfo?.currentYearId ??
        currentSchoolNotifier.value?.currentYearId ??
        "2024-2025";

    // Calcul des heures d'absence
    int totalAbsenceHours = 0;
    int justifiedAbsenceHours = 0;
    int unjustifiedAbsenceHours = 0;

    for (var abs in absences) {
      int hours = 2; // Valeur par défaut
      final p = abs.period.toLowerCase();
      if (p.contains('1h') || p.contains('1 heure')) {
        hours = 1;
      } else if (p.contains('2h') || p.contains('2 heures')) {
        hours = 2;
      } else if (p.contains('3h') || p.contains('3 heures')) {
        hours = 3;
      } else if (p.contains('4h') ||
          p.contains('matin') ||
          p.contains('après-midi') ||
          p.contains('apres-midi')) {
        hours = 4;
      } else if (p.contains('8h') || p.contains('jour')) {
        hours = 8;
      } else {
        final match = RegExp(r'(\d+)\s*h').firstMatch(p);
        if (match != null) {
          hours = int.tryParse(match.group(1)!) ?? 2;
        }
      }
      totalAbsenceHours += hours;
      if (abs.isJustified) {
        justifiedAbsenceHours += hours;
      } else {
        unjustifiedAbsenceHours += hours;
      }
    }

    final Map<String, double> effectiveCoeffs = {};
    if (subjectCoefficients != null) {
      effectiveCoeffs.addAll(subjectCoefficients);
    }
    if (subjects != null) {
      for (var s in subjects) {
        effectiveCoeffs[s.name.trim().toLowerCase()] = s.coefficient;
      }
    }

    double totalPoints = 0;
    double totalCoeffs = 0;
    for (var g in grades) {
      final exam = exams.firstWhere(
        (e) => e.id == g.examId,
        orElse: () => Exam(
          id: '',
          title: '',
          subject: '',
          className: '',
          date: DateTime.now(),
          coefficient: 1,
        ),
      );
      final coef =
          effectiveCoeffs[exam.subject.trim().toLowerCase()] ??
          (exam.coefficient > 0 ? exam.coefficient : 1.0);
      totalPoints += (g.score * coef);
      totalCoeffs += coef;
    }
    final generalAvg = totalCoeffs > 0 ? totalPoints / totalCoeffs : 0.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Entête Officiel de l'établissement
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  schoolName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  schoolAddress,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
                if (schoolPhone.isNotEmpty)
                  pw.Text(
                    "${_text(languageCode, 'Tél', 'Phone')}: $schoolPhone",
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue700, width: 1),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _text(languageCode, "BULLETIN DE NOTES", "REPORT CARD"),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    "${_text(languageCode, 'Session', 'School year')} $currentYear",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    _periodText(languageCode, period).toUpperCase(),
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 1, color: PdfColors.grey400),
        pw.SizedBox(height: 8),

        // Carte d'identité de l'élève
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text:
                              "${_text(languageCode, 'Nom & Prénom', 'Name')} : ",
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.TextSpan(
                          text: student.fullName,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    "${_text(languageCode, 'Matricule', 'Student ID')} : ${student.id.isNotEmpty ? student.id : 'N/A'} • ${_text(languageCode, 'Classe', 'Class')} : ${reportClassName ?? student.className}",
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (student.birthDate != null)
                    pw.Text(
                      "${_text(languageCode, 'Né(e) le', 'Date of birth')} : ${DateFormat(languageCode == 'en' ? 'MM/dd/yyyy' : 'dd/MM/yyyy', languageCode).format(student.birthDate!)}",
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                  if (student.parentName != null &&
                      student.parentName!.isNotEmpty)
                    pw.Text(
                      "${_text(languageCode, 'Parent / Tuteur', 'Parent / Guardian')} : ${student.parentName} ${student.parentPhone != null ? '(${student.parentPhone})' : ''}",
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                  if (totalStudents != null)
                    pw.Text(
                      "${_text(languageCode, 'Effectif de la classe', 'Class size')} : $totalStudents ${_text(languageCode, 'élèves', 'students')}",
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // Tableau des Notes et Matières
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    _text(languageCode, "Matière", "Subject"),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 8.5,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    _text(languageCode, "Coeff", "Coeff."),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 8.5,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    _text(languageCode, "Note / 20", "Grade / 20"),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 8.5,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    _text(languageCode, "Total Pts", "Total points"),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 8.5,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    _text(
                      languageCode,
                      "Appréciation & Avis du Professeur",
                      "Teacher's comment",
                    ),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 8.5,
                    ),
                  ),
                ),
              ],
            ),
            ...(exams.isNotEmpty
                ? exams.map((exam) {
                    final Grade? g = grades
                        .where((gr) => gr.examId == exam.id)
                        .firstOrNull;
                    final coef =
                        effectiveCoeffs[exam.subject.trim().toLowerCase()] ??
                        (exam.coefficient > 0 ? exam.coefficient : 1.0);
                    final hasGrade = g != null;
                    final points = hasGrade
                        ? (g.score * coef).toStringAsFixed(2)
                        : "-";
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4.5),
                          child: pw.Text(
                            exam.subject,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4.5),
                          child: pw.Text(
                            "${coef % 1 == 0 ? coef.toInt() : coef}",
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4.5),
                          child: pw.Text(
                            hasGrade
                                ? g.score.toStringAsFixed(2)
                                : _text(languageCode, "Non noté", "Not graded"),
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: hasGrade
                                  ? PdfColors.black
                                  : PdfColors.orange800,
                              fontStyle: hasGrade
                                  ? pw.FontStyle.normal
                                  : pw.FontStyle.italic,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4.5),
                          child: pw.Text(
                            points,
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4.5),
                          child: pw.Text(
                            hasGrade
                                ? _getAppreciation(g.score, languageCode)
                                : _text(languageCode, "En attente", "Pending"),
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ),
                      ],
                    );
                  })
                : grades.map((g) {
                    final exam = exams.firstWhere(
                      (e) => e.id == g.examId,
                      orElse: () => Exam(
                        id: '',
                        title: 'N/A',
                        subject: 'N/A',
                        className: '',
                        date: DateTime.now(),
                      ),
                    );
                    final coef =
                        effectiveCoeffs[exam.subject.trim().toLowerCase()] ??
                        (exam.coefficient > 0 ? exam.coefficient : 1.0);
                    final points = g.score * coef;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4.5),
                          child: pw.Text(
                            exam.subject,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4.5),
                          child: pw.Text(
                            "${coef % 1 == 0 ? coef.toInt() : coef}",
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4.5),
                          child: pw.Text(
                            g.score.toStringAsFixed(2),
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4.5),
                          child: pw.Text(
                            points.toStringAsFixed(2),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4.5),
                          child: pw.Text(
                            _getAppreciation(g.score, languageCode),
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ),
                      ],
                    );
                  })),
            // Ligne de Total
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    _text(languageCode, "TOTAL DES POINTS", "TOTAL POINTS"),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8.5,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    "${totalCoeffs % 1 == 0 ? totalCoeffs.toInt() : totalCoeffs.toStringAsFixed(1)}",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8.5,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text("-", textAlign: pw.TextAlign.center),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    totalPoints.toStringAsFixed(2),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8.5,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(""),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),

        // Synthèse des Résultats & Assiduité / Absences
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Volet Moyenne et Classement
            pw.Expanded(
              flex: 5,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue700, width: 1),
                  borderRadius: pw.BorderRadius.circular(6),
                  color: PdfColors.blue50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _text(
                        languageCode,
                        "BILAN ACADÉMIQUE",
                        "ACADEMIC SUMMARY",
                      ),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          _text(
                            languageCode,
                            "MOYENNE GÉNÉRALE :",
                            "OVERALL AVERAGE:",
                          ),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          "${generalAvg.toStringAsFixed(2)} / 20",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color:
                                generalAvg >=
                                    (period == 'Bilan Annuel'
                                        ? promotionThreshold
                                        : 10)
                                ? PdfColors.green800
                                : PdfColors.red800,
                          ),
                        ),
                      ],
                    ),
                    if (rank != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            _text(
                              languageCode,
                              "Rang de l'élève :",
                              "Student rank:",
                            ),
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                          pw.Text(
                            languageCode == 'en'
                                ? "$rank${_englishOrdinalSuffix(rank)} / ${totalStudents ?? '-'}"
                                : "$rank${rank == 1 ? 'er' : 'ème'} / ${totalStudents ?? '-'}",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                              color: PdfColors.blueGrey900,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (period == 'Bilan Annuel' &&
                        promotionTargetClassName != null &&
                        promotionTargetClassName.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        generalAvg >= promotionThreshold
                            ? _text(
                                languageCode,
                                'Admis en $promotionTargetClassName (seuil : ${promotionThreshold.toStringAsFixed(2)}/20).',
                                'Promoted to $promotionTargetClassName (threshold: ${promotionThreshold.toStringAsFixed(2)}/20).',
                              )
                            : _text(
                                languageCode,
                                'Redouble (seuil requis : ${promotionThreshold.toStringAsFixed(2)}/20).',
                                'Repeats the class (required: ${promotionThreshold.toStringAsFixed(2)}/20).',
                              ),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8.5,
                          color: generalAvg >= promotionThreshold
                              ? PdfColors.green800
                              : PdfColors.red800,
                        ),
                      ),
                    ],
                    if (classAvg != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "${_text(languageCode, 'Moy. Classe', 'Class avg.')} : ${classAvg.toStringAsFixed(2)} | Min : ${classMin?.toStringAsFixed(2) ?? '-'} | Max : ${classMax?.toStringAsFixed(2) ?? '-'}",
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 10),

            // Volet Assiduité & Heures d'Absences
            pw.Expanded(
              flex: 5,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: totalAbsenceHours > 10
                        ? PdfColors.orange700
                        : PdfColors.grey400,
                    width: 1,
                  ),
                  borderRadius: pw.BorderRadius.circular(6),
                  color: totalAbsenceHours > 10
                      ? PdfColors.orange50
                      : PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _text(
                        languageCode,
                        "VIE SCOLAIRE & ASSIDUITÉ",
                        "ATTENDANCE",
                      ),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          _text(
                            languageCode,
                            "Total Absences :",
                            "Total absences:",
                          ),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9.5,
                          ),
                        ),
                        pw.Text(
                          "$totalAbsenceHours ${_text(languageCode, 'Heure(s)', 'hour(s)')}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: totalAbsenceHours > 10
                                ? PdfColors.deepOrange800
                                : PdfColors.blueGrey900,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "• ${_text(languageCode, 'Justifiées', 'Excused')}: $justifiedAbsenceHours h  |  • ${_text(languageCode, 'Non justifiées', 'Unexcused')}: $unjustifiedAbsenceHours h",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      totalAbsenceHours == 0
                          ? _text(
                              languageCode,
                              "Assiduité exemplaire",
                              "Excellent attendance",
                            )
                          : (totalAbsenceHours < 6
                                ? _text(
                                    languageCode,
                                    "Assiduité normale",
                                    "Good attendance",
                                  )
                                : _text(
                                    languageCode,
                                    "Attention aux absences répétées",
                                    "Frequent absences",
                                  )),
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),

        // Tableau de décision & Distinctions
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _text(
                      languageCode,
                      "MENTIONS DU CONSEIL :",
                      "CLASS COUNCIL DECISION:",
                    ),
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    generalAvg >= 16
                        ? _text(
                            languageCode,
                            "[X] Félicitations du Conseil  [ ] Tableau d'Honneur  [ ] Encouragements",
                            "[X] Congratulations  [ ] Honor Roll  [ ] Encouragement",
                          )
                        : (generalAvg >= 14
                              ? _text(
                                  languageCode,
                                  "[ ] Félicitations  [X] Tableau d'Honneur  [ ] Encouragements",
                                  "[ ] Congratulations  [X] Honor Roll  [ ] Encouragement",
                                )
                              : (generalAvg >= 12
                                    ? _text(
                                        languageCode,
                                        "[ ] Félicitations  [ ] Tableau d'Honneur  [X] Encouragements",
                                        "[ ] Congratulations  [ ] Honor Roll  [X] Encouragement",
                                      )
                                    : _text(
                                        languageCode,
                                        "[ ] Tableau d'Honneur  [ ] Avertissement",
                                        "[ ] Honor Roll  [ ] Warning",
                                      ))),
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _text(
                      languageCode,
                      "Appréciation générale :",
                      "Overall comment:",
                    ),
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _getAppreciation(generalAvg, languageCode),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Signatures et Visas
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _text(languageCode, "Visa des Parents", "Parent's signature"),
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 25),
                pw.Text(
                  _text(languageCode, "Signature", "Signature"),
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  _text(
                    languageCode,
                    "Le Professeur Principal",
                    "Head Teacher",
                  ),
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 25),
                pw.Text(
                  _text(languageCode, "Visa", "Approval"),
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  _text(
                    languageCode,
                    "Le Chef d'Établissement",
                    "Head of School",
                  ),
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 25),
                pw.Text(
                  _text(
                    languageCode,
                    "Signature et Cachet",
                    "Signature and stamp",
                  ),
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- REÇUS DE PAIEMENT (THERMIQUE 80MM & STANDARD A5) ---

  static Future<void> generateThermalReceipt({
    required Payment payment,
    SchoolInfo? schoolInfo,
    String languageCode = 'fr',
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat(
      languageCode == 'en' ? 'MM/dd/yyyy h:mm a' : 'dd/MM/yyyy HH:mm',
      languageCode,
    ).format(payment.date);
    final schoolName =
        schoolInfo?.name ?? currentSchoolNotifier.value?.name ?? "EDUGUEST";
    final schoolAddress =
        schoolInfo?.address ??
        currentSchoolNotifier.value?.address ??
        _text(languageCode, "Établissement Scolaire", "School");
    final schoolPhone =
        schoolInfo?.phone ?? currentSchoolNotifier.value?.phone ?? "";
    final currentYear =
        schoolInfo?.currentYearId ??
        currentSchoolNotifier.value?.currentYearId ??
        "";

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // En-tête école
                pw.Text(
                  schoolName.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (schoolAddress.isNotEmpty)
                  pw.Text(
                    schoolAddress,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey800,
                    ),
                  ),
                if (schoolPhone.isNotEmpty)
                  pw.Text(
                    "${_text(languageCode, 'Tél', 'Phone')}: $schoolPhone",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey800,
                    ),
                  ),
                if (currentYear.isNotEmpty)
                  pw.Text(
                    "${_text(languageCode, 'Année Scolaire', 'School year')} $currentYear",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                pw.SizedBox(height: 6),
                pw.Text(
                  "--------------------------------------------------",
                  style: const pw.TextStyle(fontSize: 7),
                ),
                pw.SizedBox(height: 2),

                pw.Text(
                  _text(languageCode, "REÇU DE PAIEMENT", "PAYMENT RECEIPT"),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                pw.Text(
                  "TICKET N°: ${payment.id.isEmpty ? 'AUTO' : payment.id}",
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "${_text(languageCode, 'Date', 'Date')} : $dateStr",
                  style: const pw.TextStyle(fontSize: 8),
                ),
                if (payment.recordedByName != null)
                  pw.Text(
                    "${_text(languageCode, 'Caissier(ère)', 'Cashier')} : ${payment.recordedByName}",
                    style: const pw.TextStyle(fontSize: 8),
                  ),

                pw.SizedBox(height: 6),
                pw.Text(
                  "--------------------------------------------------",
                  style: const pw.TextStyle(fontSize: 7),
                ),
                pw.SizedBox(height: 4),

                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "${_text(languageCode, 'ÉLÈVE', 'STUDENT')} : ${payment.studentName}",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "${_text(languageCode, 'MOTIF', 'REASON')} : ${payment.description}",
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 8),
                pw.Text(
                  "=================================",
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 4),

                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1.2),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        _text(languageCode, "MONTANT ENCAISSÉ", "AMOUNT PAID"),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "${payment.amount.toInt()} FCFA",
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (payment.remaining != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          payment.tuitionCompleted
                              ? _text(
                                  languageCode,
                                  "SCOLARITÉ TERMINÉE",
                                  "TUITION PAID",
                                )
                              : "${_text(languageCode, 'RESTE À PAYER', 'BALANCE DUE')} : ${payment.remaining!.toInt()} FCFA",
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: payment.tuitionCompleted
                                ? PdfColors.green
                                : PdfColors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                pw.SizedBox(height: 6),
                pw.Text(
                  "=================================",
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 6),

                pw.Text(
                  _text(
                    languageCode,
                    "*** MERCI DE VOTRE PAIEMENT ***",
                    "*** THANK YOU FOR YOUR PAYMENT ***",
                  ),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _text(
                    languageCode,
                    "Conservez ce ticket comme justificatif officiel",
                    "Keep this receipt as official proof of payment",
                  ),
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _text(
                    languageCode,
                    "Système de caisse EduGest",
                    "EduGest POS system",
                  ),
                  style: const pw.TextStyle(
                    fontSize: 6,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          '${_text(languageCode, 'Ticket', 'Receipt')}_${payment.studentName.replaceAll(' ', '_')}.pdf',
      format: PdfPageFormat.roll80,
    );
  }

  static Future<void> generatePaymentReceipt(
    Payment payment, {
    String languageCode = 'fr',
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat(
      languageCode == 'en' ? 'MM/dd/yyyy h:mm a' : 'dd/MM/yyyy HH:mm',
      languageCode,
    ).format(payment.date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  _text(languageCode, "REÇU DE PAIEMENT", "PAYMENT RECEIPT"),
                  languageCode: languageCode,
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "${_text(languageCode, 'Reçu N°', 'Receipt No.')} : ${payment.id.isEmpty ? 'TEMP' : payment.id}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text("${_text(languageCode, 'Date', 'Date')}: $dateStr"),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  "${_text(languageCode, 'Reçu de', 'Received from')} : ${payment.studentName}",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "${_text(languageCode, 'La somme de', 'Amount')} : ${payment.amount.toInt()} FCFA",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "${_text(languageCode, 'Motif', 'Reason')} : ${payment.description}",
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                ),
                if (payment.remaining != null) ...[
                  pw.SizedBox(height: 10),
                  pw.Text(
                    payment.tuitionCompleted
                        ? _text(
                            languageCode,
                            "Scolarité terminée",
                            "Tuition paid",
                          )
                        : "${_text(languageCode, 'Reste à payer', 'Balance due')} : ${payment.remaining!.toInt()} FCFA",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: payment.tuitionCompleted
                          ? PdfColors.green
                          : PdfColors.red,
                    ),
                  ),
                ],
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          _text(languageCode, "Le Client", "Customer"),
                          style: pw.TextStyle(
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          _text(languageCode, "La Caisse", "Cashier"),
                          style: pw.TextStyle(
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                        if (payment.recordedByName != null)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 5),
                            child: pw.Text(
                              payment.recordedByName!,
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          '${_text(languageCode, 'Recu', 'Receipt')}_${payment.studentName.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildHeader(
    String title, {
    String? schoolName,
    String? academicYear,
    String languageCode = 'fr',
  }) {
    final name = (schoolName != null && schoolName.isNotEmpty)
        ? schoolName
        : (currentSchoolNotifier.value?.name.isNotEmpty == true
              ? currentSchoolNotifier.value!.name
              : _text(
                  languageCode,
                  "EDUGUEST - SYSTÈME DE GESTION",
                  "EDUGUEST - MANAGEMENT SYSTEM",
                ));
    final year = (academicYear != null && academicYear.isNotEmpty)
        ? "${_text(languageCode, 'Année Scolaire', 'School year')} $academicYear"
        : (currentSchoolNotifier.value?.currentYearId.isNotEmpty == true
              ? "${_text(languageCode, 'Année Scolaire', 'School year')} ${currentSchoolNotifier.value!.currentYearId}"
              : _text(languageCode, "Gestion Scolaire", "School Management"));

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              name.toUpperCase(),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(year, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static double _calculateAverage(List<Grade> grades) {
    if (grades.isEmpty) return 0;
    return grades.map((g) => g.score).reduce((a, b) => a + b) / grades.length;
  }

  static double _calculateWeightedAverage(
    List<Grade> grades,
    List<Exam> exams, {
    Map<String, double>? subjectCoeffs,
  }) {
    if (grades.isEmpty) return 0;
    double totalPoints = 0;
    double totalCoeffs = 0;
    for (var g in grades) {
      final exam = exams.firstWhere(
        (e) => e.id == g.examId,
        orElse: () => Exam(
          id: '',
          title: '',
          subject: '',
          className: '',
          date: DateTime.now(),
          coefficient: 1,
        ),
      );
      final coef =
          subjectCoeffs?[exam.subject.trim().toLowerCase()] ??
          (exam.coefficient > 0 ? exam.coefficient : 1.0);
      totalPoints += (g.score * coef);
      totalCoeffs += coef;
    }
    return totalCoeffs == 0 ? 0 : totalPoints / totalCoeffs;
  }

  static String _getAppreciation(double score, String languageCode) {
    if (score >= 16) return "Excellent";
    if (score >= 14) return _text(languageCode, "Très Bien", "Very Good");
    if (score >= 12) return _text(languageCode, "Bien", "Good");
    if (score >= 10) return _text(languageCode, "Passable", "Satisfactory");
    if (score >= 8) return _text(languageCode, "Médiocre", "Poor");
    return _text(languageCode, "Insuffisant", "Insufficient");
  }

  static String _englishOrdinalSuffix(int rank) {
    final lastTwoDigits = rank % 100;
    if (lastTwoDigits >= 11 && lastTwoDigits <= 13) return 'th';
    return switch (rank % 10) {
      1 => 'st',
      2 => 'nd',
      3 => 'rd',
      _ => 'th',
    };
  }

  static Future<Uint8List?> generateYearRecapPdf({
    required AcademicYearRecap yearRecap,
    SchoolInfo? schoolInfo,
    String languageCode = 'fr',
    bool returnBytes = false,
  }) async {
    final pdf = pw.Document();
    final schoolName = yearRecap.schoolName ?? schoolInfo?.name ?? "EduGest";
    final schoolAddress =
        schoolInfo?.address ??
        _text(languageCode, "Établissement Scolaire", "School");
    final schoolPhone = schoolInfo?.phone ?? "";
    final schoolEmail = schoolInfo?.email ?? "";
    final startDate = _formattedDate(yearRecap.startDate, languageCode);
    final endDate = _formattedDate(yearRecap.endDate, languageCode);
    final closedAt = yearRecap.closedAt == null
        ? endDate
        : DateFormat(
            languageCode == 'en' ? 'MM/dd/yyyy h:mm a' : 'dd/MM/yyyy HH:mm',
            languageCode,
          ).format(yearRecap.closedAt!);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Entête officiel de l'école
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      schoolName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      schoolAddress,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    if (schoolPhone.isNotEmpty)
                      pw.Text(
                        "${_text(languageCode, 'Tél', 'Phone')}: $schoolPhone",
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    if (schoolEmail.isNotEmpty)
                      pw.Text(
                        "Email: $schoolEmail",
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    border: pw.Border.all(color: PdfColors.green700, width: 1),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        _text(languageCode, "RAPPORT ANNUEL", "ANNUAL REPORT"),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        "${_text(languageCode, 'Session', 'School year')} : ${yearRecap.label}",
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey400, thickness: 1),
            pw.SizedBox(height: 14),

            // Titre du Document
            pw.Center(
              child: pw.Text(
                _text(
                  languageCode,
                  "RÉCAPITULATIF OFFICIEL DE L'ANNÉE SCOLAIRE",
                  "OFFICIAL SCHOOL YEAR SUMMARY",
                ),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                "${_text(languageCode, 'Période du', 'Period from')} $startDate ${_text(languageCode, 'au', 'to')} $endDate • ${_text(languageCode, 'Clôturée le', 'Closed on')} $closedAt",
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Section 1 : BILAN FINANCIER
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              color: PdfColors.blueGrey100,
              child: pw.Text(
                _text(
                  languageCode,
                  "1. BILAN FINANCIER ET COMPTABLE",
                  "1. FINANCIAL SUMMARY",
                ),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(languageCode, "Rubrique", "Category"),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(languageCode, "Montant (FCFA)", "Amount (FCFA)"),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(
                          languageCode,
                          "Total des Recettes / Frais de scolarité perçus",
                          "Total revenue / tuition collected",
                        ),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _formattedAmount(yearRecap.totalRevenue, languageCode),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(
                          languageCode,
                          "Total des Dépenses de fonctionnement",
                          "Total operating expenses",
                        ),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _formattedAmount(yearRecap.totalExpenses, languageCode),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey50),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(
                          languageCode,
                          "SOLDE NET D'EXERCICE (Recettes - Dépenses)",
                          "NET BALANCE (Revenue - Expenses)",
                        ),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _formattedAmount(yearRecap.balance, languageCode),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: yearRecap.balance >= 0
                              ? PdfColors.green800
                              : PdfColors.red800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // Section 2 : STATISTIQUES PÉDAGOGIQUES
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              color: PdfColors.blueGrey100,
              child: pw.Text(
                _text(
                  languageCode,
                  "2. EFFECTIFS ET ACTIVITÉ PÉDAGOGIQUE",
                  "2. ENROLLMENT AND ACADEMIC ACTIVITY",
                ),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(
                          languageCode,
                          "Indicateur Pédagogique",
                          "Academic indicator",
                        ),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(languageCode, "Nombre Total", "Total"),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(
                          languageCode,
                          "Nombre d'élèves inscrits",
                          "Enrolled students",
                        ),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "${yearRecap.studentCount}",
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(
                          languageCode,
                          "Corps professoral / Enseignants",
                          "Teaching staff",
                        ),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "${yearRecap.teacherCount}",
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(
                          languageCode,
                          "Séances de cours / Leçons consignées",
                          "Lessons recorded",
                        ),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "${yearRecap.lessonCount}",
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(
                          languageCode,
                          "Évaluations et Examens organisés",
                          "Assessments and exams held",
                        ),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "${yearRecap.examCount}",
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // Section 3 : VIE SCOLAIRE & DISCIPLINE
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              color: PdfColors.blueGrey100,
              child: pw.Text(
                _text(
                  languageCode,
                  "3. VIE SCOLAIRE ET DISCIPLINE",
                  "3. SCHOOL LIFE AND DISCIPLINE",
                ),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(
                          languageCode,
                          "Type d'enregistrement",
                          "Record type",
                        ),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(
                          languageCode,
                          "Total Enregistré",
                          "Total recorded",
                        ),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(
                          languageCode,
                          "Absences signalées et traitées",
                          "Absences reported and processed",
                        ),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "${yearRecap.absenceCount}",
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _text(
                          languageCode,
                          "Sanctions et mesures disciplinaires",
                          "Disciplinary measures",
                        ),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "${yearRecap.sanctionCount}",
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 35),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _text(
                        languageCode,
                        "Le Proviseur / Direction",
                        "Principal / Management",
                      ),
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 35),
                    pw.Text(
                      _text(
                        languageCode,
                        "Signature et Cachet",
                        "Signature and stamp",
                      ),
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      _text(
                        languageCode,
                        "La Fondatrice / Administration Générale",
                        "Founder / General Administration",
                      ),
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 35),
                    pw.Text(
                      _text(languageCode, "Visa et Approbation", "Approval"),
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    if (returnBytes) return bytes;
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name:
          'Recap_${yearRecap.label.replaceAll(' ', '_').replaceAll('/', '-')}.pdf',
    );
    return null;
  }

  static Future<void> generateExcel({
    required Exam exam,
    required List<Grade> grades,
    required List<Student> students,
    String languageCode = 'fr',
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject =
        excel['${_text(languageCode, 'Notes', 'Grades')}_${exam.className}'];
    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue(
        _text(
          languageCode,
          'EDUGUEST - RAPPORT DE NOTES',
          'EDUGUEST - GRADE REPORT',
        ),
      ),
    ]);
    sheetObject.appendRow([
      TextCellValue('${_text(languageCode, 'Examen', 'Exam')}: ${exam.title}'),
      TextCellValue(
        '${_text(languageCode, 'Matière', 'Subject')}: ${exam.subject}',
      ),
      TextCellValue(
        '${_text(languageCode, 'Classe', 'Class')}: ${exam.className}',
      ),
    ]);
    sheetObject.appendRow([]);

    sheetObject.appendRow([
      TextCellValue(_text(languageCode, 'Nom de l\'élève', 'Student name')),
      TextCellValue(_text(languageCode, 'Note / 20', 'Grade / 20')),
      TextCellValue(_text(languageCode, 'Coefficient', 'Coefficient')),
      TextCellValue(_text(languageCode, 'Note Finale', 'Final grade')),
    ]);

    final studentMap = {for (var s in students) s.id: s.fullName};
    for (var g in grades) {
      sheetObject.appendRow([
        TextCellValue(studentMap[g.studentId] ?? g.studentId),
        DoubleCellValue(g.score),
        DoubleCellValue(exam.coefficient),
        DoubleCellValue(g.score * exam.coefficient),
      ]);
    }

    excel.save(
      fileName:
          '${_text(languageCode, 'Notes', 'Grades')}_${exam.title.replaceAll(' ', '_')}.xlsx',
    );
  }
}
