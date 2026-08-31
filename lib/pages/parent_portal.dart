import 'package:edugest/models/app_user.dart';
import 'package:edugest/models/absence.dart';
import 'package:edugest/models/grade.dart';
import 'package:edugest/models/sanction.dart';
import 'package:edugest/models/event.dart';
import 'package:edugest/models/payment.dart';
import 'package:edugest/models/student.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';

/// Read-only space. The child list is supplied by the dedicated parent endpoint.
class ParentPortal extends StatefulWidget {
  final AppUser parent;
  const ParentPortal({super.key, required this.parent});

  @override
  State<ParentPortal> createState() => _ParentPortalState();
}

class _ParentPortalState extends State<ParentPortal> {
  late Future<List<Student>> _children;
  Student? _selected;

  @override
  void initState() {
    super.initState();
    _children = ApiService.getParentStudents(widget.parent.id);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Student>>(
        future: _children,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) return const Text("Impossible de charger les informations de vos enfants.");
          final children = snapshot.data ?? [];
          if (children.isEmpty) return const Text("Aucun enfant n'est associé à ce compte Parent.");
          _selected ??= children.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Espace Parent", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text("Consultez uniquement les informations de vos enfants."),
              const SizedBox(height: 18),
              DropdownButtonFormField<Student>(
                initialValue: _selected,
                decoration: const InputDecoration(labelText: "Enfant", border: OutlineInputBorder()),
                items: children.map((s) => DropdownMenuItem(value: s, child: Text('${s.fullName} — ${s.className}'))).toList(),
                onChanged: (s) => setState(() => _selected = s),
              ),
              const SizedBox(height: 18),
              DefaultTabController(
                length: 7,
                child: Column(
                  children: [
                    const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'Notes'),
                        Tab(text: 'Absences'),
                        Tab(text: 'Discipline'),
                        Tab(text: 'Bulletin'),
                        Tab(text: 'Cahier de texte'),
                        Tab(text: 'Événements'),
                        Tab(text: 'Paiements'),
                      ],
                    ),
                    SizedBox(
                      height: 360,
                      child: TabBarView(children: [
                        _GradesView(student: _selected!),
                        _AbsencesView(student: _selected!),
                        _SanctionsView(student: _selected!),
                        _BulletinView(student: _selected!),
                        _NotebookView(student: _selected!),
                        const _EventsView(),
                        _PaymentsView(student: _selected!, parentUserId: widget.parent.id),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
}

class _GradesView extends StatelessWidget {
  final Student student;
  const _GradesView({required this.student});
  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: ApiService.getExams(className: student.className),
        builder: (context, examsSnapshot) {
          final exams = examsSnapshot.data ?? [];
          if (examsSnapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (exams.isEmpty) return const Center(child: Text('Aucune note publiée.'));
          return FutureBuilder<List<Grade>>(
            future: Future.wait<List<Grade>>(
              exams.map((exam) => ApiService.getGradesByExam(exam.id)),
            ).then((sets) => sets.expand((x) => x).where((g) => g.studentId == student.id).toList()),
            builder: (context, gradesSnapshot) {
              final grades = gradesSnapshot.data ?? [];
              if (gradesSnapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
              if (grades.isEmpty) return const Center(child: Text('Aucune note publiée.'));
              return ListView(children: grades.map((g) => ListTile(title: Text('Évaluation ${g.examId}'), trailing: Text('${g.score.toStringAsFixed(2)} / 20'))).toList());
            },
          );
        },
      );
}

class _AbsencesView extends StatelessWidget {
  final Student student;
  const _AbsencesView({required this.student});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Absence>>(
        future: ApiService.getAbsences(),
        builder: (context, snapshot) {
          final data = (snapshot.data ?? []).where((a) => a.studentId == student.id).toList();
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          return data.isEmpty ? const Center(child: Text('Aucune absence enregistrée.')) : ListView(children: data.map((a) => ListTile(title: Text(a.period), subtitle: Text(a.reason.isEmpty ? 'Sans motif' : a.reason))).toList());
        },
      );
}

class _SanctionsView extends StatelessWidget {
  final Student student;
  const _SanctionsView({required this.student});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Sanction>>(
        future: ApiService.getSanctions(),
        builder: (context, snapshot) {
          final data = (snapshot.data ?? []).where((s) => s.studentId == student.id).toList();
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          return data.isEmpty ? const Center(child: Text('Aucune sanction enregistrée.')) : ListView(children: data.map((s) => ListTile(title: Text(s.type), subtitle: Text(s.reason))).toList());
        },
      );
}

class _BulletinView extends StatelessWidget {
  final Student student;
  const _BulletinView({required this.student});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.assignment_turned_in_outlined, size: 52),
          const SizedBox(height: 12),
          Text('Bulletin de ${student.fullName}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Les notes et absences affichées dans les autres onglets composent le bulletin.'),
        ]),
      );
}

class _NotebookView extends StatelessWidget {
      final Student student;
      const _NotebookView({required this.student});

      @override
      Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
            future: ApiService.getLessonsByClass(student.className),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final lessons = snapshot.data ?? [];
              if (lessons.isEmpty) return const Center(child: Text('Aucun contenu de cahier publié.'));
              return ListView(
                children: lessons.map((lesson) => ListTile(
                  title: Text(lesson['title']?.toString() ?? lesson['subject']?.toString() ?? 'Cours'),
                  subtitle: Text(lesson['content']?.toString() ?? lesson['description']?.toString() ?? ''),
                )).toList(),
              );
            },
          );
}

class _EventsView extends StatelessWidget {
      const _EventsView();

      @override
      Widget build(BuildContext context) => FutureBuilder<List<Event>>(
            future: ApiService.getEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) return const Center(child: Text('Aucun événement annoncé.'));
              return ListView(
                children: events.map((event) => ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(event.title),
                  subtitle: Text(event.description.isEmpty ? event.category : event.description),
                  trailing: Text('${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}'),
                )).toList(),
              );
            },
          );
}

class _PaymentsView extends StatelessWidget {
      final Student student;
      final String parentUserId;
      const _PaymentsView({required this.student, required this.parentUserId});

      @override
      Widget build(BuildContext context) => FutureBuilder<List<Payment>>(
            future: ApiService.getParentPayments(parentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final payments = (snapshot.data ?? [])
                  .where((payment) => payment.studentId == student.id)
                  .toList();
              if (payments.isEmpty) return const Center(child: Text('Aucun paiement enregistré pour cet enfant.'));
              return ListView(
                children: payments.map((payment) => ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text('${payment.amount.toStringAsFixed(0)} FCFA'),
                  subtitle: Text(payment.description),
                  trailing: Text('${payment.date.day.toString().padLeft(2, '0')}/${payment.date.month.toString().padLeft(2, '0')}'),
                )).toList(),
              );
            },
          );
}
