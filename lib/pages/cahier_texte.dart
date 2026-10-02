import 'package:edugest/models/app_user.dart';
import 'package:edugest/models/school_class.dart';
import 'package:edugest/models/subject.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';

class CahierTexte extends StatefulWidget {
  final AppUser? currentUser;
  CahierTexte({super.key, this.currentUser});

  @override
  State<CahierTexte> createState() => _CahierTexteState();
}

class _CahierTexteState extends State<CahierTexte>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedClasse;
  String? _selectedSubject;
  List<SchoolClass> _classes = [];
  List<Subject> _subjects = [];
  bool _isEditing = false;
  String? _editingId;

  List<Map<String, dynamic>> _myHistory = [];
  bool _isLoading = true;

  bool get _canWriteNotebook => widget.currentUser?.role == UserRole.enseignant;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOptions();
    _fetchMyHistory();
  }

  Future<void> _fetchOptions() async {
    try {
      final results = await Future.wait([
        ApiService.getClassrooms(),
        ApiService.getSubjects(),
      ]);
      if (!mounted) return;
      setState(() {
        _classes = results[0] as List<SchoolClass>;
        _subjects = results[1] as List<Subject>;
        _selectedClasse ??= _classes.isEmpty ? null : _classes.first.name;
        _selectedSubject ??= _subjects.isEmpty ? null : _subjects.first.name;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.friendlyErrorMessage(error))),
        );
      }
    }
  }

  Future<void> _fetchMyHistory() async {
    if (widget.currentUser == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getMyLessons(widget.currentUser!.id);
      if (!mounted) return;
      setState(() {
        _myHistory = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _publishLesson() async {
    if (!_canWriteNotebook) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('teacherOnlyLessonBook'))),
      );
      return;
    }
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedClasse == null ||
        _selectedSubject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('selectClassSubject'))));
      return;
    }

    final lessonData = {
      if (_editingId != null) 'id': _editingId,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'className': _selectedClasse,
      'subject': _selectedSubject,
      'date': DateTime.now().toIso8601String(),
      'teacherId': widget.currentUser?.id,
      'teacherName': widget.currentUser?.name,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('lessonBookUpdated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.friendlyErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canWriteNotebook) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('lessonBookPreview'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 8),
          Text(context.tr('teacherOnlyLessonBook')),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.hasBoundedHeight
            ? (constraints.maxHeight - 130).clamp(1.0, 600.0)
            : 600.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing
                  ? context.tr('lessonEditing')
                  : context.tr('lessonBook'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 20),

            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              isScrollable: true,
              tabs: [
                Tab(text: context.tr('entryTab')),
                Tab(text: context.tr('myPosts')),
              ],
            ),

            SizedBox(height: 25),

            SizedBox(
              height: availableHeight,
              child: TabBarView(
                controller: _tabController,
                children: [_buildSaisieView(), _buildHistoryView()],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSaisieView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdown(
            context.tr('classLabel'),
            _selectedClasse,
            _classes.map((item) => item.name).toList(),
            (val) => setState(() => _selectedClasse = val),
          ),
          SizedBox(height: 20),
          _buildDropdown(
            context.tr('subject'),
            _selectedSubject,
            _subjects.map((item) => item.name).toList(),
            (val) => setState(() => _selectedSubject = val),
          ),
          SizedBox(height: 20),
          MyTextfield(
            controller: _titleController,
            hintText: context.tr('lessonTitleHint'),
            icon: Icons.title,
          ),
          SizedBox(height: 20),
          TextField(
            controller: _contentController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: context.tr('lessonDetailHint'),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: MyButton(
              icon: Icons.send,
              text: _isEditing
                  ? context.tr('update')
                  : context.tr('publishLesson'),
              onTap: _publishLesson,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_myHistory.isEmpty) {
      return Center(child: Text(context.tr('noPublishedLessons')));
    }

    return ListView.builder(
      itemCount: _myHistory.length,
      itemBuilder: (context, index) {
        final lesson = _myHistory[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            title: Text(
              lesson['title']?.toString() ?? '',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${lesson['className']} • ${lesson['date'].toString().substring(0, 10)}"
              "${lesson['teacherName']?.toString().trim().isNotEmpty == true ? ' • Par ${lesson['teacherName']}' : ''}",
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit_note, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _editingId = lesson['id'].toString();
                  _selectedClasse = lesson['className']?.toString();
                  _selectedSubject = lesson['subject']?.toString();
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

  Widget _buildDropdown(
    String label,
    String? val,
    List<String> items,
    Function(String?) onChange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: items.contains(val) ? val : null,
            isExpanded: true,
            underline: SizedBox(),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChange,
          ),
        ),
      ],
    );
  }
}
