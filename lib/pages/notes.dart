import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../models/student.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../models/grade.dart';
import '../service/api_service.dart';
import '../service/export_service.dart';

class Notes extends StatefulWidget {
  final AppUser? currentUser;
  const Notes({super.key, this.currentUser});

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? selectedClasse;
  String? selectedSubject;
  String selectedSequence = 'Séquence 1';

  List<Student> _students = [];
  List<SchoolClass> _allClasses = [];
  List<Subject> _originalSubjects = [];
  List<Subject> _availableSubjects = [];
  List<Exam> _historyExams = [];
  List<dynamic> _teacherSchedule = [];

  Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isHistoryLoading = false;

  bool get _canWriteGrades => widget.currentUser?.role == UserRole.enseignant;

  final List<String> sequences = [
    'Séquence 1',
    'Séquence 2',
    'Séquence 3',
    'Séquence 4',
    'Séquence 5',
    'Séquence 6',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _historyExams.isEmpty) {
        _fetchHistory();
      }
    });
    _loadInitialData();
    if (!_canWriteGrades) _fetchHistory();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getClassrooms(),
        ApiService.getSubjects(),
      ]);

      _allClasses = results[0] as List<SchoolClass>;
      _originalSubjects = results[1] as List<Subject>;

      if (widget.currentUser?.role == UserRole.enseignant) {
        _teacherSchedule = await ApiService.getSchedule(
          teacherName: widget.currentUser!.name,
        );
        final assignedClasses = _teacherSchedule
            .map((item) => item.className)
            .toSet();
        _allClasses = _allClasses
            .where((c) => assignedClasses.contains(c.name))
            .toList();
      }

      if (_allClasses.isNotEmpty) {
        selectedClasse = _allClasses.first.name;
        _updateAvailableSubjects();
        await _fetchStudents();
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateAvailableSubjects() {
    if (widget.currentUser?.role == UserRole.enseignant) {
      final subjectsForClass = _teacherSchedule
          .where((item) => item.className == selectedClasse)
          .map((item) => item.subject)
          .toSet();
      _availableSubjects = _originalSubjects
          .where((s) => subjectsForClass.contains(s.name))
          .toList();
    } else {
      _availableSubjects = List.from(_originalSubjects);
    }

    if (_availableSubjects.isNotEmpty) {
      if (selectedSubject == null ||
          !_availableSubjects.any((s) => s.name == selectedSubject)) {
        selectedSubject = _availableSubjects.first.name;
      }
    } else {
      selectedSubject = null;
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isHistoryLoading = true);
    try {
      final data = await ApiService.getExams(
        teacherName: widget.currentUser?.role == UserRole.enseignant
            ? widget.currentUser!.name
            : null,
      );
      if (mounted) {
        setState(() {
          _historyExams = data;
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isHistoryLoading = false);
    }
  }

  Future<void> _fetchStudents() async {
    if (selectedClasse == null) return;
    try {
      final data = await ApiService.getStudents(className: selectedClasse);
      if (mounted) {
        setState(() {
          _students = data;
          _controllers = {for (var s in data) s.id: TextEditingController()};
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement élèves: $e");
    }
  }

  void _showExportDialog(Exam exam) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final grades = await ApiService.getGradesByExam(exam.id);
      final students = await ApiService.getStudents(className: exam.className);

      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Options : ${exam.title}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Matière: ${exam.subject} | Classe: ${exam.className}"),
              const SizedBox(height: 16),
              const Text("Voulez-vous télécharger le bordereau ?"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () => ExportService.generatePdf(
                exam: exam,
                grades: grades,
                students: students,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.table_view, color: Colors.green),
              onPressed: () => ExportService.generateExcel(
                exam: exam,
                grades: grades,
                students: students,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors du chargement des détails"),
          ),
        );
      }
    }
  }

  Future<void> _editGrades(Exam exam) async {
    if (!_canWriteGrades) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seuls les enseignants peuvent modifier les notes.'),
        ),
      );
      return;
    }
    if (!exam.editable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cette saisie est verrouillée après 7 jours."),
        ),
      );
      return;
    }
    final grades = await ApiService.getGradesByExam(exam.id);
    if (!mounted) return;
    final controllers = {
      for (final grade in grades)
        grade.id: TextEditingController(text: grade.score.toString()),
    };
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Modifier les notes — ${exam.subject}"),
        content: SizedBox(
          width: (MediaQuery.sizeOf(context).width - 80).clamp(280.0, 420.0),
          child: ListView(
            shrinkWrap: true,
            children: grades
                .map(
                  (grade) => ListTile(
                    title: Text("Élève ${grade.studentId}"),
                    trailing: SizedBox(
                      width: 80,
                      child: TextField(
                        controller: controllers[grade.id],
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              for (final grade in grades) {
                final score = double.tryParse(
                  controllers[grade.id]!.text.replaceAll(',', '.'),
                );
                if (score != null) {
                  await ApiService.updateGrade(
                    Grade(
                      id: grade.id,
                      studentId: grade.studentId,
                      examId: grade.examId,
                      score: score,
                      observations: grade.observations,
                    ),
                  );
                }
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _fetchHistory();
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> _submitGrades() async {
    if (!_canWriteGrades) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seuls les enseignants peuvent envoyer des notes.'),
        ),
      );
      return;
    }
    if (selectedSubject == null || selectedClasse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez choisir une classe et une matière"),
        ),
      );
      return;
    }

    final gradesData = {
      'classe': selectedClasse,
      'subject': selectedSubject,
      'sequence': selectedSequence,
      if (widget.currentUser?.role == UserRole.enseignant)
        'teacherName': widget.currentUser!.name,
      'grades': _controllers.map(
        (id, controller) => MapEntry(id, controller.text),
      ),
    };

    setState(() => _isLoading = true);
    try {
      await ApiService.submitGrades(gradesData);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notes enregistrées avec succès !")),
        );
        _fetchHistory();
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'enregistrement")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canWriteGrades) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aperçu des notes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consultation uniquement : la saisie et la modification sont réservées aux enseignants.',
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _buildHistoryView(),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gestion des Notes",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 20),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Saisie"),
            Tab(text: "Historique"),
          ],
        ),
        const SizedBox(height: 25),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: TabBarView(
            controller: _tabController,
            children: [_buildSaisieView(), _buildHistoryView()],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView() {
    if (_isHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historyExams.isEmpty) {
      return const Center(child: Text("Aucun historique disponible."));
    }

    return ListView.builder(
      itemCount: _historyExams.length,
      itemBuilder: (context, index) {
        final exam = _historyExams[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: AppColors.border),
          ),
          elevation: 0,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primaryPale,
              child: Icon(Icons.history, color: AppColors.primary),
            ),
            title: Text(
              exam.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${exam.subject} • ${exam.className} • ${DateFormat('dd/MM/yyyy').format(exam.date)}'
              '${exam.teacherName?.trim().isNotEmpty == true ? ' • Envoyé par ${exam.teacherName}' : ''}',
            ),
            isThreeLine: exam.teacherName?.trim().isNotEmpty == true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_canWriteGrades)
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: exam.editable ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () => _editGrades(exam),
                    tooltip: exam.editable
                        ? "Modifier (7 jours)"
                        : "Modification verrouillée",
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.file_download_outlined,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _showExportDialog(exam),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaisieView() {
    if (_isLoading && _allClasses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildDropdown(
                "Classe",
                selectedClasse,
                _allClasses.map((c) => c.name).toList(),
                (v) {
                  setState(() {
                    selectedClasse = v;
                    _updateAvailableSubjects();
                  });
                  _fetchStudents();
                },
              ),
              _buildDropdown(
                "Matière",
                selectedSubject,
                _availableSubjects.map((s) => s.name).toList(),
                (v) {
                  setState(() => selectedSubject = v);
                },
              ),
              _buildDropdown(
                "Période",
                selectedSequence,
                sequences,
                (v) => setState(() => selectedSequence = v!),
              ),
            ],
          ),
          const SizedBox(height: 30),
          if (_students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(
                "Aucun élève inscrit en '$selectedClasse'",
                style: const TextStyle(color: Colors.red),
              ),
            )
          else ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _students.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = _students[index];
                  return ListTile(
                    title: Text(s.fullName),
                    subtitle: Text(
                      "ID: ${s.id}",
                      style: const TextStyle(fontSize: 10),
                    ),
                    trailing: SizedBox(
                      width: 70,
                      child: TextField(
                        controller: _controllers[s.id],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "00",
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: MyButton(
                icon: Icons.send,
                text: "Valider et Envoyer",
                onTap: _submitGrades,
              ),
            ),
            const SizedBox(height: 50),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? val,
    List<String> items,
    Function(String?) onChange,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: val,
        hint: Text(label),
        underline: const SizedBox(),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChange,
      ),
    );
  }
}
