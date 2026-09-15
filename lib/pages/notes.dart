import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
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
  Notes({super.key, this.currentUser});

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

  Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isHistoryLoading = false;
  String? _loadError;
  String? _studentsError;

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
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getClassrooms(),
        ApiService.getSubjects(),
      ]);
      _allClasses = results[0] as List<SchoolClass>;
      _originalSubjects = results[1] as List<Subject>;

      if (_allClasses.isNotEmpty) {
        selectedClasse = _allClasses.first.name;
        _updateAvailableSubjects();
        await _fetchStudents();
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Erreur chargement notes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = ApiService.friendlyErrorMessage(e);
        });
      }
    }
  }

  void _updateAvailableSubjects() {
    _availableSubjects = List.from(_originalSubjects);

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
      final data = await ApiService.getExams();
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
          _studentsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _students = [];
          _controllers = {};
          _studentsError = ApiService.friendlyErrorMessage(e);
        });
      }
      debugPrint("Erreur chargement élèves: $e");
    }
  }

  void _showExportDialog(Exam exam) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(child: CircularProgressIndicator()),
    );

    try {
      final grades = await ApiService.getGradesByExam(exam.id);
      final students = await ApiService.getStudents(className: exam.className);

      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("${context.tr('options')} ${exam.title}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${context.tr('subject')}: ${exam.subject} | "
                "${context.tr('classLabel')}: ${exam.className}",
              ),
              SizedBox(height: 16),
              Text(context.tr('auto_voulez_vous_telecharger_le_bordereau')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('cancel')),
            ),
            IconButton(
              icon: Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () => ExportService.generatePdf(
                exam: exam,
                grades: grades,
                students: students,
              ),
            ),
            IconButton(
              icon: Icon(Icons.table_view, color: Colors.green),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('loadDetailsError'))));
      }
    }
  }

  Future<void> _editGrades(Exam exam) async {
    if (!_canWriteGrades) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('teachersOnlyEditGrades'))),
      );
      return;
    }
    if (!exam.editable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('gradesLocked'))));
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
        title: Text("${context.tr('editGrades')} — ${exam.subject}"),
        content: SizedBox(
          width: (MediaQuery.sizeOf(context).width - 80).clamp(280.0, 420.0),
          child: ListView(
            shrinkWrap: true,
            children: grades
                .map(
                  (grade) => ListTile(
                    title: Text(
                      "${context.tr('studentName')} ${grade.studentId}",
                    ),
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
            child: Text(context.tr('cancel')),
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
            child: Text(context.tr('save')),
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
        SnackBar(content: Text(context.tr('teachersOnlySubmitGrades'))),
      );
      return;
    }
    if (selectedSubject == null || selectedClasse == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('selectClassSubject'))));
      return;
    }

    final gradesData = {
      context.tr('classLabel'): selectedClasse,
      'subject': selectedSubject,
      'sequence': selectedSequence,
      'grades': _controllers.map(
        (id, controller) => MapEntry(id, controller.text),
      ),
    };

    setState(() => _isLoading = true);
    try {
      await ApiService.submitGrades(gradesData);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('gradesSaved'))));
        _fetchHistory();
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('saveError'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canWriteGrades) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('gradesPreview'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 8),
          Text(context.tr('teacherOnlyGrades')),
          SizedBox(height: 20),
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
        Text(
          "Gestion des Notes",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        SizedBox(height: 20),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: "Saisie"),
            Tab(text: "Historique"),
          ],
        ),
        SizedBox(height: 25),
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
      return Center(child: CircularProgressIndicator());
    }
    if (_historyExams.isEmpty) {
      return Center(child: Text(context.tr('noHistory')));
    }

    return ListView.builder(
      itemCount: _historyExams.length,
      itemBuilder: (context, index) {
        final exam = _historyExams[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: AppColors.border),
          ),
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryPale,
              child: Icon(Icons.history, color: AppColors.primary),
            ),
            title: Text(
              exam.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${exam.subject} • ${exam.className} • ${DateFormat('dd/MM/yyyy').format(exam.date)}',
            ),
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
                        : context.tr('lockedEditing'),
                  ),
                IconButton(
                  icon: Icon(
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
      return Center(child: CircularProgressIndicator());
    }

    if (_allClasses.isEmpty) {
      if (_loadError != null) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadInitialData,
                  icon: Icon(Icons.refresh),
                  label: Text(context.tr('retry')),
                ),
              ],
            ),
          ),
        );
      }
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            context.tr('noClassesVerify'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildDropdown(
                context.tr('classLabel'),
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
                context.tr('subject'),
                selectedSubject,
                _availableSubjects.map((s) => s.name).toList(),
                (v) {
                  setState(() => selectedSubject = v);
                },
              ),
              _buildDropdown(
                context.tr('period'),
                selectedSequence,
                sequences,
                (v) => setState(() => selectedSequence = v!),
              ),
            ],
          ),
          SizedBox(height: 30),
          if (_studentsError != null)
            Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Text(_studentsError!, textAlign: TextAlign.center),
                  SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _fetchStudents,
                    icon: Icon(Icons.refresh),
                    label: Text(context.tr('retry')),
                  ),
                ],
              ),
            )
          else if (_students.isEmpty)
            Padding(
              padding: EdgeInsets.all(40.0),
              child: Text(
                '${context.tr('noStudentsEnrolledIn')} $selectedClasse',
                style: TextStyle(color: Colors.red),
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
                physics: NeverScrollableScrollPhysics(),
                itemCount: _students.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = _students[index];
                  return ListTile(
                    title: Text(s.fullName),
                    subtitle: Text(
                      "ID: ${s.id}",
                      style: TextStyle(fontSize: 10),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: MyButton(
                icon: Icons.send,
                text: "Valider et Envoyer",
                onTap: _submitGrades,
              ),
            ),
            SizedBox(height: 50),
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: val,
        hint: Text(label),
        underline: SizedBox(),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e.startsWith('Séquence ')
                      ? '${context.tr('sequence')} ${e.split(' ').last}'
                      : e,
                ),
              ),
            )
            .toList(),
        onChanged: onChange,
      ),
    );
  }
}
