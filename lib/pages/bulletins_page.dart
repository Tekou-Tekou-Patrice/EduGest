import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'package:intl/intl.dart';
import '../components/app_colors.dart';
import '../components/responsive_layout.dart';
import '../models/absence.dart';
import '../models/app_user.dart';
import '../models/grade.dart';
import '../models/school_class.dart';
import '../models/school_info.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../models/bulletin_publication.dart';
import '../service/api_service.dart';
import '../service/export_service.dart';
import '../service/school_notifier.dart';

class BulletinsPage extends StatefulWidget {
  final AppUser currentUser;
  BulletinsPage({super.key, required this.currentUser});

  @override
  State<BulletinsPage> createState() => _BulletinsPageState();
}

class _BulletinsPageState extends State<BulletinsPage> {
  bool _isLoading = true;
  bool _isExportingAll = false;

  List<SchoolClass> _classes = [];
  String? _selectedClass;
  String _selectedPeriod = "1er Trimestre";

  List<Student> _students = [];
  List<Exam> _exams = [];
  List<Subject> _subjects = [];
  Map<String, List<Grade>> _gradesByStudent = {};
  Map<String, List<Absence>> _absencesByStudent = {};
  Map<String, double> _averagesByStudent = {};
  Map<String, int> _ranksByStudent = {};

  double _classMinAvg = 0;
  double _classMaxAvg = 0;
  double _classGeneralAvg = 0;

  Student? _selectedStudentForPreview;
  String _searchQuery = '';
  BulletinPublication? _classPublication;
  bool _isPublishing = false;

  bool get _canPublishBulletins =>
      widget.currentUser.role == UserRole.fondateur ||
      widget.currentUser.role == UserRole.proviseur ||
      widget.currentUser.role == UserRole.secretaire;

  Map<String, double> get _subjectCoefficients => {
    for (final subject in _subjects)
      subject.name.trim().toLowerCase(): subject.coefficient,
  };

  double _coefficientFor(Exam exam) =>
      _subjectCoefficients[exam.subject.trim().toLowerCase()] ??
      (exam.coefficient > 0 ? exam.coefficient : 1.0);

  final List<String> _periods = [
    "1er Trimestre",
    "2ème Trimestre",
    "3ème Trimestre",
    "Séquence 1",
    "Séquence 2",
    "Séquence 3",
    "Séquence 4",
    "Séquence 5",
    "Séquence 6",
    "Bilan Annuel",
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getClassrooms(),
        ApiService.getSubjects(),
      ]);
      final classes = results[0] as List<SchoolClass>;
      _classes = classes;
      _subjects = results[1] as List<Subject>;

      if (_classes.isNotEmpty) {
        _selectedClass = _classes.first.name;
        await _fetchClassData();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Erreur chargement classes: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchClassData() async {
    if (_selectedClass == null) return;
    setState(() => _isLoading = true);

    try {
      final students = await ApiService.getStudents(className: _selectedClass);
      final exams = await ApiService.getExams(className: _selectedClass);
      final absences = await ApiService.getAbsences(className: _selectedClass);

      // Récupération des notes pour tous les examens de la classe
      final Map<String, List<Grade>> gradesMap = {
        for (var s in students) s.id: [],
      };

      for (var exam in exams) {
        try {
          final examGrades = await ApiService.getGradesByExam(exam.id);
          for (var g in examGrades) {
            if (gradesMap.containsKey(g.studentId)) {
              gradesMap[g.studentId]!.add(g);
            }
          }
        } catch (_) {}
      }

      // Groupement des absences par élève
      final Map<String, List<Absence>> absencesMap = {
        for (var s in students) s.id: [],
      };
      for (var abs in absences) {
        if (absencesMap.containsKey(abs.studentId)) {
          absencesMap[abs.studentId]!.add(abs);
        }
      }

      // Calcul des moyennes
      final Map<String, double> avgs = {};
      for (var s in students) {
        final sGrades = gradesMap[s.id] ?? [];
        double points = 0;
        double coeffs = 0;
        for (var g in sGrades) {
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
          final coefficient = _coefficientFor(exam);
          points += g.score * coefficient;
          coeffs += coefficient;
        }
        avgs[s.id] = coeffs > 0 ? (points / coeffs) : 0.0;
      }

      // Calcul du classement (rang)
      final sortedStudents = List<Student>.from(students)
        ..sort((a, b) => (avgs[b.id] ?? 0).compareTo(avgs[a.id] ?? 0));

      final Map<String, int> ranks = {};
      for (int i = 0; i < sortedStudents.length; i++) {
        ranks[sortedStudents[i].id] = i + 1;
      }

      // Moyennes min, max, générale de classe
      final validAvgs = avgs.values.where((v) => v > 0).toList();
      final minAvg = validAvgs.isNotEmpty
          ? validAvgs.reduce((a, b) => a < b ? a : b)
          : 0.0;
      final maxAvg = validAvgs.isNotEmpty
          ? validAvgs.reduce((a, b) => a > b ? a : b)
          : 0.0;
      final genAvg = validAvgs.isNotEmpty
          ? (validAvgs.reduce((a, b) => a + b) / validAvgs.length)
          : 0.0;

      if (mounted) {
        setState(() {
          _students = students;
          _exams = exams;
          _gradesByStudent = gradesMap;
          _absencesByStudent = absencesMap;
          _averagesByStudent = avgs;
          _ranksByStudent = ranks;
          _classMinAvg = minAvg;
          _classMaxAvg = maxAvg;
          _classGeneralAvg = genAvg;
          if (_selectedStudentForPreview != null) {
            _selectedStudentForPreview = students.firstWhere(
              (s) => s.id == _selectedStudentForPreview!.id,
              orElse: () => students.isNotEmpty
                  ? students.first
                  : _selectedStudentForPreview!,
            );
          }
          _isLoading = false;
        });
        await _loadPublicationStatus();
      }
    } catch (e) {
      debugPrint("Erreur récupération données classe: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPublicationStatus() async {
    if (_selectedClass == null) return;
    final publication = await ApiService.getBulletinPublicationStatus(
      className: _selectedClass!,
      period: _selectedPeriod,
    );
    if (mounted) setState(() => _classPublication = publication);
  }

  Future<void> _toggleClassPublication() async {
    if (!_canPublishBulletins || _selectedClass == null) return;
    setState(() => _isPublishing = true);
    try {
      if (_classPublication == null) {
        final readiness = await ApiService.getBulletinReadiness(
          className: _selectedClass!,
          period: _selectedPeriod,
        );
        if (readiness['ready'] != true) {
          final missing = (readiness['missing'] as List? ?? [])
              .take(10)
              .map((item) => '• ${item['studentName']} — ${item['subject']}')
              .join('\n');
          final zeroCoeffs = (readiness['zeroCoefficients'] as List? ?? [])
              .take(6)
              .map((item) => '• $item')
              .join('\n');

          String alertMessage = '';
          if (missing.isNotEmpty) {
            alertMessage +=
                '${context.tr('missingGradesDetected')}:\n$missing\n\n';
          }
          if (zeroCoeffs.isNotEmpty) {
            alertMessage +=
                '${context.tr('invalidCoefficients')}:\n$zeroCoeffs\n\n';
          }
          if (alertMessage.isEmpty) {
            alertMessage =
                readiness['message']?.toString() ??
                context.tr('allGradesRequiredBeforePublish');
          } else {
            alertMessage += context.tr('completeGradesBeforePublish');
          }

          if (mounted) {
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text(context.tr('publicationBlocked')),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Text(
                    alertMessage,
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('understood')),
                  ),
                ],
              ),
            );
          }
          return;
        }

        // Critères validés -> Demande explicite de confirmation (Point 3)
        if (mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green),
                  SizedBox(width: 8),
                  Text(context.tr('confirmPublication')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      'auto_voulez_vous_publier_les_bulletins_de_la_classe_s',
                    ),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '✓ ${context.tr('noMissingGrades')}.\n'
                    '✓ ${context.tr('validCoefficients')}.\n'
                    '✓ ${context.tr('parentsNotifiedBulletin')}',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.tr('cancel')),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: Icon(Icons.check, size: 18, color: Colors.white),
                  label: Text(
                    context.tr('confirmAndPublish'),
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          );

          if (confirmed != true) return;
        }

        await ApiService.publishBulletin(
          className: _selectedClass!,
          period: _selectedPeriod,
          publishedBy: widget.currentUser.name,
          publishedByRole: widget.currentUser.displayRole,
        );
      } else {
        // Demande de confirmation pour retirer la publication
        if (mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(context.tr('auto_retirer_la_publication')),
              content: Text(
                context.tr(
                  'auto_voulez_vous_masquer_les_bulletins_de_la_classe_s',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(
                    context.tr('remove'),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );

          if (confirmed != true) return;
        }

        await ApiService.unpublishBulletin(
          className: _selectedClass!,
          period: _selectedPeriod,
        );
      }
      await _loadPublicationStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _classPublication == null
                  ? context.tr('bulletinsUnpublished')
                  : context.tr('bulletinsPublished'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('publicationUpdateError')} $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  int _calculateStudentAbsenceHours(String studentId) {
    final list = _absencesByStudent[studentId] ?? [];
    int total = 0;
    for (var abs in list) {
      int hours = 2;
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
      total += hours;
    }
    return total;
  }

  List<Student> get _filteredStudents {
    if (_searchQuery.trim().isEmpty) return _students;
    final q = _searchQuery.toLowerCase().trim();
    return _students
        .where((s) => s.fullName.toLowerCase().contains(q) || s.id.contains(q))
        .toList();
  }

  Future<void> _handlePrintAll() async {
    if (_students.isEmpty) return;
    setState(() => _isExportingAll = true);
    try {
      await ExportService.generateAllClassBulletinsPdf(
        students: _students,
        gradesByStudent: _gradesByStudent,
        exams: _exams,
        absencesByStudent: _absencesByStudent,
        className: _selectedClass ?? context.tr('classLabel'),
        schoolInfo: currentSchoolNotifier.value,
        period: _selectedPeriod,
        subjects: _subjects,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('bulletinGenerationError')} $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingAll = false);
    }
  }

  Future<void> _handlePrintSingle(Student student) async {
    try {
      await ExportService.generateBulletinPdf(
        student: student,
        grades: _gradesByStudent[student.id] ?? [],
        exams: _exams,
        absences: _absencesByStudent[student.id] ?? [],
        schoolInfo: currentSchoolNotifier.value,
        period: _selectedPeriod,
        subjects: _subjects,
        rank: _ranksByStudent[student.id],
        totalStudents: _students.length,
        classMin: _classMinAvg,
        classMax: _classMaxAvg,
        classAvg: _classGeneralAvg,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur impression bulletin: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          SizedBox(height: 20),
          _buildControlBar(isMobile),
          SizedBox(height: 20),

          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_selectedClass == null || _classes.isEmpty)
            _buildEmptyState(context.tr('noClassesConfigured'))
          else if (_students.isEmpty)
            _buildEmptyState(
              "${context.tr('noStudentsInClassPrefix')} $_selectedClass.",
            )
          else ...[
            _buildClassStatsKpi(isMobile),
            SizedBox(height: 20),
            if (_selectedStudentForPreview != null)
              _buildStudentPreviewSection(isMobile)
            else
              _buildStudentsList(isMobile),
          ],
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.assignment, color: AppColors.primary, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ValueListenableBuilder<SchoolInfo?>(
              valueListenable: currentSchoolNotifier,
              builder: (context, school, _) {
                final currentYear = school?.currentYearId.isNotEmpty == true
                    ? "${context.tr('academicYear')} ${school!.currentYearId}"
                    : context.tr('currentSession');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('reportCardGeneration'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${context.tr('officialReportCardsDescription')} • $currentYear",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (!isMobile && _students.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _isExportingAll ? null : _handlePrintAll,
              icon: Icon(Icons.print, size: 18, color: Colors.white),
              label: Text(
                _isExportingAll
                    ? context.tr('generationInProgress')
                    : context.tr('printEntireClass'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Sélecteur de Classe
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Classe : ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedClass,
                    hint: Text("Choisir"),
                    items: _classes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.name,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedClass = val;
                          _selectedStudentForPreview = null;
                        });
                        _fetchClassData();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          // Sélecteur de Période / Trimestre
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Période : ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    items: _periods
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPeriod = val);
                        _loadPublicationStatus();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          // Recherche
          SizedBox(
            width: isMobile ? double.infinity : 220,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                isDense: true,
                hintText: context.tr('searchStudent'),
                prefixIcon: Icon(Icons.search, size: 18),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          if (_canPublishBulletins && _selectedClass != null)
            ElevatedButton.icon(
              onPressed: _isPublishing ? null : _toggleClassPublication,
              icon: Icon(
                _classPublication == null
                    ? Icons.publish_outlined
                    : Icons.unpublished_outlined,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                _isPublishing
                    ? context.tr('updateInProgress')
                    : _classPublication == null
                    ? context.tr('publishToParents')
                    : context.tr('removeFromParents'),
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _classPublication == null
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),

          if (_classPublication != null)
            Text(
              '${context.tr('publishedBy')} ${_classPublication!.publishedBy}',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),

          if (isMobile && _students.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExportingAll ? null : _handlePrintAll,
                icon: Icon(Icons.print, size: 18, color: Colors.white),
                label: Text(
                  _isExportingAll
                      ? context.tr('generationInProgress')
                      : context.tr('printAllReportCards'),
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassStatsKpi(bool isMobile) {
    if (isMobile) {
      return Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryPale,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceAround,
          children: [
            SizedBox(
              width: 140,
              child: _statMini(
                context.tr('studentCount'),
                "${_students.length} ${context.tr('students').toLowerCase()}",
                Icons.groups,
              ),
            ),
            SizedBox(
              width: 140,
              child: _statMini(
                context.tr('classAverage'),
                "${_classGeneralAvg.toStringAsFixed(2)}/20",
                Icons.insights,
              ),
            ),
            SizedBox(
              width: 140,
              child: _statMini(
                context.tr('minMaxGrade'),
                "${_classMinAvg.toStringAsFixed(1)} - ${_classMaxAvg.toStringAsFixed(1)}",
                Icons.show_chart,
              ),
            ),
            SizedBox(
              width: 140,
              child: _statMini(
                context.tr('includedExams'),
                "${_exams.length}",
                Icons.assignment_outlined,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statMini(
            context.tr('studentCount'),
            "${_students.length} ${context.tr('students').toLowerCase()}",
            Icons.groups,
          ),
          _statMini(
            context.tr('classAverage'),
            "${_classGeneralAvg.toStringAsFixed(2)}/20",
            Icons.insights,
          ),
          _statMini(
            context.tr('minMaxGrade'),
            "${_classMinAvg.toStringAsFixed(1)} - ${_classMaxAvg.toStringAsFixed(1)}",
            Icons.show_chart,
          ),
          _statMini(
            context.tr('includedExams'),
            "${_exams.length}",
            Icons.assignment_outlined,
          ),
        ],
      ),
    );
  }

  Widget _statMini(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildStudentsList(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${context.tr('studentList')} — ${context.tr('classLabel')} "
              "$_selectedClass (${_filteredStudents.length})",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _filteredStudents.length,
          separatorBuilder: (_, _) => SizedBox(height: 10),
          itemBuilder: (context, index) {
            final student = _filteredStudents[index];
            final avg = _averagesByStudent[student.id] ?? 0.0;
            final rank = _ranksByStudent[student.id] ?? (index + 1);
            final absenceHours = _calculateStudentAbsenceHours(student.id);

            if (isMobile) {
              return Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryPale,
                          child: Text(
                            "$rank",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                "${context.tr('studentId')} : ${student.id} • "
                                "${context.tr('rank')} : ${rank == 1 ? '1er' : '$rankème'} / ${_students.length}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: avg >= 10
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: avg >= 10
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                            ),
                          ),
                          child: Text(
                            "Moyenne : ${avg.toStringAsFixed(2)} / 20",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: avg >= 10
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: absenceHours > 6
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: absenceHours > 6
                                  ? Colors.orange.shade300
                                  : Colors.blue.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 12,
                                color: absenceHours > 6
                                    ? Colors.deepOrange
                                    : Colors.blue,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "$absenceHours h d'absence",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: absenceHours > 6
                                      ? Colors.deepOrange
                                      : Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(
                                () => _selectedStudentForPreview = student,
                              );
                            },
                            icon: Icon(Icons.visibility, size: 15),
                            label: Text(
                              context.tr('preview'),
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handlePrintSingle(student),
                            icon: Icon(
                              Icons.print,
                              size: 15,
                              color: Colors.white,
                            ),
                            label: Text(
                              "Bulletin PDF",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryPale,
                    child: Text(
                      "$rank",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "${context.tr('studentId')} : ${student.id} • "
                          "${context.tr('rank')} : ${rank == 1 ? '1er' : '$rankème'} / ${_students.length}",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: avg >= 10
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: avg >= 10
                                      ? Colors.green.shade300
                                      : Colors.red.shade300,
                                ),
                              ),
                              child: Text(
                                "Moyenne : ${avg.toStringAsFixed(2)} / 20",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: avg >= 10
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: absenceHours > 6
                                    ? Colors.orange.shade50
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: absenceHours > 6
                                      ? Colors.orange.shade300
                                      : Colors.blue.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 12,
                                    color: absenceHours > 6
                                        ? Colors.deepOrange
                                        : Colors.blue,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "$absenceHours h d'absence",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: absenceHours > 6
                                          ? Colors.deepOrange
                                          : Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _selectedStudentForPreview = student);
                        },
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text(context.tr('preview')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _handlePrintSingle(student),
                        icon: Icon(Icons.print, size: 16, color: Colors.white),
                        label: Text(
                          "Bulletin PDF",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStudentPreviewSection(bool isMobile) {
    final student = _selectedStudentForPreview!;
    final sGrades = _gradesByStudent[student.id] ?? [];
    final sAbsences = _absencesByStudent[student.id] ?? [];
    final avg = _averagesByStudent[student.id] ?? 0.0;
    final rank = _ranksByStudent[student.id] ?? 1;
    final absenceHours = _calculateStudentAbsenceHours(student.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              onPressed: () =>
                  setState(() => _selectedStudentForPreview = null),
              icon: Icon(Icons.arrow_back, color: AppColors.primary),
            ),
            SizedBox(width: 8),
            Text(
              "${context.tr('reportCardPreview')} — ${student.fullName}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _handlePrintSingle(student),
              icon: Icon(Icons.print, size: 18, color: Colors.white),
              label: Text(
                context.tr('downloadPrintReportCard'),
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Carte stylisée représentant le bulletin
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header école
              ValueListenableBuilder<SchoolInfo?>(
                valueListenable: currentSchoolNotifier,
                builder: (context, school, _) {
                  final schoolName = school?.name.isNotEmpty == true
                      ? school!.name
                      : "EduGest";
                  final currentYear = school?.currentYearId.isNotEmpty == true
                      ? school!.currentYearId
                      : "2024-2025";
                  return Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 260,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schoolName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              school?.address ?? context.tr('schoolLabel'),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (school?.phone.isNotEmpty == true)
                              Text(
                                "${context.tr('contactPhone')}: ${school!.phone}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPale,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "BULLETIN DE NOTES",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              "Session $currentYear • $_selectedPeriod",
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 12),

              // Identité élève
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 260,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${context.tr('studentName')} : ${student.fullName}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "${context.tr('studentId')} : ${student.id} • "
                            "${context.tr('classLabel')} : ${student.className}",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (student.birthDate != null)
                            Text(
                              "Date de Naissance : ${DateFormat('dd/MM/yyyy').format(student.birthDate!)}",
                              style: TextStyle(fontSize: 12),
                            ),
                          if (student.parentName != null)
                            Text(
                              "Tuteur : ${student.parentName} (${student.parentPhone ?? ''})",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Tableau des notes
              Text(
                context.tr('gradesAndCoefficients'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: IntrinsicColumnWidth(),
                  border: TableBorder.all(
                    color: AppColors.border,
                    width: 1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            context.tr('subject'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "Coeff",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "Note / 20",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "Total Pts",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            context.tr('appreciation'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ..._exams.map((exam) {
                      final Grade? g = sGrades
                          .where((item) => item.examId == exam.id)
                          .firstOrNull;
                      final coefficient = _coefficientFor(exam);
                      final hasGrade = g != null;
                      final pts = hasGrade
                          ? (g.score * coefficient).toStringAsFixed(2)
                          : "—";
                      return TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              exam.subject,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              "${coefficient % 1 == 0 ? coefficient.toInt() : coefficient}",
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: hasGrade
                                ? Text(
                                    g.score.toStringAsFixed(2),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: g.score >= 10
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  )
                                : Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        context.tr('notGraded'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(pts, textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              hasGrade
                                  ? _getAppreciation(g.score)
                                  : "En attente",
                              style: TextStyle(
                                fontSize: 12,
                                color: hasGrade
                                    ? AppColors.textMuted
                                    : Colors.orange.shade700,
                                fontStyle: hasGrade
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Bilan et Assiduité
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bilan académique
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('termResult'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.tr('overallAverage'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "${avg.toStringAsFixed(2)} / 20",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: avg >= 10
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            "${context.tr('classRank')} : $rank${rank == 1 ? 'er' : 'ème'} "
                            "${context.tr('outOf')} ${_students.length} ${context.tr('students').toLowerCase()}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Moyenne de classe : ${_classGeneralAvg.toStringAsFixed(2)} | Min : ${_classMinAvg.toStringAsFixed(2)} | Max : ${_classMaxAvg.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14),

                    // Suivi des Absences
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: absenceHours > 6
                            ? Colors.orange.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: absenceHours > 6
                              ? Colors.orange.shade300
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "VIE SCOLAIRE & ABSENCES",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.text,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.tr('totalAbsences'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "$absenceHours ${context.tr('hours')}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: absenceHours > 6
                                      ? Colors.deepOrange
                                      : Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            "${context.tr('recordedIncidents')}: ${sAbsences.length}",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            absenceHours == 0
                                ? context.tr('excellentAttendance')
                                : (absenceHours <= 4
                                      ? context.tr('satisfactoryAttendance')
                                      : context.tr(
                                          'attendanceNeedsMonitoring',
                                        )),
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bilan académique
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPale,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('termResult'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr('overallAverage'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "${avg.toStringAsFixed(2)} / 20",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: avg >= 10
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${context.tr('classRank')} : $rank${rank == 1 ? 'er' : 'ème'} "
                              "${context.tr('outOf')} ${_students.length} ${context.tr('students').toLowerCase()}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${context.tr('classAverage')}: ${_classGeneralAvg.toStringAsFixed(2)} | "
                              "${context.tr('min')}: ${_classMinAvg.toStringAsFixed(2)} | "
                              "${context.tr('max')}: ${_classMaxAvg.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),

                    // Suivi des Absences
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: absenceHours > 6
                              ? Colors.orange.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: absenceHours > 6
                                ? Colors.orange.shade300
                                : Colors.blue.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('schoolLifeAndAbsences'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.text,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr('totalAbsences'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "$absenceHours ${context.tr('hours')}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: absenceHours > 6
                                        ? Colors.deepOrange
                                        : Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${context.tr('recordedIncidents')}: ${sAbsences.length}",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              absenceHours == 0
                                  ? context.tr('excellentAttendance')
                                  : (absenceHours <= 4
                                        ? context.tr('satisfactoryAttendance')
                                        : context.tr(
                                            'attendanceNeedsMonitoring',
                                          )),
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_late_outlined,
            color: AppColors.textMuted,
            size: 40,
          ),
          SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _getAppreciation(double score) {
    if (score >= 16) return "Excellent";
    if (score >= 14) return "Très Bien";
    if (score >= 12) return "Bien";
    if (score >= 10) return "Passable";
    if (score >= 8) return "Médiocre";
    return "Insuffisant";
  }
}
