import 'package:edugest/components/app_colors.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/models/exam_class.dart';
import 'package:edugest/models/school_class.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class ExamClassesPage extends StatefulWidget {
  final AppUser currentUser;

  ExamClassesPage({super.key, required this.currentUser});

  @override
  State<ExamClassesPage> createState() => _ExamClassesPageState();
}

class _ExamClassesPageState extends State<ExamClassesPage> {
  List<SchoolClass> _classes = [];
  Map<String, List<StudentExamStatus>> _studentsByClass = {};
  bool _loading = true;

  bool get _canAccess =>
      widget.currentUser.role == UserRole.fondateur ||
      widget.currentUser.role == UserRole.proviseur ||
      widget.currentUser.role == UserRole.censeur ||
      widget.currentUser.role == UserRole.secretaire ||
      widget.currentUser.role == UserRole.comptable;

  @override
  void initState() {
    super.initState();
    if (_canAccess) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final classrooms = await ApiService.getClassrooms();
      final examClasses = classrooms.where((item) => item.examClass).toList();
      final results = await Future.wait(
        examClasses.map(
          (classroom) => ApiService.getExamClassStudents(classroom.id),
        ),
      );
      if (!mounted) return;
      setState(() {
        _classes = examClasses;
        _studentsByClass = {
          for (var index = 0; index < examClasses.length; index++)
            examClasses[index].id: results[index],
        };
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.friendlyErrorMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canAccess) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(child: Text(context.tr('adminOnlyPage'))),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('examClassesTracking'),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: _loading ? null : _load,
              icon: Icon(Icons.refresh),
              tooltip: context.tr('refresh'),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          context.tr('examClassDescription'),
          style: TextStyle(color: AppColors.textMuted),
        ),
        SizedBox(height: 20),
        if (_loading)
          Center(child: CircularProgressIndicator())
        else if (_classes.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text(context.tr('noExamClasses'))),
            ),
          )
        else
          ..._classes.map(_buildClassCard),
      ],
    );
  }

  Widget _buildClassCard(SchoolClass classroom) {
    final students = _studentsByClass[classroom.id] ?? [];
    final upToDate = students
        .where((student) => student.dossierComplete && student.feesComplete)
        .length;
    final notUpToDate = students.length - upToDate;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryPale,
          child: Icon(Icons.assignment_turned_in, color: AppColors.primary),
        ),
        title: Text(
          classroom.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$upToDate ${context.tr('upToDate').toLowerCase()} • '
          '$notUpToDate ${context.tr('notUpToDate').toLowerCase()} • '
          '${students.length} ${context.tr('students').toLowerCase()}',
        ),
        children: students.isEmpty
            ? [ListTile(title: Text(context.tr('noStudentsInClass')))]
            : students.map(_buildStudentTile).toList(),
      ),
    );
  }

  Widget _buildStudentTile(StudentExamStatus student) {
    final complete = student.dossierComplete && student.feesComplete;
    final status = complete
        ? context.tr('upToDate')
        : context.tr('notUpToDate');
    final statusColor = complete ? Colors.green : Colors.orange;
    final details = <String>[
      student.dossierComplete
          ? context.tr('completeFile')
          : context.tr('incompleteFile'),
      student.feesComplete
          ? context.tr('completeFees')
          : '${context.tr('fees')}: ${student.paidAmount.toInt()}/${student.officialFee.toInt()} FCFA',
    ];

    return ListTile(
      leading: Icon(
        complete ? Icons.check_circle : Icons.warning_amber_rounded,
        color: statusColor,
      ),
      title: Text(student.studentName),
      subtitle: Text(details.join(' • ')),
      trailing: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
