import 'package:edugest/components/app_colors.dart';
import 'package:edugest/components/my_button.dart';
import 'package:edugest/components/my_textfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Evenement extends StatefulWidget {
  const Evenement({super.key});

  @override
  State<Evenement> createState() => _EvenementState();
}

class _EvenementState extends State<Evenement> {
  final List<Map<String, dynamic>> _allEvents = [
    {
      'title': 'Conseil de classe 3ème',
      'date': DateTime.now().add(const Duration(days: 1)),
      'time': const TimeOfDay(hour: 14, minute: 0),
      'category': 'Conseil',
      'color': Colors.blue
    },
    {
      'title': 'Examen de Mathématiques',
      'date': DateTime.now().add(const Duration(days: 3)),
      'time': const TimeOfDay(hour: 8, minute: 30),
      'category': 'Examen',
      'color': Colors.red
    },
  ];

  String _searchQuery = "";
  String _selectedCategory = "Tous";
  final List<String> _categories = ["Tous", "Conseil", "Examen", "Réunion", "Cérémonie"];

  final TextEditingController _titleController = TextEditingController();
  DateTime _tempDate = DateTime.now();
  TimeOfDay _tempTime = TimeOfDay.now();
  String _tempCategory = "Réunion";

  List<Map<String, dynamic>> get _filteredEvents {
    return _allEvents.where((event) {
      final matchesCategory = _selectedCategory == "Tous" || event['category'] == _selectedCategory;
      final matchesSearch = event['title'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nouvel Événement"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyTextfield(
                  controller: _titleController,
                  hintText: "Titre",
                  icon: Icons.title,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _tempCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Catégorie",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _categories.where((c) => c != "Tous").map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => _tempCategory = val!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Date: ${DateFormat('dd/MM/yyyy').format(_tempDate)}", style: const TextStyle(fontSize: 13)),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _tempDate, firstDate: DateTime.now(), lastDate: DateTime(2101));
                    if (picked != null) setDialogState(() => _tempDate = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Heure: ${_tempTime.format(context)}", style: const TextStyle(fontSize: 13)),
                  trailing: const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _tempTime);
                    if (picked != null) setDialogState(() => _tempTime = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  setState(() {
                    _allEvents.add({
                      'title': _titleController.text,
                      'date': _tempDate,
                      'time': _tempTime,
                      'category': _tempCategory,
                      'color': _tempCategory == 'Examen' ? Colors.red : Colors.blue,
                    });
                    _titleController.clear();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Ajouter", style: TextStyle(color: Colors.white)),
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
        // Header flexible pour éviter l'overflow
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 10,
          children: [
            const Text(
              "Planning & Événements",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: 140,
              child: MyButton(
                icon: Icons.add,
                text: "Ajouter",
                onTap: _showAddEventDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: const InputDecoration(
              hintText: "Rechercher...",
              prefixIcon: Icon(Icons.search, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        _filteredEvents.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text("Aucun événement")))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = _filteredEvents[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (event['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.event, color: event['color'], size: 20),
                      ),
                      title: Text(
                        event['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "${DateFormat('dd/MM').format(event['date'])} à ${event['time'].format(context)}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
