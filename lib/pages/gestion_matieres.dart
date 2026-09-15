import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../models/subject.dart';
import '../service/api_service.dart';

class GestionMatieres extends StatefulWidget {
  GestionMatieres({super.key});

  @override
  State<GestionMatieres> createState() => _GestionMatieresState();
}

class _GestionMatieresState extends State<GestionMatieres> {
  List<Subject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getSubjects();
      if (mounted) {
        setState(() {
          _subjects = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('loadSubjectsError'))),
        );
      }
    }
  }

  void _showSubjectDialog({Subject? subject}) {
    final nameCtrl = TextEditingController(text: subject?.name ?? '');
    final coeffCtrl = TextEditingController(
      text: subject?.coefficient.toString() ?? '1.0',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          subject == null
              ? context.tr('addSubject')
              : context.tr('editSubject'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyTextfield(
                controller: nameCtrl,
                hintText: context.tr('subjectNameExample'),
                icon: Icons.book_outlined,
              ),
              SizedBox(height: 16),
              MyTextfield(
                controller: coeffCtrl,
                hintText: context.tr('coefficient'),
                icon: Icons.star_outline,
                keyboardType: TextInputType.number,
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;

              final newSubject = Subject(
                id: subject?.id ?? '',
                name: nameCtrl.text.trim(),
                coefficient: double.tryParse(coeffCtrl.text) ?? 1.0,
              );

              try {
                await ApiService.saveSubject(newSubject);
                if (mounted) {
                  Navigator.pop(context);
                  _fetchSubjects();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur lors de l'enregistrement")),
                  );
                }
              }
            },
            child: Text(
              context.tr('validate'),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
          spacing: 12,
          runSpacing: 10,
          children: [
            Text(
              context.tr('subjectManagement'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            MyButton(
              icon: Icons.add,
              text: context.tr('addSubject'),
              onTap: () => _showSubjectDialog(),
            ),
          ],
        ),
        SizedBox(height: 24),

        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (_subjects.isEmpty)
          Center(child: Text(context.tr('noSubjects')))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final s = _subjects[index];
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
                    child: Icon(Icons.book, color: AppColors.primary),
                  ),
                  title: Text(
                    s.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Coefficient: ${s.coefficient}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => _showSubjectDialog(subject: s),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(context.tr('delete')),
                              content: Text(
                                "${context.tr('confirmDeleteSubject')} ${s.name} ?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(context.tr('no')),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(context.tr('yes')),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ApiService.deleteSubject(s.id);
                            _fetchSubjects();
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
