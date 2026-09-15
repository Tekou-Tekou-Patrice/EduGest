import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'package:intl/intl.dart';
import '../components/app_colors.dart';

class ReceptionCahierTexte extends StatefulWidget {
  const ReceptionCahierTexte({super.key});

  @override
  State<ReceptionCahierTexte> createState() => _ReceptionCahierTexteState();
}

class _ReceptionCahierTexteState extends State<ReceptionCahierTexte> {
  List<Map<String, dynamic>> _lessons = [];
  bool _isLoading = true;
  String? selectedClasse;

  @override
  void initState() {
    super.initState();
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    setState(() => _isLoading = true);
    try {
      final data = selectedClasse != null && selectedClasse!.isNotEmpty
          ? await ApiService.getLessonsByClass(selectedClasse!)
          : await ApiService.getAllLessons();
      if (!mounted) return;
      setState(() {
        _lessons = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.friendlyErrorMessage(e))),
      );
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final classes =
        _lessons
            .map((l) => l['className']?.toString() ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Suivi des Cahiers de Texte",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 20),
        if (classes.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<String>(
              value: selectedClasse,
              hint: const Text("Toutes les classes"),
              isExpanded: true,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text("Toutes les classes"),
                ),
                ...classes.map(
                  (c) => DropdownMenuItem(value: c, child: Text("Classe : $c")),
                ),
              ],
              onChanged: (val) {
                setState(() => selectedClasse = val);
                _fetchLessons();
              },
            ),
          ),
        const SizedBox(height: 25),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_lessons.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(context.tr('noPublishedLessons')),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lessons.length,
            itemBuilder: (context, index) {
              final lesson = _lessons[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryPale,
                    child: Icon(Icons.menu_book, color: AppColors.primary),
                  ),
                  title: Text(
                    lesson['title']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${lesson['subject']} • ${lesson['className']}\n${_formatDate(lesson['date'])}"
                    "${lesson['teacherName']?.toString().trim().isNotEmpty == true ? ' • Par ${lesson['teacherName']}' : ''}",
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
      ],
    );
  }
}
