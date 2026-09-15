import 'package:edugest/models/absence.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'package:intl/intl.dart';
import '../components/app_colors.dart';
import '../components/my_textfield.dart';

class Absences extends StatefulWidget {
  Absences({super.key});

  @override
  State<Absences> createState() => _AbsencesState();
}

class _AbsencesState extends State<Absences> {
  String selectedFilter = 'Toutes';
  List<Absence> _absences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAbsences();
  }

  Future<void> _fetchAbsences() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAbsences();
      if (!mounted) return;
      setState(() {
        _absences = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('loadAbsencesError'))));
    }
  }

  void _showReportDialog() {
    final nameCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String period = context.tr('fullDay');
    bool justified = false;
    final periods = [
      context.tr('morning'),
      context.tr('afternoon'),
      context.tr('fullDay'),
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('reportAbsence')),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyTextfield(
                  controller: nameCtrl,
                  hintText: context.tr('studentNameHint'),
                  icon: Icons.person,
                ),
                SizedBox(height: 12),
                MyTextfield(
                  controller: classCtrl,
                  hintText: context.tr('classLabel'),
                  icon: Icons.class_,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: period,
                  decoration: InputDecoration(
                    labelText: context.tr('period'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: periods
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => period = v!),
                ),
                SizedBox(height: 12),
                MyTextfield(
                  controller: reasonCtrl,
                  hintText: context.tr('reason'),
                  icon: Icons.notes,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('justified')),
                  value: justified,
                  onChanged: (v) => setDialogState(() => justified = v),
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
                backgroundColor: AppColors.danger,
              ),
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                try {
                  await ApiService.saveAbsence(
                    Absence(
                      id: '',
                      studentId: 'AUTO',
                      studentName: nameCtrl.text.trim(),
                      className: classCtrl.text.trim().isEmpty
                          ? 'N/A'
                          : classCtrl.text.trim(),
                      date: DateTime.now(),
                      period: period,
                      reason: reasonCtrl.text.trim(),
                      isJustified: justified,
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                  await _fetchAbsences();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('saveError'))),
                    );
                  }
                }
              },
              child: Text(
                context.tr('report'),
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
    final filteredList = _absences
        .where(
          (a) => selectedFilter == 'Toutes' || a.className == selectedFilter,
        )
        .toList();

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
              "Suivi des Absences",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showReportDialog,
              icon: Icon(Icons.add_alert, color: Colors.white, size: 18),
              label: Text(
                context.tr('report'),
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (_absences.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(context.tr('noAbsences')),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final a = filteredList[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: a.isJustified
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                      child: Icon(
                        a.isJustified ? Icons.check : Icons.close,
                        color: a.isJustified ? Colors.green : Colors.red,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.studentName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${a.className} • ${a.period} • ${DateFormat('dd/MM/yyyy').format(a.date)}",
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          if (a.reason.isNotEmpty)
                            Text(a.reason, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      a.isJustified
                          ? context.tr('justified')
                          : context.tr('notJustified'),
                      style: TextStyle(
                        color: a.isJustified ? Colors.green : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
