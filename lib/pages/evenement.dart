import 'package:edugest/components/app_colors.dart';
import 'package:edugest/components/my_button.dart';
import 'package:edugest/models/event.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'package:intl/intl.dart';

class Evenement extends StatefulWidget {
  const Evenement({super.key});

  @override
  State<Evenement> createState() => _EvenementState();
}

class _EvenementState extends State<Evenement> {
  List<Event> _events = [];
  bool _isLoading = true;
  String _selectedCategory = "Tous";
  final List<String> _categories = [
    "Tous",
    "Annonce",
    "Conseil",
    "Examen",
    "Réunion",
    "Cérémonie",
  ];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getEvents();
      if (!mounted) return;
      setState(() {
        _events = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('loadEventsError'))));
    }
  }

  void _showEventDialog({Event? event}) {
    final titleController = TextEditingController(text: event?.title ?? '');
    DateTime tempDate = event?.date ?? DateTime.now();
    TimeOfDay tempTime = event?.time ?? TimeOfDay.now();
    String tempCategory = event?.category ?? "Réunion";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            event == null ? context.tr('newEvent') : context.tr('editEvent'),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  maxLines: tempCategory == "Annonce" ? 6 : 1,
                  decoration: InputDecoration(
                    labelText: tempCategory == "Annonce"
                        ? "Contenu de l'annonce"
                        : context.tr('auto_titre'),
                    hintText: tempCategory == "Annonce"
                        ? "Saisissez le contenu de l'annonce"
                        : null,
                    prefixIcon: Icon(
                      tempCategory == "Annonce"
                          ? Icons.campaign_outlined
                          : Icons.title,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignLabelWithHint: tempCategory == "Annonce",
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: tempCategory,
                  decoration: InputDecoration(
                    labelText: context.tr('category'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: _categories
                      .where((c) => c != "Tous")
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setDialogState(() => tempCategory = val);
                  },
                ),
                SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Date: ${DateFormat('dd/MM/yyyy').format(tempDate)}",
                    ),
                    trailing: Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setDialogState(() => tempDate = picked);
                      }
                    },
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Heure: ${tempTime.format(context)}"),
                    trailing: Icon(Icons.access_time, color: AppColors.primary),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: tempTime,
                      );
                      if (picked != null) {
                        setDialogState(() => tempTime = picked);
                      }
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
                if (titleController.text.isEmpty) return;
                final newEvent = Event(
                  id: event?.id ?? '',
                  title: titleController.text.trim(),
                  date: tempDate,
                  time: tempTime,
                  category: tempCategory,
                );
                try {
                  await ApiService.saveEvent(newEvent);
                  if (context.mounted) Navigator.pop(context);
                  await _fetchEvents();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erreur lors de l'enregistrement"),
                      ),
                    );
                  }
                }
              },
              child: Text(
                context.tr('save'),
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
    final filteredEvents = _events
        .where(
          (e) => _selectedCategory == "Tous" || e.category == _selectedCategory,
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
              context.tr('events'),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            MyButton(
              icon: Icons.add,
              text: context.tr('add'),
              onTap: () => _showEventDialog(),
            ),
          ],
        ),
        SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((c) {
              final selected = _selectedCategory == c;
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 20),
        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (filteredEvents.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(context.tr('noEvents')),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final e = filteredEvents[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryPale,
                      child: Icon(Icons.event, color: AppColors.primary),
                    ),
                    title: Text(
                      e.title,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${e.category} • ${DateFormat('dd/MM/yyyy').format(e.date)} à ${e.time.format(context)}",
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        try {
                          await ApiService.deleteEvent(e.id);
                          await _fetchEvents();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Suppression impossible")),
                            );
                          }
                        }
                      },
                    ),
                    onTap: () => _showEventDialog(event: e),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
