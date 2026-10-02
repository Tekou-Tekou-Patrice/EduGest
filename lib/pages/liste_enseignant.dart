import 'package:edugest/components/my_textfield.dart';
import 'package:edugest/models/teacher.dart';
import 'package:edugest/models/subject.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';

class ListeEnseignant extends StatefulWidget {
  ListeEnseignant({super.key});

  @override
  State<ListeEnseignant> createState() => _ListeEnseignantState();
}

class _ListeEnseignantState extends State<ListeEnseignant> {
  String selectedSubjectName = 'Tous';
  String searchQuery = "";
  List<Teacher> _allTeachers = [];
  List<Subject> _availableSubjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _fetchSubjects();
    await _fetchTeachers();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchSubjects() async {
    try {
      final data = await ApiService.getSubjects();
      setState(() {
        _availableSubjects = data;
      });
    } catch (e) {
      debugPrint("Erreur chargement matières: $e");
    }
  }

  Future<void> _fetchTeachers() async {
    try {
      final data = await ApiService.getTeachers(
        query: searchQuery.isEmpty ? null : searchQuery,
      );
      setState(() {
        _allTeachers = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('loadTeachersError'))));
    }
  }

  void _showTeacherDialog({Teacher? teacher}) {
    final messenger = ScaffoldMessenger.of(context);
    final nomController = TextEditingController(text: teacher?.lastName ?? '');
    final prenomController = TextEditingController(
      text: teacher?.firstName ?? '',
    );
    final emailController = TextEditingController(text: teacher?.email ?? '');
    final phoneController = TextEditingController(text: teacher?.phone ?? '');
    final passwordController = TextEditingController();
    String? selectedSpec = teacher?.speciality;

    // Si la spécialité du prof n'est pas dans la liste (ex: nouvelle base), on reset
    if (selectedSpec != null &&
        !_availableSubjects.any((s) => s.name == selectedSpec)) {
      selectedSpec = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            teacher == null
                ? context.tr('recruitTeacher')
                : context.tr('editTeacher'),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyTextfield(
                  controller: prenomController,
                  hintText: context.tr('firstName'),
                  icon: Icons.person_outline,
                ),
                SizedBox(height: 16),
                MyTextfield(
                  controller: nomController,
                  hintText: context.tr('lastName'),
                  icon: Icons.person,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSpec,
                  hint: Text(context.tr('specialty')),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.book, color: AppColors.primary),
                  ),
                  items: _availableSubjects
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.name,
                          child: Text(s.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedSpec = val),
                ),
                SizedBox(height: 16),
                MyTextfield(
                  controller: phoneController,
                  hintText: context.tr('phoneRequired'),
                  icon: Icons.phone_android,
                ),
                SizedBox(height: 16),
                MyTextfield(
                  controller: emailController,
                  hintText: context.tr('emailIdentifier'),
                  icon: Icons.email_outlined,
                ),
                if (teacher == null) ...[
                  SizedBox(height: 16),
                  MyTextfield(
                    controller: passwordController,
                    hintText: context.tr('temporaryPassword'),
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                ],
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
                if (prenomController.text.isEmpty ||
                    nomController.text.isEmpty ||
                    phoneController.text.trim().isEmpty ||
                    emailController.text.isEmpty ||
                    selectedSpec == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('teacherFieldsRequired')),
                    ),
                  );
                  return;
                }

                final newTeacher = Teacher(
                  id: teacher?.id ?? '',
                  firstName: prenomController.text.trim(),
                  lastName: nomController.text.trim(),
                  speciality: selectedSpec!,
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  password: passwordController.text.isNotEmpty
                      ? passwordController.text
                      : null,
                );

                await ApiService.saveTeacher(newTeacher);
                _fetchTeachers();
                if (context.mounted) {
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(context.tr('teacherAccountCreated')),
                    ),
                  );
                }
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
    final filteredTeachers = _allTeachers
        .where(
          (t) =>
              selectedSubjectName == 'Tous' ||
              t.speciality == selectedSubjectName,
        )
        .toList();
    final filterTabs = ['Tous', ..._availableSubjects.map((s) => s.name)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 10,
          children: [
            Text(
              context.tr('teachingStaff'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            MyButton(
              icon: Icons.person_add_alt_1,
              text: context.tr('recruit'),
              onTap: () => _showTeacherDialog(),
            ),
          ],
        ),
        SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            onChanged: (val) {
              searchQuery = val;
              _fetchTeachers();
            },
            decoration: InputDecoration(
              hintText: context.tr('searchTeacher'),
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        SizedBox(height: 20),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filterTabs.map((subjectName) {
              final isSelected = selectedSubjectName == subjectName;
              return GestureDetector(
                onTap: () => setState(() => selectedSubjectName = subjectName),
                child: Container(
                  margin: EdgeInsets.only(right: 8),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    subjectName == 'Tous' ? context.tr('all') : subjectName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: 32),

        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (filteredTeachers.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(context.tr('noTeachers')),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: filteredTeachers.length,
            itemBuilder: (context, index) {
              final teacher = filteredTeachers[index];
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
                    "${teacher.firstName} ${teacher.lastName}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${context.tr('specialty')}: ${teacher.speciality} | ${teacher.email ?? ''}\n"
                    "${context.tr('contactPhone')} : ${teacher.phone?.trim().isNotEmpty == true ? teacher.phone : context.tr('notProvided')}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () => _showTeacherDialog(teacher: teacher),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () async {
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(context.tr('delete')),
                              content: Text(context.tr('removeTeacherConfirm')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(context.tr('no')),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(context.tr('yes')),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await ApiService.deleteTeacher(teacher.id);
                              await _fetchTeachers();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('teacherRemoved')),
                                ),
                              );
                            } catch (error) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ApiService.friendlyErrorMessage(error),
                                  ),
                                ),
                              );
                            }
                          }
                        },
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
