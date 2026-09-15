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
  static Future<void> generatePdf({
    required Exam exam,
    required List<Grade> grades,
    required List<Student> students,
  }) async {
    final pdf = pw.Document();
    final studentMap = {for (var s in students) s.id: s.fullName};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader("BORDEREAU DE NOTES"),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Examen : ${exam.title}"),
                    pw.Text("Matière : ${exam.subject}"),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Classe : ${exam.className}"),
                    pw.Text(
                      "Date : ${exam.date.day}/${exam.date.month}/${exam.date.year}",
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
                'Rang',
                'Nom et Prénom de l\'élève',
                'Note / 20',
                'Appréciation',
              ],
              data: List<List<dynamic>>.generate(grades.length, (index) {
                final g = grades[index];
                return [
                  index + 1,
                  studentMap[g.studentId] ?? "Inconnu (${g.studentId})",
                  g.score.toStringAsFixed(2),
                  _getAppreciation(g.score),
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
                      "Moyenne de classe : ${_calculateAverage(grades).toStringAsFixed(2)} / 20",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      "Signature et Cachet de la Direction",
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
      name: 'Bordereau_${exam.title.replaceAll(' ', '_')}.pdf',
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
    String period = "1er Trimestre",
    int? rank,
    int? totalStudents,
    double? classMin,
    double? classMax,
    double? classAvg,
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
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Bulletin_${student.lastName}_${student.firstName}.pdf',
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
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Bulletins_Classe_${className.replaceAll(' ', '_')}.pdf',
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
    String period = "1er Trimestre",
    int? rank,
    int? totalStudents,
    double? classMin,
    double? classMax,
    double? classAvg,
  }) {
    final schoolName =
        schoolInfo?.name ?? currentSchoolNotifier.value?.name ?? "EDUGUEST";
    final schoolAddress =
        schoolInfo?.address ??
        currentSchoolNotifier.value?.address ??
        "Établissement Scolaire";
    final schoolPhone =
        schoolInfo?.phone ?? currentSchoolNotifier.value?.phone ?? "";
    final currentYear =
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
                    "Tél: $schoolPhone",
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
                    "BULLETIN DE NOTES",
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    "Session $currentYear",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    period.toUpperCase(),
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
                          text: "Nom & Prénom : ",
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
                    "Matricule : ${student.id.isNotEmpty ? student.id : 'N/A'} • Classe : ${student.className}",
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (student.birthDate != null)
                    pw.Text(
                      "Né(e) le : ${DateFormat('dd/MM/yyyy').format(student.birthDate!)}",
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                  if (student.parentName != null &&
                      student.parentName!.isNotEmpty)
                    pw.Text(
                      "Parent / Tuteur : ${student.parentName} ${student.parentPhone != null ? '(${student.parentPhone})' : ''}",
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                  if (totalStudents != null)
                    pw.Text(
                      "Effectif de la classe : $totalStudents élèves",
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
                    "Matière",
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
                    "Coeff",
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
                    "Note / 20",
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
                    "Total Pts",
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
                    "Appréciation & Avis du Professeur",
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
                            hasGrade ? g.score.toStringAsFixed(2) : "Non noté",
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
                            hasGrade ? _getAppreciation(g.score) : "En attente",
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
                            _getAppreciation(g.score),
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
                    "TOTAL DES POINTS",
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
                      "BILAN ACADÉMIQUE",
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
                          "MOYENNE GÉNÉRALE :",
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
                            color: generalAvg >= 10
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
                            "Rang de l'élève :",
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                          pw.Text(
                            "$rank${rank == 1 ? 'er' : 'ème'} / ${totalStudents ?? '-'}",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                              color: PdfColors.blueGrey900,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (classAvg != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "Moy. Classe : ${classAvg.toStringAsFixed(2)} | Min : ${classMin?.toStringAsFixed(2) ?? '-'} | Max : ${classMax?.toStringAsFixed(2) ?? '-'}",
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
                      "VIE SCOLAIRE & ASSIDUITÉ",
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
                          "Total Absences :",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9.5,
                          ),
                        ),
                        pw.Text(
                          "$totalAbsenceHours Heure(s)",
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
                      "• Justifiées : $justifiedAbsenceHours h  |  • Non justifiées : $unjustifiedAbsenceHours h",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      totalAbsenceHours == 0
                          ? "Assiduité exemplaire"
                          : (totalAbsenceHours < 6
                                ? "Assiduité normale"
                                : "Attention aux absences répétées"),
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
                    "MENTIONS DU CONSEIL :",
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    generalAvg >= 16
                        ? "[X] Félicitations du Conseil  [ ] Tableau d'Honneur  [ ] Encouragements"
                        : (generalAvg >= 14
                              ? "[ ] Félicitations  [X] Tableau d'Honneur  [ ] Encouragements"
                              : (generalAvg >= 12
                                    ? "[ ] Félicitations  [ ] Tableau d'Honneur  [X] Encouragements"
                                    : "[ ] Tableau d'Honneur  [ ] Avertissement")),
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "Appréciation générale :",
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _getAppreciation(generalAvg),
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
                  "Visa des Parents",
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 25),
                pw.Text(
                  "Signature",
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
                  "Le Professeur Principal",
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 25),
                pw.Text(
                  "Visa",
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
                  "Le Chef d'Établissement",
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 25),
                pw.Text(
                  "Signature et Cachet",
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
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(payment.date);
    final schoolName =
        schoolInfo?.name ?? currentSchoolNotifier.value?.name ?? "EDUGUEST";
    final schoolAddress =
        schoolInfo?.address ??
        currentSchoolNotifier.value?.address ??
        "Établissement Scolaire";
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
                    "Tél: $schoolPhone",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey800,
                    ),
                  ),
                if (currentYear.isNotEmpty)
                  pw.Text(
                    "Année Scolaire $currentYear",
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
                  "REÇU DE PAIEMENT",
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
                  "Date : $dateStr",
                  style: const pw.TextStyle(fontSize: 8),
                ),
                if (payment.recordedByName != null)
                  pw.Text(
                    "Caissier(ère) : ${payment.recordedByName}",
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
                        "ÉLÈVE : ${payment.studentName}",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "MOTIF : ${payment.description}",
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
                        "MONTANT ENCAISSÉ",
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
                              ? "SCOLARITÉ TERMINÉE"
                              : "RESTE À PAYER : ${payment.remaining!.toInt()} FCFA",
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
                  "*** MERCI DE VOTRE PAIEMENT ***",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  "Conservez ce ticket comme justificatif officiel",
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "EduGest POS System",
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
      name: 'Ticket_${payment.studentName.replaceAll(' ', '_')}.pdf',
      format: PdfPageFormat.roll80,
    );
  }

  static Future<void> generatePaymentReceipt(Payment payment) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(payment.date);

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
                _buildHeader("REÇU DE PAIEMENT"),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Reçu N°: ${payment.id.isEmpty ? 'TEMP' : payment.id}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text("Date: $dateStr"),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  "Reçu de : ${payment.studentName}",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "La somme de : ${payment.amount.toInt()} FCFA",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Motif : ${payment.description}",
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                ),
                if (payment.remaining != null) ...[
                  pw.SizedBox(height: 10),
                  pw.Text(
                    payment.tuitionCompleted
                        ? "Scolarité terminée"
                        : "Reste à payer : ${payment.remaining!.toInt()} FCFA",
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
                          "Le Client",
                          style: pw.TextStyle(
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          "La Caisse",
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
      name: 'Recu_${payment.studentName.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildHeader(
    String title, {
    String? schoolName,
    String? academicYear,
  }) {
    final name = (schoolName != null && schoolName.isNotEmpty)
        ? schoolName
        : (currentSchoolNotifier.value?.name.isNotEmpty == true
              ? currentSchoolNotifier.value!.name
              : "EDUGUEST - SYSTÈME DE GESTION");
    final year = (academicYear != null && academicYear.isNotEmpty)
        ? "Année Scolaire $academicYear"
        : (currentSchoolNotifier.value?.currentYearId.isNotEmpty == true
              ? "Année Scolaire ${currentSchoolNotifier.value!.currentYearId}"
              : "Gestion Scolaire");

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

  static String _getAppreciation(double score) {
    if (score >= 16) return "Excellent";
    if (score >= 14) return "Très Bien";
    if (score >= 12) return "Bien";
    if (score >= 10) return "Passable";
    if (score >= 8) return "Médiocre";
    return "Insuffisant";
  }

  static Future<void> generateYearRecapPdf({
    required AcademicYearRecap yearRecap,
    SchoolInfo? schoolInfo,
  }) async {
    final pdf = pw.Document();
    final schoolName = yearRecap.schoolName ?? schoolInfo?.name ?? "EduGest";
    final schoolAddress = schoolInfo?.address ?? "Établissement Scolaire";
    final schoolPhone = schoolInfo?.phone ?? "";
    final schoolEmail = schoolInfo?.email ?? "";

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
                        "Tél: $schoolPhone",
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
                        "RAPPORT ANNUEL",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        "Session : ${yearRecap.label}",
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
                "RÉCAPITULATIF OFFICIEL DE L'ANNÉE SCOLAIRE",
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
                "Période du ${yearRecap.formattedStartDate} au ${yearRecap.formattedEndDate} • Clôturée le ${yearRecap.formattedClosedAt}",
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
                "1. BILAN FINANCIER ET COMPTABLE",
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
                        "Rubrique",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "Montant (FCFA)",
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
                        "Total des Recettes / Frais de scolarité perçus",
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        yearRecap.formattedRevenue,
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
                        "Total des Dépenses de fonctionnement",
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        yearRecap.formattedExpenses,
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
                        "SOLDE NET D'EXERCICE (Recettes - Dépenses)",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        yearRecap.formattedBalance,
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
                "2. EFFECTIFS ET ACTIVITÉ PÉDAGOGIQUE",
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
                        "Indicateur Pédagogique",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "Nombre Total",
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
                        "Nombre d'élèves inscrits",
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
                        "Corps professoral / Enseignants",
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
                        "Séances de cours / Leçons consignées",
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
                        "Évaluations et Examens organisés",
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
                "3. VIE SCOLAIRE ET DISCIPLINE",
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
                        "Type d'enregistrement",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "Total Enregistré",
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
                        "Absences signalées et traitées",
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
                        "Sanctions et mesures disciplinaires",
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
                      "Le Proviseur / Direction",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 35),
                    pw.Text(
                      "Signature et Cachet",
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
                      "La Fondatrice / Administration Générale",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 35),
                    pw.Text(
                      "Visa et Approbation",
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Recap_${yearRecap.label.replaceAll(' ', '_').replaceAll('/', '-')}.pdf',
    );
  }

  static Future<void> generateExcel({
    required Exam exam,
    required List<Grade> grades,
    required List<Student> students,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Notes_${exam.className}'];
    excel.delete('Sheet1');

    sheetObject.appendRow([TextCellValue('EDUGUEST - RAPPORT DE NOTES')]);
    sheetObject.appendRow([
      TextCellValue('Examen: ${exam.title}'),
      TextCellValue('Matière: ${exam.subject}'),
      TextCellValue('Classe: ${exam.className}'),
    ]);
    sheetObject.appendRow([]);

    sheetObject.appendRow([
      TextCellValue('Nom de l\'élève'),
      TextCellValue('Note / 20'),
      TextCellValue('Coefficient'),
      TextCellValue('Note Finale'),
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

    excel.save(fileName: 'Notes_${exam.title.replaceAll(' ', '_')}.xlsx');
  }
}
