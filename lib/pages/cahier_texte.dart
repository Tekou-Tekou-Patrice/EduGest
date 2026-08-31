import 'package:edugest/models/app_user.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';

class CahierTexte extends StatefulWidget {
  final AppUser? currentUser;
  const CahierTexte({super.key, this.currentUser});

  @override
  State<CahierTexte> createState() => _CahierTexteState();
}

class _CahierTexteState extends State<CahierTexte> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedClasse = 'Terminale S1';
  bool _isEditing = false;
  String? _editingId;
  
  List<Map<String, dynamic>> _myHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMyHistory();
  }

  Future<void> _fetchMyHistory() async {
    if (widget.currentUser == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getMyLessons(widget.currentUser!.id);
      setState(() {
        _myHistory = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _publishLesson() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) return;

    final lessonData = {
      if (_editingId != null) 'id': _editingId,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'className': _selectedClasse,
      'subject': 'Mathématiques', // À dynamiser selon le prof
      'date': DateTime.now().toIso8601String(),
      'teacherId': widget.currentUser?.id,
    };

    try {
      await ApiService.saveLesson(lessonData);
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _isEditing = false;
        _editingId = null;
      });
      _fetchMyHistory();
      _tabController.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cahier de texte mis à jour !")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de l'enregistrement")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? "Modification de la Leçon" : "Cahier de Texte",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 20),

        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Saisie"),
            Tab(text: "Mes Publications"),
          ],
        ),
        
        const SizedBox(height: 25),

        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSaisieView(),
              _buildHistoryView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaisieView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdown("Classe", _selectedClasse, ['6ème A', '3ème A', 'Terminale S1'], (val) => setState(() => _selectedClasse = val!)),
          const SizedBox(height: 20),
          MyTextfield(controller: _titleController, hintText: "Titre de la leçon", icon: Icons.title),
          const SizedBox(height: 20),
          TextField(
            controller: _contentController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Détaillez le cours ici...",
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: MyButton(
              icon: Icons.send,
              text: _isEditing ? "Mettre à jour" : "Publier la leçon",
              onTap: _publishLesson,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_myHistory.isEmpty) return const Center(child: Text("Aucune leçon publiée."));

    return ListView.builder(
      itemCount: _myHistory.length,
      itemBuilder: (context, index) {
        final lesson = _myHistory[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.border)),
          child: ListTile(
            title: Text(lesson['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${lesson['className']} • ${lesson['date'].toString().substring(0,10)}"),
            trailing: IconButton(
              icon: const Icon(Icons.edit_note, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _editingId = lesson['id'].toString();
                  _selectedClasse = lesson['className'];
                  _titleController.text = lesson['title'];
                  _contentController.text = lesson['content'];
                  _tabController.animateTo(0);
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown(String label, String val, List<String> items, Function(String?) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
          child: DropdownButton<String>(
            value: val,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChange,
          ),
        ),
      ],
    );
  }
}
