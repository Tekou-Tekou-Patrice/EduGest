import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'package:edugest/models/grade.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/export_service.dart';
import '../components/app_colors.dart';
import '../components/export_language_dialog.dart';

class ReceptionNotes extends StatefulWidget {
  final AppUser? currentUser;

  ReceptionNotes({super.key, this.currentUser});

  @override
  State<ReceptionNotes> createState() => _ReceptionNotesState();
}

class _ReceptionNotesState extends State<ReceptionNotes> {
  String selectedClasse = 'Toutes';
  List<Exam> _exams = [];
  bool _isLoading = true;

  bool get _canEditGrades {
    final role = widget.currentUser?.role;
    return role == UserRole.fondateur ||
        role == UserRole.proviseur ||
        role == UserRole.secretaire;
  }

  final List<String> _classes = [
    'Toutes',
    '6eme',
    '5eme',
    '4eme',
    '3eme',
    '2nd',
    '1ere',
    'Terminale',
  ];

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getExams(
        className: selectedClasse == 'Toutes' ? null : selectedClasse,
      );
      if (mounted) {
        setState(() {
          _exams = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              context.tr('notesReceptionValidation'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.primary),
              onPressed: _fetchExams,
            ),
          ],
        ),
        SizedBox(height: 20),

        // Filtre de classe
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _classes.map((c) {
              return Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(c == 'Toutes' ? context.tr('all') : c),
                  selected: selectedClasse == c,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => selectedClasse = c);
                      _fetchExams();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 25),

        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (_exams.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(context.tr('noExamSubmission')),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _exams.length,
            itemBuilder: (context, index) {
              final exam = _exams[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryPale,
                    child: Icon(
                      Icons.assignment_turned_in,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    exam.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${context.tr('subject')}: ${exam.subject} • "
                    "${context.tr('classLabel')}: ${exam.className}"
                    "${exam.teacherName?.trim().isNotEmpty == true ? ' • ${context.tr('sentBy')} ${exam.teacherName}' : ''}",
                  ),
                  isThreeLine: exam.teacherName?.trim().isNotEmpty == true,
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => _showGradesTable(context, exam),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showGradesTable(BuildContext pageContext, Exam exam) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final grades = await ApiService.getGradesByExam(exam.id);
      final students = await ApiService.getStudents(className: exam.className);

      if (!pageContext.mounted) return;
      Navigator.pop(pageContext); // Remove loading

      final studentMap = {for (var s in students) s.id: s.fullName};
      final controllers = {
        for (final grade in grades)
          grade.id: TextEditingController(text: grade.score.toString()),
      };

      var isEditing = false;
      var isSaving = false;
      await showDialog(
        context: pageContext,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Row(
              children: [
                Expanded(
                  child: Text("${context.tr('transcript')} : ${exam.title}"),
                ),
                if (_canEditGrades && grades.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      isEditing ? Icons.close : Icons.edit_outlined,
                      color: AppColors.primary,
                    ),
                    onPressed: isSaving
                        ? null
                        : () => setDialogState(() => isEditing = !isEditing),
                    tooltip: context.tr(
                      isEditing ? 'cancel' : 'editGradesBeforePublication',
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: isEditing
                      ? null
                      : () async {
                          final languageCode = await ExportLanguageDialog.show(
                            context,
                          );
                          if (languageCode == null || !pageContext.mounted) {
                            return;
                          }
                          await ExportService.generatePdf(
                            exam: exam,
                            grades: grades,
                            students: students,
                            languageCode: languageCode,
                          );
                        },
                  tooltip: context.tr('downloadPdf'),
                ),
                IconButton(
                  icon: Icon(Icons.table_view, color: Colors.green),
                  onPressed: isEditing
                      ? null
                      : () async {
                          final languageCode = await ExportLanguageDialog.show(
                            context,
                          );
                          if (languageCode == null || !pageContext.mounted) {
                            return;
                          }
                          await ExportService.generateExcel(
                            exam: exam,
                            grades: grades,
                            students: students,
                            languageCode: languageCode,
                          );
                        },
                  tooltip: context.tr('downloadExcel'),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${context.tr('subject')} : ${exam.subject} | "
                        "${context.tr('classLabel')} : ${exam.className}",
                      ),
                      if (isEditing)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            context.tr('gradeEditBeforePublicationHint'),
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      SizedBox(height: 16),
                      Divider(),
                      Table(
                        border: TableBorder.all(
                          color: AppColors.border,
                          width: 1,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        columnWidths: {
                          0: FlexColumnWidth(3),
                          1: FixedColumnWidth(90),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: AppColors.bg),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  context.tr('studentName'),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  context.tr('grade'),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          ...grades.map(
                            (grade) => TableRow(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    studentMap[grade.studentId] ??
                                        "Inconnu (${grade.studentId})",
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(4),
                                  child: isEditing
                                      ? TextField(
                                          controller: controllers[grade.id],
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            suffixText: '/20',
                                          ),
                                        )
                                      : Text(
                                          grade.score.toStringAsFixed(1),
                                          textAlign: TextAlign.center,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (grades.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(context.tr('noGrades')),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (isEditing) ...[
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => setDialogState(() => isEditing = false),
                  child: Text(context.tr('cancel')),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final changedGrades = <Grade>[];
                          for (final grade in grades) {
                            final score = double.tryParse(
                              controllers[grade.id]!.text.replaceAll(',', '.'),
                            );
                            if (score == null || score < 0 || score > 20) {
                              ScaffoldMessenger.of(pageContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr('invalidGradeRange'),
                                  ),
                                ),
                              );
                              return;
                            }
                            changedGrades.add(
                              Grade(
                                id: grade.id,
                                studentId: grade.studentId,
                                examId: grade.examId,
                                score: score,
                                observations: grade.observations,
                              ),
                            );
                          }
                          setDialogState(() => isSaving = true);
                          try {
                            await ApiService.updateGrades(changedGrades);
                            grades
                              ..clear()
                              ..addAll(changedGrades);
                            for (final grade in grades) {
                              controllers[grade.id]!.text = grade.score
                                  .toString();
                            }
                            if (context.mounted) {
                              setDialogState(() {
                                isSaving = false;
                                isEditing = false;
                              });
                            }
                            if (pageContext.mounted) {
                              ScaffoldMessenger.of(pageContext).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('gradesSaved')),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${context.tr('saveError')} ${ApiService.friendlyErrorMessage(e)}',
                                ),
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('save')),
                ),
              ] else
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('close')),
                ),
            ],
          ),
        ),
      );
      for (final controller in controllers.values) {
        controller.dispose();
      }
    } catch (e) {
      if (pageContext.mounted) {
        Navigator.pop(pageContext); // Remove loading
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(
            content: Text(
              "${pageContext.tr('loadDetailsError')}: "
              '${ApiService.friendlyErrorMessage(e)}',
            ),
          ),
        );
      }
    }
  }
}
