import 'package:edugest/models/student.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/models/school_class.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/components/my_textfield.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'package:intl/intl.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';

class ListeEleves extends StatefulWidget {
  final AppUser currentUser;
  ListeEleves({super.key, required this.currentUser});

  @override
  State<ListeEleves> createState() => _ListeElevesState();
}

class _ListeElevesState extends State<ListeEleves> {
  String selectedClasse = 'Toutes';
  String searchQuery = "";
  List<Student> _eleves = [];
  List<SchoolClass> _availableClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _fetchClasses();
    await _fetchData();
  }

  Future<void> _fetchClasses() async {
    try {
      final data = await ApiService.getClassrooms();
      if (mounted) {
        setState(() {
          _availableClasses = data;
        });
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des classes: $e");
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getStudents(
        className: selectedClasse == 'Toutes' ? null : selectedClasse,
        query: searchQuery.isEmpty ? null : searchQuery,
      );
      if (mounted) {
        setState(() {
          _eleves = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _validateStudent(Student student) async {
    String? selectedClass = _availableClasses.isNotEmpty
        ? _availableClasses.first.name
        : null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(context.tr('validateRegistration')),
          content: DropdownButtonFormField<String>(
            value: selectedClass,
            decoration: InputDecoration(
              labelText: context.tr('assignClass'),
              border: OutlineInputBorder(),
            ),
            items: _availableClasses
                .map(
                  (schoolClass) => DropdownMenuItem(
                    value: schoolClass.name,
                    child: Text(schoolClass.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setDialogState(() => selectedClass = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: selectedClass == null
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: Text(context.tr('validate')),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || selectedClass == null) return;
    final classroom = _availableClasses.firstWhere(
      (schoolClass) => schoolClass.name == selectedClass,
    );
    try {
      await ApiService.validateStudent(
        studentId: student.id,
        classroomId: classroom.id,
      );
      await _fetchData();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.friendlyErrorMessage(error))),
        );
      }
    }
  }

  void _showStudentDialog({Student? student}) {
    final prenomCtrl = TextEditingController(text: student?.firstName ?? '');
    final nomCtrl = TextEditingController(text: student?.lastName ?? '');
    final parentNomCtrl = TextEditingController(
      text: student?.parentName ?? '',
    );
    final parentPhoneCtrl = TextEditingController(
      text: student?.parentPhone ?? '',
    );
    final parentEmailCtrl = TextEditingController(
      text: student?.parentEmail ?? '',
    );
    final parentPasswordCtrl = TextEditingController();

    DateTime? selectedBirthDate = student?.birthDate;
    final birthDateCtrl = TextEditingController(
      text: selectedBirthDate != null
          ? DateFormat('dd/MM/yyyy').format(selectedBirthDate)
          : '',
    );

    String? currentClass = student?.className;
    if (currentClass == null || currentClass.isEmpty) {
      if (selectedClasse != 'Toutes') {
        currentClass = selectedClasse;
      } else if (_availableClasses.isNotEmpty) {
        currentClass = _availableClasses.first.name;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            student == null
                ? context.tr('registerStudent')
                : context.tr('editStudent'),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('studentInformation'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                MyTextfield(
                  controller: prenomCtrl,
                  hintText: context.tr('firstName'),
                  icon: Icons.person_outline,
                ),
                SizedBox(height: 12),
                MyTextfield(
                  controller: nomCtrl,
                  hintText: context.tr('lastName'),
                  icon: Icons.person,
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedBirthDate ?? DateTime(2010),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedBirthDate = picked;
                        birthDateCtrl.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(picked);
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: MyTextfield(
                      controller: birthDateCtrl,
                      hintText: context.tr('birthDate'),
                      icon: Icons.calendar_today,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _availableClasses.any((c) => c.name == currentClass)
                      ? currentClass
                      : null,
                  hint: Text(context.tr('selectClass')),
                  decoration: InputDecoration(
                    labelText: context.tr('classLabel'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _availableClasses
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.name,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => currentClass = val);
                  },
                ),

                SizedBox(height: 24),
                Text(
                  context.tr('parentInformation'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                MyTextfield(
                  controller: parentNomCtrl,
                  hintText: context.tr('parentName'),
                  icon: Icons.family_restroom,
                ),
                SizedBox(height: 12),
                MyTextfield(
                  controller: parentPhoneCtrl,
                  hintText: context.tr('parentPhone'),
                  icon: Icons.phone_callback,
                ),
                SizedBox(height: 12),
                MyTextfield(
                  controller: parentEmailCtrl,
                  hintText: context.tr('parentEmail'),
                  icon: Icons.email_outlined,
                ),
                SizedBox(height: 12),
                if (student == null)
                  MyTextfield(
                    controller: parentPasswordCtrl,
                    hintText: context.tr('parentTemporaryPassword'),
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                if (student == null)
                  Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      context.tr('parentPasswordFallback'),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),

                if (_availableClasses.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      context.tr('noClassesAvailable'),
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            if (student != null)
              TextButton(
                onPressed: () async {
                  await ApiService.deleteStudent(student.id);
                  if (mounted) Navigator.pop(context);
                  _fetchData();
                },
                child: Text(
                  context.tr('delete'),
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                if (prenomCtrl.text.trim().isEmpty ||
                    nomCtrl.text.trim().isEmpty ||
                    currentClass == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('studentFieldsRequired')),
                    ),
                  );
                  return;
                }
                final newStudent = Student(
                  id: student?.id ?? '',
                  firstName: prenomCtrl.text.trim(),
                  lastName: nomCtrl.text.trim(),
                  className: currentClass!,
                  birthDate: selectedBirthDate,
                  parentName: parentNomCtrl.text.trim(),
                  parentPhone: parentPhoneCtrl.text.trim(),
                  parentEmail: parentEmailCtrl.text.trim(),
                  parentPassword: parentPasswordCtrl.text,
                  registeredById: widget.currentUser.id,
                );
                await ApiService.saveStudent(newStudent);
                if (mounted) Navigator.pop(context);
                _fetchData();
              },
              child: Text(
                context.tr('validate'),
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
    final allFilterClasses = [
      'Toutes',
      ..._availableClasses.map((e) => e.name),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            Text(
              context.tr('studentManagement'),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _showStudentDialog(),
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    context.tr('add'),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 10),
                MyButton(
                  icon: Icons.refresh,
                  text: context.tr('refresh'),
                  onTap: _loadInitialData,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 20),

        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            onChanged: (val) {
              searchQuery = val;
              _fetchData();
            },
            decoration: InputDecoration(
              hintText: context.tr('searchStudent'),
              icon: Icon(Icons.search),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 20),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: allFilterClasses
                .map(
                  (c) => Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(c == 'Toutes' ? context.tr('all') : c),
                      selected: selectedClasse == c,
                      onSelected: (s) {
                        setState(() => selectedClasse = c);
                        _fetchData();
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(height: 25),

        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (_eleves.isEmpty)
          Center(child: Text(context.tr('noStudents')))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _eleves.length,
            itemBuilder: (context, index) {
              final student = _eleves[index];
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
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(
                    "${student.firstName} ${student.lastName}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${context.tr('classLabel')}: ${student.className}"),
                      if (student.birthDate != null)
                        Text(
                          "${context.tr('bornOn')} ${DateFormat('dd/MM/yyyy').format(student.birthDate!)}",
                          style: TextStyle(fontSize: 12),
                        ),
                      if (student.parentName != null &&
                          student.parentName!.isNotEmpty)
                        Text(
                          "${context.tr('parentPrefix')}: ${student.parentName} (${student.parentPhone ?? ''})",
                          style: TextStyle(fontSize: 12),
                        ),
                      if (student.registeredByName != null)
                        Text(
                          "${context.tr('registeredBy')}: ${student.registeredByName}",
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (student.registrationStatus == 'PENDING')
                        Text(
                          context.tr('pendingRegistration'),
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (student.registrationStatus == 'PENDING' &&
                          (widget.currentUser.role == UserRole.proviseur ||
                              widget.currentUser.role == UserRole.fondateur))
                        IconButton(
                          tooltip: context.tr('validateRegistration'),
                          icon: const Icon(
                            Icons.verified_outlined,
                            color: Colors.green,
                          ),
                          onPressed: () => _validateStudent(student),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _showStudentDialog(student: student),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
