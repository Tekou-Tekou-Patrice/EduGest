import 'package:edugest/models/sanction.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/models/student.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/school_notifier.dart';
import 'package:edugest/components/my_button.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../components/app_colors.dart';
import 'package:intl/intl.dart';

class Discipline extends StatefulWidget {
  final AppUser? currentUser;
  Discipline({super.key, this.currentUser});

  @override
  State<Discipline> createState() => _DisciplineState();
}

class _DisciplineState extends State<Discipline> {
  bool get _canManageSanctions {
    final role = widget.currentUser?.role;
    final isPrimary = currentSchoolNotifier.value?.schoolLevel == 'PRIMARY';
    final isPrimaryAdmin =
        isPrimary &&
        (role == UserRole.proviseur || role == UserRole.secretaire);
    return role == null ||
        role == UserRole.fondateur ||
        role == UserRole.proviseur ||
        role == UserRole.censeur ||
        role == UserRole.surveillant ||
        role == UserRole.surveillantGeneral ||
        isPrimaryAdmin;
  }

  late Future<List<Sanction>> _sanctionsFuture;
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String _selectedType = 'Avertissement';
  final List<String> _sanctionTypes = [
    'Avertissement',
    'Blâme',
    'Exclusion',
    'Corvée',
  ];

  String _sanctionTypeLabel(String type) {
    switch (type) {
      case 'Avertissement':
        return context.tr('category_warning');
      case 'Blâme':
        return context.tr('category_reprimand');
      case 'Exclusion':
        return context.tr('category_exclusion');
      case 'Corvée':
        return context.tr('category_communityService');
      default:
        return type;
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshSanctions();
  }

  void _refreshSanctions() {
    setState(() {
      _sanctionsFuture = ApiService.getSanctions();
    });
  }

  void _showSanctionDialog({Sanction? sanction}) {
    Student? selectedStudent;
    List<Student> matches = [];
    bool isSearching = false;
    if (sanction != null) {
      _studentNameController.text = sanction.studentName;
      _reasonController.text = sanction.reason;
      _selectedType = sanction.type;
    } else {
      _studentNameController.clear();
      _reasonController.clear();
      _selectedType = 'Avertissement';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            sanction == null
                ? context.tr('newSanction')
                : context.tr('editSanction'),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _studentNameController,
                  decoration: InputDecoration(
                    labelText: context.tr('searchExistingStudent'),
                    hintText: context.tr('nameOrId'),
                    prefixIcon: Icon(Icons.person_search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) async {
                    selectedStudent = null;
                    if (value.trim().length < 2) {
                      setDialogState(() => matches = []);
                      return;
                    }
                    setDialogState(() => isSearching = true);
                    try {
                      final students = await ApiService.getStudents(
                        query: value.trim(),
                      );
                      if (context.mounted) {
                        setDialogState(() => matches = students);
                      }
                    } finally {
                      if (context.mounted)
                        setDialogState(() => isSearching = false);
                    }
                  },
                ),
                if (isSearching)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
                if (matches.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    constraints: BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: matches
                          .map(
                            (student) => ListTile(
                              dense: true,
                              title: Text(student.fullName),
                              subtitle: Text(
                                '${student.className} • ${student.id}',
                              ),
                              onTap: () => setDialogState(() {
                                selectedStudent = student;
                                _studentNameController.text = student.fullName;
                                matches = [];
                              }),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    labelText: context.tr('sanctionType'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: _sanctionTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_sanctionTypeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => _selectedType = val!),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.tr('reason'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                final studentId = sanction?.studentId ?? selectedStudent?.id;
                if (studentId == null ||
                    studentId.isEmpty ||
                    _reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('selectStudentReason'))),
                  );
                  return;
                }
                try {
                  final newSanction = Sanction(
                    id: sanction?.id ?? '',
                    studentId: studentId,
                    studentName:
                        selectedStudent?.fullName ??
                        _studentNameController.text.trim(),
                    type: _selectedType,
                    reason: _reasonController.text,
                    date: sanction?.date ?? DateTime.now(),
                  );
                  await ApiService.addSanction(newSanction);
                  if (!context.mounted) return;
                  _refreshSanctions();
                  Navigator.pop(context);
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ApiService.friendlyErrorMessage(error)),
                    ),
                  );
                }
              },
              child: Text(
                sanction == null
                    ? context.tr('auto_appliquer')
                    : context.tr('update'),
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
              context.tr('disciplineTracking'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            if (_canManageSanctions)
              SizedBox(
                width: 160,
                child: MyButton(
                  icon: Icons.gavel,
                  text: context.tr('sanction'),
                  onTap: () => _showSanctionDialog(),
                ),
              ),
          ],
        ),
        SizedBox(height: 25),

        FutureBuilder<List<Sanction>>(
          future: _sanctionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError)
              return Center(
                child: Text(
                  '${context.tr('errorPrefix')} '
                  '${ApiService.friendlyErrorMessage(snapshot.error!)}',
                ),
              );
            if (!snapshot.hasData || snapshot.data!.isEmpty)
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(context.tr('noIncidents')),
                ),
              );

            final items = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final s = items[index];
                final bool isSevere = s.type.contains('Exclusion');

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isSevere ? Colors.red : Colors.orange)
                          .withValues(alpha: 0.1),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: isSevere ? Colors.red : Colors.orange,
                      ),
                    ),
                    title: Text(
                      s.studentName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${s.type} • ${DateFormat('dd/MM/yyyy').format(s.date)}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_canManageSanctions)
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: Colors.blue,
                              size: 20,
                            ),
                            onPressed: () => _showSanctionDialog(sanction: s),
                          ),
                        if (_canManageSanctions)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () async {
                              await ApiService.deleteSanction(s.id);
                              _refreshSanctions();
                            },
                          ),
                      ],
                    ),
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
