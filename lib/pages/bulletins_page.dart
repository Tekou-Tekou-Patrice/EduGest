import 'package:flutter/material.dart';
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
  const BulletinsPage({super.key, required this.currentUser});

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
            alertMessage += 'Notes manquantes détectées :\n$missing\n\n';
          }
          if (zeroCoeffs.isNotEmpty) {
            alertMessage += 'Coefficients nuls ou non définis :\n$zeroCoeffs\n\n';
          }
          if (alertMessage.isEmpty) {
            alertMessage = readiness['message']?.toString() ??
                'Toutes les évaluations de la période doivent être notées sans coefficient nul avant de publier.';
          } else {
            alertMessage += 'Veuillez compléter toutes les notes et coefficients avant la publication officielle.';
          }

          if (mounted) {
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Publication Bloquée'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Text(alertMessage, style: const TextStyle(fontSize: 13, height: 1.4)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Compris'),
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
              title: const Row(
                children: [
                  Icon(Icons.verified, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Confirmer la Publication'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voulez-vous publier les bulletins de la classe $_selectedClass pour la période "$_selectedPeriod" ?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '✓ Aucune note manquante détectée.\n'
                    '✓ Tous les coefficients sont valides (> 0).\n'
                    '✓ Les parents d\'élèves seront notifiés et pourront immédiatement consulter et télécharger le bulletin en PDF.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check, size: 18, color: Colors.white),
                  label: const Text('Confirmer & Publier', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
              title: const Text('Retirer la publication ?'),
              content: Text(
                'Voulez-vous masquer les bulletins de la classe $_selectedClass pour la période "$_selectedPeriod" ? Les parents ne pourront plus y accéder.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Retirer', style: TextStyle(color: Colors.white)),
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
          SnackBar(content: Text(_classPublication == null
              ? 'Bulletins retirés de l’espace Parent.'
              : 'Bulletins publiés avec succès : les parents peuvent désormais les consulter et les télécharger.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de modifier la publication : $e')),
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
        className: _selectedClass ?? "Classe",
        schoolInfo: currentSchoolNotifier.value,
        period: _selectedPeriod,
        subjects: _subjects,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur génération des bulletins: $e")),
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
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 20),
          _buildControlBar(isMobile),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_selectedClass == null || _classes.isEmpty)
            _buildEmptyState("Aucune classe configurée dans l'établissement.")
          else if (_students.isEmpty)
            _buildEmptyState(
              "Aucun élève trouvé dans la classe $_selectedClass.",
            )
          else ...[
            _buildClassStatsKpi(isMobile),
            const SizedBox(height: 20),
            if (_selectedStudentForPreview != null)
              _buildStudentPreviewSection(isMobile)
            else
              _buildStudentsList(isMobile),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.assignment,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ValueListenableBuilder<SchoolInfo?>(
              valueListenable: currentSchoolNotifier,
              builder: (context, school, _) {
                final currentYear = school?.currentYearId.isNotEmpty == true
                    ? "Année ${school!.currentYearId}"
                    : "Session en cours";
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Génération des Bulletins Scolaires",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Bulletins officiels avec notes par matière, moyennes pondérées, classement et heures d'absence • $currentYear",
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
              icon: const Icon(Icons.print, size: 18, color: Colors.white),
              label: Text(
                _isExportingAll ? "Génération..." : "Imprimer Toute la Classe",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
      padding: const EdgeInsets.all(16),
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
              const Text(
                "Classe : ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedClass,
                    hint: const Text("Choisir"),
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
              const Text(
                "Période : ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                hintText: "Chercher élève...",
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
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
                    ? 'Mise à jour...'
                    : _classPublication == null
                        ? 'Publier aux parents'
                        : 'Retirer des parents',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _classPublication == null
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),

          if (_classPublication != null)
            Text(
              'Publié par ${_classPublication!.publishedBy}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),

          if (isMobile && _students.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExportingAll ? null : _handlePrintAll,
                icon: const Icon(Icons.print, size: 18, color: Colors.white),
                label: Text(
                  _isExportingAll
                      ? "Génération..."
                      : "Imprimer Tous les Bulletins",
                  style: const TextStyle(color: Colors.white),
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
        padding: const EdgeInsets.all(14),
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
              child: _statMini("Effectif", "${_students.length} élèves", Icons.groups),
            ),
            SizedBox(
              width: 140,
              child: _statMini(
                "Moyenne Classe",
                "${_classGeneralAvg.toStringAsFixed(2)}/20",
                Icons.insights,
              ),
            ),
            SizedBox(
              width: 140,
              child: _statMini(
                "Note Min / Max",
                "${_classMinAvg.toStringAsFixed(1)} - ${_classMaxAvg.toStringAsFixed(1)}",
                Icons.show_chart,
              ),
            ),
            SizedBox(
              width: 140,
              child: _statMini(
                "Examens Inclus",
                "${_exams.length}",
                Icons.assignment_outlined,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statMini("Effectif", "${_students.length} élèves", Icons.groups),
          _statMini(
            "Moyenne Classe",
            "${_classGeneralAvg.toStringAsFixed(2)}/20",
            Icons.insights,
          ),
          _statMini(
            "Note Min / Max",
            "${_classMinAvg.toStringAsFixed(1)} - ${_classMaxAvg.toStringAsFixed(1)}",
            Icons.show_chart,
          ),
          _statMini(
            "Examens Inclus",
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
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
              "Liste des Élèves — Classe de $_selectedClass (${_filteredStudents.length})",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredStudents.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final student = _filteredStudents[index];
            final avg = _averagesByStudent[student.id] ?? 0.0;
            final rank = _ranksByStudent[student.id] ?? (index + 1);
            final absenceHours = _calculateStudentAbsenceHours(student.id);

            if (isMobile) {
              return Container(
                padding: const EdgeInsets.all(14),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Matricule : ${student.id} • Rang : ${rank == 1 ? '1er' : '$rankème'} / ${_students.length}",
                                style: const TextStyle(
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
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
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
                          padding: const EdgeInsets.symmetric(
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
                              const SizedBox(width: 4),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _selectedStudentForPreview = student);
                            },
                            icon: const Icon(Icons.visibility, size: 15),
                            label: const Text("Aperçu", style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handlePrintSingle(student),
                            icon: const Icon(
                              Icons.print,
                              size: 15,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Bulletin PDF",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
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
              padding: const EdgeInsets.all(14),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Matricule : ${student.id} • Rang : ${rank == 1 ? '1er' : '$rankème'} / ${_students.length}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
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
                              padding: const EdgeInsets.symmetric(
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
                                  const SizedBox(width: 4),
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
                  const SizedBox(width: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _selectedStudentForPreview = student);
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text("Aperçu"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _handlePrintSingle(student),
                        icon: const Icon(
                          Icons.print,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
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
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Text(
              "Aperçu du Bulletin — ${student.fullName}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _handlePrintSingle(student),
              icon: const Icon(Icons.print, size: 18, color: Colors.white),
              label: const Text(
                "Télécharger / Imprimer ce Bulletin",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Carte stylisée représentant le bulletin
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              school?.address ?? "Établissement Scolaire",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (school?.phone.isNotEmpty == true)
                              Text(
                                "Tél: ${school!.phone}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
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
                            const Text(
                              "BULLETIN DE NOTES",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              "Session $currentYear • $_selectedPeriod",
                              style: const TextStyle(
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
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Identité élève
              Container(
                padding: const EdgeInsets.all(12),
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
                            "Élève : ${student.fullName}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Matricule : ${student.id} • Classe : ${student.className}",
                            style: const TextStyle(
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
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (student.parentName != null)
                            Text(
                              "Tuteur : ${student.parentName} (${student.parentPhone ?? ''})",
                              style: const TextStyle(
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
              const SizedBox(height: 20),

              // Tableau des notes
              const Text(
                "Détail des Notes & Coefficients :",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: TableBorder.all(
                    color: AppColors.border,
                    width: 1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "Matière",
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
                            "Appréciation",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ..._exams.map((exam) {
                      final Grade? g = sGrades.where((item) => item.examId == exam.id).firstOrNull;
                      final coefficient = _coefficientFor(exam);
                      final hasGrade = g != null;
                      final pts = hasGrade ? (g.score * coefficient).toStringAsFixed(2) : "—";
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              exam.subject,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              "${coefficient % 1 == 0 ? coefficient.toInt() : coefficient}",
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Text(
                                        "Non noté",
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
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              pts,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              hasGrade ? _getAppreciation(g.score) : "En attente",
                              style: TextStyle(
                                fontSize: 12,
                                color: hasGrade ? AppColors.textMuted : Colors.orange.shade700,
                                fontStyle: hasGrade ? FontStyle.normal : FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bilan et Assiduité
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bilan académique
                    Container(
                      padding: const EdgeInsets.all(14),
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
                          const Text(
                            "RÉSULTAT DU TRIMESTRE",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Moyenne Générale :",
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
                          const SizedBox(height: 4),
                          Text(
                            "Rang dans la classe : $rank${rank == 1 ? 'er' : 'ème'} sur ${_students.length} élèves",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Moyenne de classe : ${_classGeneralAvg.toStringAsFixed(2)} | Min : ${_classMinAvg.toStringAsFixed(2)} | Max : ${_classMaxAvg.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Suivi des Absences
                    Container(
                      padding: const EdgeInsets.all(14),
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
                          const Text(
                            "VIE SCOLAIRE & ABSENCES",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total Absences :",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "$absenceHours Heure(s)",
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
                          const SizedBox(height: 4),
                          Text(
                            "Nombre d'incidents enregistrés : ${sAbsences.length}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            absenceHours == 0
                                ? "Assiduité exemplaire"
                                : (absenceHours <= 4
                                      ? "Assiduité satisfaisante"
                                      : "Absences à surveiller"),
                            style: const TextStyle(
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
                        padding: const EdgeInsets.all(14),
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
                            const Text(
                              "RÉSULTAT DU TRIMESTRE",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Moyenne Générale :",
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
                            const SizedBox(height: 4),
                            Text(
                              "Rang dans la classe : $rank${rank == 1 ? 'er' : 'ème'} sur ${_students.length} élèves",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Moyenne de classe : ${_classGeneralAvg.toStringAsFixed(2)} | Min : ${_classMinAvg.toStringAsFixed(2)} | Max : ${_classMaxAvg.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Suivi des Absences
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
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
                            const Text(
                              "VIE SCOLAIRE & ABSENCES",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total Absences :",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "$absenceHours Heure(s)",
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
                            const SizedBox(height: 4),
                            Text(
                              "Nombre d'incidents enregistrés : ${sAbsences.length}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              absenceHours == 0
                                  ? "Assiduité exemplaire"
                                  : (absenceHours <= 4
                                        ? "Assiduité satisfaisante"
                                        : "Absences à surveiller"),
                              style: const TextStyle(
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
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_late_outlined,
            color: AppColors.textMuted,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
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
