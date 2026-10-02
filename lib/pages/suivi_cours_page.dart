import 'package:edugest/models/app_user.dart';
import 'package:edugest/pages/cahier_texte.dart';
import 'package:edugest/pages/programme_page.dart';
import 'package:edugest/pages/reception_cahier_texte.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class SuiviCoursPage extends StatelessWidget {
  final AppUser currentUser;

  const SuiviCoursPage({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final canWrite = currentUser.role == UserRole.enseignant;

    return DefaultTabController(
      length: 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.hasBoundedHeight
              ? (constraints.maxHeight - 140).clamp(1.0, 700.0)
              : 700.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('courseTracking'),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('courseTrackingDescription'),
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(
                    icon: Icon(Icons.menu_book),
                    text: context.tr('lessonBookTab'),
                  ),
                  Tab(
                    icon: Icon(Icons.assignment),
                    text: context.tr('courseProgramTab'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: availableHeight,
                child: TabBarView(
                  children: [
                    canWrite
                        ? CahierTexte(currentUser: currentUser)
                        : const ReceptionCahierTexte(),
                    ProgrammePage(currentUser: currentUser),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
