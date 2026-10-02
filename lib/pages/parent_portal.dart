import 'package:edugest/models/app_user.dart';
import 'package:edugest/models/absence.dart';
import 'package:edugest/models/grade.dart';
import 'package:edugest/models/event.dart';
import 'package:edugest/models/payment.dart';
import 'package:edugest/models/bulletin_publication.dart';
import 'package:edugest/pages/programme_page.dart';
import 'package:edugest/models/student.dart';
import 'package:edugest/models/exam_class.dart';
import 'package:edugest/pages/login_page.dart';
import 'package:edugest/pages/profil.dart';
import 'package:edugest/pages/school_selection_page.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/auth_session_service.dart';
import 'package:edugest/service/notification_service.dart';
import 'package:edugest/service/export_service.dart';
import 'package:edugest/components/export_language_dialog.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'package:intl/intl.dart';

/// Read-only space. The child list is supplied by the dedicated parent endpoint.
class ParentPortal extends StatefulWidget {
  final AppUser parent;
  ParentPortal({super.key, required this.parent});

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
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SchoolSelectionPage(user: widget.parent),
        ),
      );
    },
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: context.tr('changeSchool'),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SchoolSelectionPage(user: widget.parent),
              ),
            );
          },
        ),
        title: Text(context.tr('parentSpace')),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz),
            tooltip: context.tr('changeSchool'),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SchoolSelectionPage(user: widget.parent),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person_outline),
            tooltip: context.tr('myProfile'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(context.tr('myProfile'))),
                    body: SafeArea(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Profil(user: widget.parent),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: context.tr('logout'),
            onPressed: () async {
              NotificationService.instance.stop();
              ApiService.activeSchoolId = null;
              ApiService.clearActiveUser();
              await AuthSessionService.clearSession();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: FutureBuilder<List<Student>>(
            future: _children,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Text(context.tr('parentChildrenLoadError'));
              }
              final children = snapshot.data ?? [];
              if (children.isEmpty) {
                return Text(context.tr('noChildren'));
              }
              _selected ??= children.first;
              final double tabViewHeight =
                  (MediaQuery.of(context).size.height * 0.55).clamp(
                    360.0,
                    700.0,
                  );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('parentSpace'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(context.tr('parentReadOnly')),
                  SizedBox(height: 18),
                  DropdownButtonFormField<Student>(
                    initialValue: _selected,
                    decoration: InputDecoration(
                      labelText: context.tr('auto_enfant'),
                      border: OutlineInputBorder(),
                    ),
                    items: children
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s.fullName} — ${s.className}'),
                          ),
                        )
                        .toList(),
                    onChanged: (s) => setState(() => _selected = s),
                  ),
                  SizedBox(height: 18),
                  DefaultTabController(
                    length: 7,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          tabs: [
                            Tab(text: context.tr('myNotes')),
                            Tab(text: context.tr('schoolAbsences')),
                            Tab(text: context.tr('bulletins')),
                            Tab(text: context.tr('programTracking')),
                            Tab(text: context.tr('events')),
                            Tab(text: context.tr('payments')),
                            Tab(text: context.tr('exam')),
                          ],
                        ),
                        SizedBox(
                          height: tabViewHeight,
                          child: TabBarView(
                            children: [
                              _GradesView(student: _selected!),
                              _AbsencesView(student: _selected!),
                              _PublishedBulletinView(student: _selected!),
                              ProgrammePage(currentUser: widget.parent),
                              _EventsView(),
                              _PaymentsView(
                                student: _selected!,
                                parentUserId: widget.parent.id,
                              ),
                              _ParentExamView(student: _selected!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _ParentExamView extends StatelessWidget {
  final Student student;

  _ParentExamView({required this.student});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentExamStatus?>(
      future: ApiService.getParentExamStatus(studentId: student.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              context.tr('parentExamLoadError'),
              textAlign: TextAlign.center,
            ),
          );
        }
        final status = snapshot.data;
        if (status == null) {
          return Center(
            child: Text(
              context.tr('parentExamUnavailable'),
              textAlign: TextAlign.center,
            ),
          );
        }
        final complete = status.dossierComplete && status.feesComplete;
        return ListView(
          padding: EdgeInsets.symmetric(vertical: 8),
          children: [
            Card(
              color: complete ? Colors.green.shade50 : Colors.orange.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      complete ? Icons.verified : Icons.assignment_late,
                      color: complete ? Colors.green : Colors.orange,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        complete
                            ? '${context.tr('statusUpToDate')}\n${context.tr('parentExamComplete').replaceAll('{student}', student.fullName)}'
                            : '${context.tr('statusNotUpToDate')}\n${context.tr('parentExamIncomplete').replaceAll('{student}', student.fullName)}',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.payments_outlined),
              title: Text(context.tr('officialFees')),
              subtitle: Text(
                '${status.paidAmount.toInt()} / ${status.officialFee.toInt()} FCFA',
              ),
              trailing: Icon(
                status.feesComplete ? Icons.check_circle : Icons.pending,
                color: status.feesComplete ? Colors.green : Colors.orange,
              ),
            ),
            Divider(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                context.tr('requiredDocuments'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...status.documents.map(
              (document) => ListTile(
                dense: true,
                leading: Icon(
                  document.submitted ? Icons.check_circle : Icons.cancel,
                  color: document.submitted ? Colors.green : Colors.red,
                ),
                title: Text(document.name),
                subtitle: Text(
                  document.required
                      ? context.tr('required')
                      : context.tr('optional'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GradesView extends StatelessWidget {
  final Student student;
  _GradesView({required this.student});
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: ApiService.getExams(className: student.className),
    builder: (context, examsSnapshot) {
      final exams = examsSnapshot.data ?? [];
      if (examsSnapshot.connectionState != ConnectionState.done) {
        return Center(child: CircularProgressIndicator());
      }
      if (exams.isEmpty) {
        return Center(child: Text(context.tr('noPublishedGrades')));
      }
      return FutureBuilder<List<Grade>>(
        future:
            Future.wait<List<Grade>>(
              exams.map((exam) => ApiService.getGradesByExam(exam.id)),
            ).then(
              (sets) => sets
                  .expand((x) => x)
                  .where((g) => g.studentId == student.id)
                  .toList(),
            ),
        builder: (context, gradesSnapshot) {
          final grades = gradesSnapshot.data ?? [];
          if (gradesSnapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          if (grades.isEmpty) {
            return Center(child: Text(context.tr('noPublishedGrades')));
          }
          return ListView(
            children: grades
                .map(
                  (g) => ListTile(
                    title: Text(
                      exams
                              .where((exam) => exam.id == g.examId)
                              .map(
                                (exam) => exam.subject.isNotEmpty
                                    ? exam.subject
                                    : exam.title,
                              )
                              .firstOrNull ??
                          '${context.tr('evaluation')} ${g.examId}',
                    ),
                    subtitle: Text(
                      exams
                              .where((exam) => exam.id == g.examId)
                              .map(
                                (exam) =>
                                    'Coefficient ${exam.coefficient.toStringAsFixed(2)}',
                              )
                              .firstOrNull ??
                          '${context.tr('evaluation')} ${g.examId}',
                    ),
                    trailing: Text('${g.score.toStringAsFixed(2)} / 20'),
                  ),
                )
                .toList(),
          );
        },
      );
    },
  );
}

class _AbsencesView extends StatelessWidget {
  final Student student;
  _AbsencesView({required this.student});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Absence>>(
    future: ApiService.getAbsences(),
    builder: (context, snapshot) {
      final data = (snapshot.data ?? [])
          .where((a) => a.studentId == student.id)
          .toList();
      if (snapshot.connectionState != ConnectionState.done) {
        return Center(child: CircularProgressIndicator());
      }
      return data.isEmpty
          ? Center(child: Text(context.tr('noRecordedAbsences')))
          : ListView(
              children: data
                  .map(
                    (a) => ListTile(
                      title: Text(a.period),
                      subtitle: Text(
                        a.reason.isEmpty ? 'Sans motif' : a.reason,
                      ),
                    ),
                  )
                  .toList(),
            );
    },
  );
}

class _PublishedBulletinView extends StatelessWidget {
  final Student student;
  _PublishedBulletinView({required this.student});

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: ApiService.getBulletinPublications(studentId: student.id),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Center(child: CircularProgressIndicator());
      }
      final publications =
          (snapshot.data ?? [])
              .where(
                (publication) =>
                    publication.published &&
                    (publication.studentId == null ||
                        publication.studentId!.isEmpty ||
                        publication.studentId == student.id),
              )
              .toList()
            ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      if (publications.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 52),
                SizedBox(height: 12),
                Text(
                  '${context.tr('noPublishedBulletin')} ${student.fullName}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  context.tr('bulletinPendingPublication'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return ListView(
        children: publications
            .map(
              (publication) => Card(
                child: ListTile(
                  leading: Icon(
                    Icons.assignment_turned_in,
                    color: Colors.green,
                  ),
                  title: Text(
                    '${context.tr('reportCard')} — '
                    '${AppLocalizations.of(context).translateAcademicPeriod(publication.period)}',
                  ),
                  subtitle: Text(
                    '${context.tr('publishedOn')} ${DateFormat('dd/MM/yyyy HH:mm').format(publication.publishedAt)}\n'
                    '${context.tr('by')} ${publication.publishedBy} (${publication.publishedByRole})\n'
                    '${context.tr('bulletinLanguage')}: ${context.tr(publication.languageCode == 'en' ? 'languageEnglish' : 'languageFrench')}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: Icon(Icons.picture_as_pdf, color: Colors.red),
                    tooltip: context.tr('viewReportPdf'),
                    onPressed: () => _downloadBulletin(context, publication),
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
  Future<void> _downloadBulletin(
    BuildContext context,
    BulletinPublication publication,
  ) async {
    final languageCode = await ExportLanguageDialog.show(
      context,
      initialLanguageCode: Localizations.localeOf(context).languageCode,
    );
    if (languageCode == null || !context.mounted) return;
    try {
      final exams = await ApiService.getExams(className: publication.className);
      final grades = <Grade>[];
      for (final exam in exams) {
        final examGrades = await ApiService.getGradesByExam(exam.id);
        grades.addAll(
          examGrades.where((grade) => grade.studentId == student.id),
        );
      }
      final absences = (await ApiService.getAbsences())
          .where((absence) => absence.studentId == student.id)
          .toList();
      final schoolInfo = await ApiService.getSchoolInfo();
      await ExportService.generateBulletinPdf(
        student: student,
        grades: grades,
        exams: exams,
        absences: absences,
        schoolInfo: schoolInfo,
        period: publication.period,
        promotionThreshold: publication.promotionThreshold ?? 10,
        reportClassName: publication.className,
        languageCode: languageCode,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.tr('bulletinPdfError')} '
              '${ApiService.friendlyErrorMessage(error)}',
            ),
          ),
        );
      }
    }
  }
}

class _EventsView extends StatelessWidget {
  _EventsView();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Event>>(
    future: ApiService.getEvents(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Center(child: CircularProgressIndicator());
      }
      final events = snapshot.data ?? [];
      if (events.isEmpty) {
        return Center(child: Text(context.tr('noAnnouncedEvents')));
      }
      return ListView(
        children: events
            .map(
              (event) => ListTile(
                leading: Icon(Icons.event),
                title: Text(event.title),
                subtitle: Text(
                  event.description.isEmpty
                      ? event.category
                      : event.description,
                ),
                trailing: Text(
                  '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}',
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _PaymentsView extends StatelessWidget {
  final Student student;
  final String parentUserId;
  _PaymentsView({required this.student, required this.parentUserId});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Payment>>(
    future: ApiService.getParentPayments(parentUserId),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Center(child: CircularProgressIndicator());
      }
      final payments = (snapshot.data ?? [])
          .where((payment) => payment.studentId == student.id)
          .toList();
      if (payments.isEmpty) {
        return Center(child: Text(context.tr('noChildPayments')));
      }
      return ListView(
        children: payments
            .map(
              (payment) => ListTile(
                leading: Icon(Icons.payments_outlined),
                title: Text('${payment.amount.toStringAsFixed(0)} FCFA'),
                subtitle: Text(payment.description),
                trailing: Text(
                  '${payment.date.day.toString().padLeft(2, '0')}/${payment.date.month.toString().padLeft(2, '0')}',
                ),
              ),
            )
            .toList(),
      );
    },
  );
}
