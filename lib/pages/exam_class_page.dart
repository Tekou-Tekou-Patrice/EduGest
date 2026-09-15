import 'package:edugest/components/app_colors.dart';
import 'package:edugest/models/exam_class.dart';
import 'package:edugest/models/school_class.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class ExamClassPage extends StatefulWidget {
  final SchoolClass classroom;

  ExamClassPage({super.key, required this.classroom});

  @override
  State<ExamClassPage> createState() => _ExamClassPageState();
}

class _ExamClassPageState extends State<ExamClassPage> {
  ExamClassConfig? _config;
  List<StudentExamStatus> _students = [];
  bool _loading = true;
  bool _saving = false;
  late final TextEditingController _examNameController;
  late final TextEditingController _feeController;
  final List<TextEditingController> _documentControllers = [];
  final List<bool> _documentRequired = [];

  @override
  void initState() {
    super.initState();
    _examNameController = TextEditingController();
    _feeController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _examNameController.dispose();
    _feeController.dispose();
    for (final controller in _documentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final config = await ApiService.getExamClassConfig(widget.classroom.id);
      _applyConfig(config);
      final students = await ApiService.getExamClassStudents(
        widget.classroom.id,
      );
      if (!mounted) return;
      setState(() {
        _config = config;
        _students = students;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _config = null;
        _loading = false;
      });
    }
  }

  void _applyConfig(ExamClassConfig config) {
    _examNameController.text = config.examName;
    _feeController.text = config.officialFee.toStringAsFixed(0);
    for (final controller in _documentControllers) {
      controller.dispose();
    }
    _documentControllers
      ..clear()
      ..addAll(
        config.documents.map((item) => TextEditingController(text: item.name)),
      );
    _documentRequired
      ..clear()
      ..addAll(config.documents.map((item) => item.required));
  }

  void _addDocument() {
    setState(() {
      _documentControllers.add(TextEditingController());
      _documentRequired.add(true);
    });
  }

  Future<void> _saveConfig() async {
    final documents = <ExamDocumentRequirement>[];
    for (var i = 0; i < _documentControllers.length; i++) {
      final name = _documentControllers[i].text.trim();
      if (name.isNotEmpty) {
        final previous =
            _config?.documents.length == _documentControllers.length
            ? _config!.documents[i]
            : null;
        documents.add(
          ExamDocumentRequirement(
            id: previous?.id,
            name: name,
            required: _documentRequired[i],
          ),
        );
      }
    }
    if (_examNameController.text.trim().isEmpty) {
      _message("Le nom de l'examen est obligatoire");
      return;
    }
    setState(() => _saving = true);
    try {
      final config = await ApiService.saveExamClassConfig(
        widget.classroom.id,
        ExamClassConfig(
          classroomId: widget.classroom.id,
          classroomName: widget.classroom.name,
          examName: _examNameController.text.trim(),
          officialFee:
              double.tryParse(_feeController.text.replaceAll(',', '.')) ?? 0,
          documents: documents,
        ),
      );
      _applyConfig(config);
      final students = await ApiService.getExamClassStudents(
        widget.classroom.id,
      );
      if (!mounted) return;
      setState(() {
        _config = config;
        _students = students;
        _saving = false;
      });
      _message(context.tr('configurationSaved'), success: true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _message(ApiService.friendlyErrorMessage(error));
      }
    }
  }

  Future<void> _editStudent(StudentExamStatus status) async {
    final paidController = TextEditingController(
      text: status.paidAmount.toStringAsFixed(0),
    );
    var edited = status;
    final result = await showDialog<StudentExamStatus>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(status.studentName),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: paidController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          '${context.tr('feesPaid')} (${context.tr('officialFee')}: ${status.officialFee.toInt()} FCFA)',
                    ),
                  ),
                  SizedBox(height: 12),
                  ...edited.documents.asMap().entries.map((entry) {
                    final index = entry.key;
                    final document = entry.value;
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(document.name),
                      subtitle: document.required
                          ? Text(context.tr('required'))
                          : Text(context.tr('optional')),
                      value: document.submitted,
                      onChanged: (value) => setDialogState(() {
                        final documents = [...edited.documents];
                        documents[index] = document.copyWith(
                          submitted: value ?? false,
                        );
                        edited = edited.copyWith(documents: documents);
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  edited.copyWith(
                    paidAmount:
                        double.tryParse(
                          paidController.text.replaceAll(',', '.'),
                        ) ??
                        0,
                  ),
                );
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
    paidController.dispose();
    if (result == null) return;
    try {
      final saved = await ApiService.saveExamStudentStatus(
        widget.classroom.id,
        result,
      );
      if (!mounted) return;
      setState(() {
        _students = _students
            .map((item) => item.studentId == saved.studentId ? saved : item)
            .toList();
      });
    } catch (error) {
      if (mounted) _message(ApiService.friendlyErrorMessage(error));
    }
  }

  void _message(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completeCount = _students
        .where((item) => item.dossierComplete && item.feesComplete)
        .length;
    final dossierCount = _students.where((item) => item.dossierComplete).length;
    final feesCount = _students.where((item) => item.feesComplete).length;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: context.tr('back'),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(context.tr('examClassSettings')),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: .78),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.assignment_turned_in,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suivi des examens',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.classroom.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: Icon(Icons.refresh, color: Colors.white),
                    tooltip: context.tr('refresh'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),
            if (_loading)
              Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_config != null)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _summaryCard(
                          context.tr('completeStudents'),
                          '$completeCount/${_students.length}',
                          Icons.verified,
                          Colors.green,
                        ),
                        _summaryCard(
                          'Dossiers complets',
                          '$dossierCount/${_students.length}',
                          Icons.folder,
                          Colors.blue,
                        ),
                        _summaryCard(
                          'Frais complets',
                          '$feesCount/${_students.length}',
                          Icons.payments,
                          Colors.orange,
                        ),
                      ],
                    ),
                  if (_config != null) SizedBox(height: 18),
                  _buildConfiguration(),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('enrolledStudents'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${_students.length}',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  if (_config == null)
                    Text(context.tr('saveExamConfigFirst'))
                  else if (_students.isEmpty)
                    Text(context.tr('noEnrolledStudents'))
                  else
                    ..._students.map(_buildStudentTile),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 190,



      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),

          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(label, style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguration() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('examSettings'),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _examNameController,
                    decoration: InputDecoration(labelText: 'Nom de l’examen'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _feeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.tr('officialFeesFcfa'),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              context.tr('requiredDocuments'),
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ..._documentControllers.asMap().entries.map((entry) {
              final index = entry.key;
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: 'Document ${index + 1}',
                      ),
                    ),
                  ),
                  Checkbox(
                    value: _documentRequired[index],
                    onChanged: (value) => setState(
                      () => _documentRequired[index] = value ?? true,
                    ),
                  ),
                  Text(context.tr('required')),
                  IconButton(
                    onPressed: () => setState(() {
                      entry.value.dispose();
                      _documentControllers.removeAt(index);
                      _documentRequired.removeAt(index);
                    }),
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              );
            }),
            SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _addDocument,
                  icon: Icon(Icons.add),
                  label: Text(context.tr('addDocument')),
                ),
                FilledButton.icon(
                  onPressed: _saving ? null : _saveConfig,
                  icon: Icon(Icons.save),
                  label: Text(
                    _saving
                        ? 'Enregistrement...'
                        : 'Enregistrer la configuration',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTile(StudentExamStatus status) {
    final complete = status.dossierComplete && status.feesComplete;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: complete ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _editStudent(status),
        leading: CircleAvatar(
          backgroundColor: complete
              ? Colors.green.shade100
              : Colors.orange.shade100,
          child: Icon(
            complete ? Icons.check : Icons.warning_amber_rounded,
            color: complete ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(status.studentName),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 5),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _statusChip(
                status.dossierComplete
                    ? 'Dossier complet'
                    : 'Dossier incomplet',
                status.dossierComplete ? Colors.green : Colors.orange,
              ),
              _statusChip(
                status.feesComplete
                    ? 'Frais complets'
                    : '${status.paidAmount.toInt()}/${status.officialFee.toInt()} FCFA',
                status.feesComplete ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
