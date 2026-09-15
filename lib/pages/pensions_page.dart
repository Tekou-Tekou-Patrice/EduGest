import 'package:edugest/components/app_colors.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class PensionsPage extends StatefulWidget {
  const PensionsPage({super.key});

  @override
  State<PensionsPage> createState() => _PensionsPageState();
}

class _PensionsPageState extends State<PensionsPage> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final students = await ApiService.getTuitionStatus();
      if (!mounted) return;
      setState(() {
        _students = students;
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

  double _amount(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final student in _students) {
      final className = student['className']?.toString().trim();
      grouped
          .putIfAbsent(
            className == null || className.isEmpty
                ? context.tr('classNotProvided')
                : className,
            () => [],
          )
          .add(student);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('tuitionTrackingByClass'),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.tr('tuitionTrackingDescription'),
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_students.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text(context.tr('noStudentsRegistered'))),
            ),
          )
        else
          ...grouped.entries.map((entry) {
            final completed = entry.value
                .where((s) => s['tuitionCompleted'] == true)
                .length;
            final pending = entry.value.length - completed;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '$completed ${context.tr('upToDate').toLowerCase()} • '
                  '$pending ${context.tr('withBalance')}',
                ),
                children: entry.value.map((student) {
                  final isCompleted = student['tuitionCompleted'] == true;
                  final remaining = _amount(student['remaining']);
                  return ListTile(
                    leading: Icon(
                      isCompleted
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      color: isCompleted ? Colors.green : Colors.orange,
                    ),
                    title: Text(student['studentName']?.toString() ?? ''),
                    subtitle: Text(
                      isCompleted
                          ? context.tr('tuitionCompleted')
                          : '${context.tr('remainingToPay')} ${remaining.toStringAsFixed(0)} FCFA',
                    ),
                    trailing: Text(
                      isCompleted
                          ? context.tr('upToDate')
                          : context.tr('toPay'),
                      style: TextStyle(
                        color: isCompleted ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
      ],
    );
  }
}
