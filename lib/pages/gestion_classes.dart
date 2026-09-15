import 'package:edugest/components/responsive_layout.dart';
import 'package:edugest/models/school_class.dart';
import 'package:edugest/models/teacher.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/school_notifier.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import 'exam_class_page.dart';

class GestionClasses extends StatefulWidget {
  final bool readOnly;

  const GestionClasses({super.key, this.readOnly = false});

  @override
  State<GestionClasses> createState() => _GestionClassesState();
}

class _GestionClassesState extends State<GestionClasses> {
  List<SchoolClass> _classes = [];
  List<Teacher> _teachers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    if (!widget.readOnly) _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    try {
      _teachers = await ApiService.getTeachers();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getClassrooms();
      if (!mounted) return;
      setState(() {
        _classes = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('loadClassesError'))));
    }
  }

  void _showCreateDialog() {
    final isPrimarySchool =
        currentSchoolNotifier.value?.schoolLevel == 'PRIMARY';
    final nameCtrl = TextEditingController();
    final levelCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '40');
    final tuitionCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool examClass = false;
    List<String> selectedTeacherIds = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('createClass')),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyTextfield(
                  controller: nameCtrl,
                  hintText: isPrimarySchool
                      ? 'Ex. 1ère année, 2e année, CM2'
                      : context.tr('classNameExample'),
                  icon: Icons.class_,
                ),
                SizedBox(height: 12),
                MyTextfield(
                  controller: levelCtrl,
                  hintText: context.tr('levelExample'),
                  icon: Icons.layers,
                ),
                SizedBox(height: 12),
                MyTextfield(
                  controller: capacityCtrl,
                  hintText: context.tr('capacity'),
                  icon: Icons.people,
                ),
                SizedBox(height: 12),
                MyTextfield(
                  controller: tuitionCtrl,
                  hintText: context.tr('tuitionFees'),
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                MyTextfield(
                  controller: descCtrl,
                  hintText: context.tr('description'),
                  icon: Icons.notes,
                ),
                SizedBox(height: 4),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: examClass,
                  title: Text(context.tr('examClass')),
                  subtitle: Text(context.tr('enableExamTracking')),
                  onChanged: (value) =>
                      setDialogState(() => examClass = value ?? false),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    examClass
                        ? 'Enseignants de la classe d’examen'
                        : 'Enseignant titulaire',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (_teachers.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Ajoutez d’abord des enseignants.'),
                  )
                else
                  ..._teachers.map(
                    (teacher) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: selectedTeacherIds.contains(teacher.id),
                      title: Text(teacher.fullName),
                      subtitle: teacher.speciality.isEmpty
                          ? null
                          : Text(teacher.speciality),
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            selectedTeacherIds = examClass
                                ? [...selectedTeacherIds, teacher.id]
                                : [teacher.id];
                          } else {
                            selectedTeacherIds = selectedTeacherIds
                                .where((id) => id != teacher.id)
                                .toList();
                          }
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                if (isPrimarySchool && selectedTeacherIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sélectionnez un enseignant titulaire pour cette classe.',
                      ),
                    ),
                  );
                  return;
                }
                try {
                  await ApiService.saveClassroom(
                    SchoolClass(
                      id: '',
                      name: nameCtrl.text.trim(),
                      level: levelCtrl.text.trim().isEmpty
                          ? nameCtrl.text.trim()
                          : levelCtrl.text.trim(),
                      capacity: int.tryParse(capacityCtrl.text) ?? 40,
                      tuitionFee:
                          double.tryParse(
                            tuitionCtrl.text.replaceAll(',', '.'),
                          ) ??
                          0,
                      description: descCtrl.text.trim(),
                      examClass: examClass,
                      teacherIds: selectedTeacherIds,
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                  await _fetchClasses();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('saveError'))),
                    );
                  }
                }
              },
              child: Text(
                context.tr('create'),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Text(
              "Gestion des Classes",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            if (!widget.readOnly)
              MyButton(
                icon: Icons.add_home_work,
                text: context.tr('createClass'),
                onTap: _showCreateDialog,
              ),
          ],
        ),
        SizedBox(height: 24),
        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (_classes.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(context.tr('noClassesCreate')),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final double aspectRatio = isMobile
                  ? (constraints.maxWidth < 360 ? 1.45 : 1.65)
                  : 1.8;
              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : 2,
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _classes.length,
                itemBuilder: (context, index) {
                  final c = _classes[index];
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "${c.studentCount} ${context.tr('students').toLowerCase()} • "
                          "${context.tr('capacity')} ${c.capacity}",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Pension : ${c.tuitionFee.toInt()} FCFA",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (c.examClass) ...[
                          SizedBox(height: 6),
                          Chip(
                            avatar: Icon(Icons.assignment_turned_in, size: 16),
                            label: Text(context.tr('examClass')),
                            visualDensity: VisualDensity.compact,
                          ),
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExamClassPage(classroom: c),
                              ),
                            ),
                            icon: Icon(Icons.settings, size: 16),
                            label: Text(context.tr('configureExam')),
                          ),
                        ],
                        if (c.teacherNames.isNotEmpty ||
                            (c.teacherName != null &&
                                c.teacherName!.isNotEmpty)) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPale,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Prof: ${c.teacherNames.isNotEmpty ? c.teacherNames.join(', ') : c.teacherName}",
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        SizedBox(height: 6),
                        if (!widget.readOnly)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () async {
                              try {
                                await ApiService.deleteClassroom(c.id);
                                await _fetchClasses();
                              } catch (_) {}
                            },
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
