import 'package:edugest/components/app_colors.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/models/school_class.dart';
import 'package:edugest/models/subject.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'package:intl/intl.dart';

class ProgrammePage extends StatefulWidget {
  final AppUser currentUser;
  ProgrammePage({super.key, required this.currentUser});

  @override
  State<ProgrammePage> createState() => _ProgrammePageState();
}

class _ProgrammePageState extends State<ProgrammePage> {
  List<Map<String, dynamic>> _chapters = [];
  List<SchoolClass> _classes = [];
  List<Subject> _subjects = [];
  String? _selectedClass;
  String? _selectedSubject;
  bool _loading = true;
  bool _saving = false;

  bool get _isParent => widget.currentUser.role == UserRole.parent;
  bool get _isTeacher => widget.currentUser.role == UserRole.enseignant;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final classFuture = _isParent
          ? Future.value(<SchoolClass>[])
          : ApiService.getClassrooms();
      final subjectFuture = _isParent
          ? Future.value(<Subject>[])
          : ApiService.getSubjects();
      final chaptersFuture = _loadChapters();
      final results = await Future.wait<dynamic>([
        classFuture,
        subjectFuture,
        chaptersFuture,
      ]);
      if (!mounted) return;
      setState(() {
        _classes = results[0] as List<SchoolClass>;
        _subjects = results[1] as List<Subject>;
        _chapters = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger le programme : $error')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadChapters() async {
    if (!_isParent) {
      return _isTeacher
          ? ApiService.getProgramChapters(teacherId: widget.currentUser.id)
          : ApiService.getProgramChapters();
    }

    final children = await ApiService.getParentStudents(widget.currentUser.id);
    final classNames = children
        .map((child) => child.className)
        .where((name) => name.trim().isNotEmpty)
        .toSet();
    final lists = await Future.wait(
      classNames.map(
        (className) => ApiService.getProgramChapters(
          className: className,
          completed: true,
        ),
      ),
    );
    final unique = <String, Map<String, dynamic>>{};
    for (final chapter in lists.expand((items) => items)) {
      final key =
          '${chapter['className']}|${chapter['subject']}|${chapter['majorChapter']}';
      unique[key] = chapter;
    }
    return unique.values.toList();
  }

  Future<void> _openChapterForm() async {
    final majorController = TextEditingController();
    final subController = TextEditingController();
    String? selectedClass =
        _selectedClass ?? (_classes.isNotEmpty ? _classes.first.name : null);
    String? selectedSubject =
        _selectedSubject ??
        (_subjects.isNotEmpty ? _subjects.first.name : null);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('addToProgram')),
          content: SizedBox(
            width: (MediaQuery.sizeOf(context).width - 80).clamp(280.0, 480.0),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedClass,
                      decoration: InputDecoration(
                        labelText: context.tr('classLabel'),
                      ),
                      items: _classes
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.name,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedClass = value),
                      validator: (value) =>
                          value == null ? context.tr('selectClass') : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: InputDecoration(
                        labelText: context.tr('subject'),
                      ),
                      items: _subjects
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.name,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedSubject = value),
                      validator: (value) =>
                          value == null ? context.tr('selectSubject') : null,
                    ),
                    TextFormField(
                      controller: majorController,
                      decoration: InputDecoration(
                        labelText: context.tr('mainChapter'),
                        hintText: context.tr('chapterExample'),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Le grand chapitre est obligatoire'
                          : null,
                    ),
                    TextFormField(
                      controller: subController,
                      decoration: InputDecoration(
                        labelText: context.tr('subChapterOptional'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => _saving = true);
                      try {
                        await ApiService.saveProgramChapter({
                          'majorChapter': majorController.text.trim(),
                          'subChapter': subController.text.trim(),
                          'className': selectedClass,
                          'subject': selectedSubject,
                          'teacherId': widget.currentUser.id,
                          'teacherName': widget.currentUser.name,
                        });
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await _load();
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('Enregistrement impossible : $error'),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
    majorController.dispose();
    subController.dispose();
  }

  Future<void> _toggleCompleted(Map<String, dynamic> chapter) async {
    try {
      await ApiService.setProgramChapterCompleted(
        chapter['id'].toString(),
        chapter['completed'] != true,
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('updateImpossible')} $error')),
        );
      }
    }
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null ? '' : DateFormat('dd/MM/yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isParent
        ? context.tr('completedChapters')
        : context.tr('programTracking');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            if (_isTeacher)
              FilledButton.icon(
                onPressed: _openChapterForm,
                icon: Icon(Icons.add),
                label: Text(context.tr('add')),
              ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          _isParent
              ? context.tr('parentCompletedChaptersDescription')
              : _isTeacher
              ? context.tr('teacherProgramDescription')
              : context.tr('programTrackingDescription'),
          style: TextStyle(color: AppColors.textMuted),
        ),
        SizedBox(height: 20),
        if (_loading)
          Center(child: CircularProgressIndicator())
        else if (_chapters.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text(context.tr('noChapters'))),
            ),
          )
        else
          ..._chapters.map(
            (chapter) => Card(
              margin: EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  chapter['completed'] == true
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: chapter['completed'] == true
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Text(
                  chapter['majorChapter']?.toString() ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  [
                    if (!_isParent) chapter['className']?.toString() ?? '',
                    if (!_isParent) chapter['subject']?.toString() ?? '',
                    if (!_isTeacher) chapter['teacherName']?.toString() ?? '',
                    if (!_isParent &&
                        chapter['subChapter']?.toString().isNotEmpty == true)
                      'Sous-chapitre : ${chapter['subChapter']}',
                    if (chapter['completedAt'] != null)
                      '${context.tr('completedOn')} ${_date(chapter['completedAt'])}',
                  ].where((item) => item.isNotEmpty).join(' • '),
                ),
                trailing: _isTeacher
                    ? Switch(
                        value: chapter['completed'] == true,
                        onChanged: (_) => _toggleCompleted(chapter),
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
