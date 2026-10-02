import 'package:edugest/components/responsive_layout.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/pages/absences.dart';
import 'package:edugest/pages/cahier_texte.dart';
import 'package:edugest/pages/depenses.dart';
import 'package:edugest/pages/discipline.dart';
import 'package:edugest/pages/emploi_du_temps.dart';
import 'package:edugest/pages/evenement.dart';
import 'package:edugest/pages/gestion_classes.dart';
import 'package:edugest/pages/gestion_matieres.dart';
import 'package:edugest/pages/gestion_staff.dart';
import 'package:edugest/pages/liste_eleves.dart';
import 'package:edugest/pages/liste_enseignant.dart';
import 'package:edugest/pages/login_page.dart';
import 'package:edugest/pages/notes.dart';
import 'package:edugest/pages/paiements.dart';
import 'package:edugest/pages/parametres.dart';
import 'package:edugest/pages/profil.dart';
import 'package:edugest/pages/reception_notes.dart';
import 'package:edugest/pages/reception_cahier_texte.dart';
import 'package:edugest/pages/reception_evenements.dart';
import 'package:edugest/pages/appel_page.dart';
import 'package:edugest/localization/app_localizations.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/auth_session_service.dart';
import 'package:edugest/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:edugest/pages/recap_annees.dart';
import 'package:edugest/pages/bulletins_page.dart';
import 'package:edugest/pages/programme_page.dart';
import 'package:edugest/pages/teacher_room_check_page.dart';
import 'package:edugest/pages/staff_attendance_page.dart';
import 'package:edugest/pages/pensions_page.dart';
import 'package:edugest/pages/exam_classes_page.dart';
import 'package:edugest/pages/suivi_cours_page.dart';
import 'package:edugest/pages/school_selection_page.dart';
import 'package:edugest/models/school_info.dart';
import 'package:edugest/service/school_notifier.dart';
import '../components/app_colors.dart';
import '../components/my_sidebar.dart';

class DashboardPage extends StatefulWidget {
  final AppUser currentUser;
  DashboardPage({super.key, required this.currentUser});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedTab = 'dashboard';
  int _studentCount = 0;
  int _staffCount = 0;
  num _financeReceived = 0;
  bool _isStatsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveStats();
    if (widget.currentUser.role == UserRole.parent) {
      selectedTab = 'receptionNotes';
    }
  }

  Future<void> _loadLiveStats() async {
    try {
      final students = await ApiService.getStudents();
      final staff = await ApiService.getAllStaff();
      final stats = await ApiService.getFinanceStats();
      if (mounted) {
        setState(() {
          _studentCount = students.length;
          _staffCount = staff.length;
          final revenue =
              stats['totalRevenue'] ??
              stats['totalReceived'] ??
              stats['totalIncomes'] ??
              0;
          _financeReceived = revenue is num
              ? revenue
              : num.tryParse(revenue.toString()) ?? 0;
          _isStatsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isStatsLoading = false);
    }
  }

  void _handleNavigation(String tabName, BuildContext context) {
    setState(() => selectedTab = tabName);
    if (ResponsiveLayout.isMobile(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _logout() async {
    NotificationService.instance.stop();
    ApiService.activeSchoolId = null;
    ApiService.clearActiveUser();
    await AuthSessionService.clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  String _schoolLevel() {
    return currentSchoolNotifier.value?.schoolLevel ?? 'COLLEGE';
  }

  bool _isPrimarySchool() => _schoolLevel() == 'PRIMARY';

  String _displayUserRole() {
    return context.trRole(
      widget.currentUser.role.name,
      schoolLevel: _schoolLevel(),
    );
  }

  String _tabLabel(AppLocalizations loc, String tabKey) {
    switch (tabKey) {
      case 'dashboard':
        return loc.translate('dashboard');
      case 'timetable':
        return loc.translate('timetable');
      case 'appel':
        return loc.translate('appel');
      case 'students':
        return loc.translate('students');
      case 'teachers':
        return loc.translate(
          _isPrimarySchool() ? 'teacherListPrimary' : 'teacherList',
        );
      case 'myNotes':
        return loc.translate('notesAndAssessments');
      case 'myNotebook':
        return context.tr('lessonBook');
      case 'courseTracking':
        return loc.translate('courseTracking');
      case 'adminAnnouncements':
        return loc.translate('notificationsAndAnnouncements');
      case 'receptionNotes':
        return loc.translate('notesForChildren');
      case 'receptionNotebooks':
        return context.tr('lessonBook');
      case 'events':
        return loc.translate('events');
      case 'discipline':
        return loc.translate('disciplineAndSanctions');
      case 'absences':
        return loc.translate('schoolAbsences');
      case 'managementStaff':
        return loc.translate('schoolStaffManagement');
      case 'payments':
        return loc.translate('schoolPayments');
      case 'expenses':
        return loc.translate('expenses');
      case 'pensions':
        return loc.translate('tuitionTracking');
      case 'examClasses':
        return loc.translate('examClasses');
      case 'classes':
        return loc.translate('classManagement');
      case 'subjects':
        return loc.translate('subjectManagement');
      case 'bulletins':
        return loc.translate('bulletins');
      case 'recapYears':
        return loc.translate('recapYears');
      case 'settings':
        return loc.translate('settings');
      case 'profile':
        return loc.translate('myProfile');
      case 'programme':
        return loc.translate('programProgress');
      case 'teacherRoomChecks':
        return loc.translate('teacherRoomChecks');
      case 'staffAttendance':
        return loc.translate('staffQrAttendance');
      default:
        return loc.translate('dashboard');
    }
  }

  SidebarItem _navItem(AppLocalizations loc, IconData icon, String tabKey) {
    return SidebarItem(
      icon: icon,
      label: _tabLabel(loc, tabKey),
      active: selectedTab == tabKey,
      onTap: () => _handleNavigation(tabKey, context),
    );
  }

  List<SidebarSection> get _sidebarSections {
    final loc = AppLocalizations.of(context);
    final role = widget.currentUser.role;

    final bool isPrimary = _isPrimarySchool();
    final bool isFondateur =
        role == UserRole.fondateur ||
        widget.currentUser.displayRole.toLowerCase() == 'fondateur' ||
        widget.currentUser.displayRole.toLowerCase() == 'founder';
    final bool isProviseur = role == UserRole.proviseur;
    final bool isCenseur = !isPrimary && role == UserRole.censeur;
    final bool isSecretaire = role == UserRole.secretaire;
    final bool isSG =
        !isPrimary &&
        (role == UserRole.surveillantGeneral || role == UserRole.surveillant);
    final bool isComptable = role == UserRole.comptable;
    final bool isEnseignant = role == UserRole.enseignant;
    final bool isParent = role == UserRole.parent;
    final bool hasPrimaryCenseurFunctions =
        isPrimary && (isProviseur || isSecretaire);
    final bool hasPrimarySGFunctions =
        isPrimary && (isProviseur || isSecretaire);
    final bool canCenseurFunctions =
        isFondateur || isCenseur || hasPrimaryCenseurFunctions;
    final bool canSGFunctions = isFondateur || isSG || hasPrimarySGFunctions;

    final List<SidebarSection> sections = [];

    // 1. SECTION PRINCIPALE
    if (!isParent) {
      sections.add(
        SidebarSection(
          title: loc.translate('principal'),
          items: [
            _navItem(loc, Icons.dashboard, 'dashboard'),
            if (isFondateur ||
                canCenseurFunctions ||
                canSGFunctions ||
                isEnseignant)
              _navItem(loc, Icons.calendar_month, 'timetable'),
            if (isEnseignant) _navItem(loc, Icons.how_to_reg, 'appel'),
          ],
        ),
      );
    }

    // 2. VIE SCOLAIRE & PEDAGOGIE
    final List<SidebarItem> acadItems = [];
    if (isFondateur || isProviseur || isSecretaire) {
      acadItems.add(_navItem(loc, Icons.school, 'students'));
    }
    if (isFondateur || isProviseur) {
      acadItems.add(_navItem(loc, Icons.people, 'teachers'));
    }
    if (isFondateur || canCenseurFunctions || isEnseignant) {
      acadItems.add(_navItem(loc, Icons.edit_note, 'myNotes'));
    }
    if (isFondateur || isProviseur || canCenseurFunctions || isEnseignant) {
      acadItems.add(_navItem(loc, Icons.menu_book, 'courseTracking'));
    }
    if (isEnseignant) {
      acadItems.add(_navItem(loc, Icons.book, 'programme'));
    }
    if (isFondateur ||
        isProviseur ||
        canCenseurFunctions ||
        isSecretaire ||
        isComptable ||
        canSGFunctions) {
      acadItems.add(_navItem(loc, Icons.event, 'events'));
    }
    if (isFondateur || isProviseur || isSecretaire) {
      acadItems.add(_navItem(loc, Icons.edit_note, 'receptionNotes'));
    }
    if (isFondateur || canSGFunctions) {
      acadItems.add(_navItem(loc, Icons.event_busy, 'absences'));
    }
    if (isFondateur ||
        isProviseur ||
        canCenseurFunctions ||
        canSGFunctions ||
        isEnseignant) {
      acadItems.add(_navItem(loc, Icons.gavel, 'discipline'));
    }
    if (isFondateur || isProviseur || canCenseurFunctions || isSecretaire) {
      acadItems.add(_navItem(loc, Icons.assignment, 'bulletins'));
    }
    if (isParent) {
      acadItems.add(_navItem(loc, Icons.menu_book, 'programme'));
    }
    if (isFondateur ||
        isProviseur ||
        isSecretaire ||
        canSGFunctions ||
        isEnseignant) {
      acadItems.add(_navItem(loc, Icons.fact_check, 'teacherRoomChecks'));
    }
    if (isFondateur ||
        isProviseur ||
        isSecretaire ||
        canCenseurFunctions ||
        canSGFunctions ||
        isEnseignant) {
      acadItems.add(_navItem(loc, Icons.qr_code_2, 'staffAttendance'));
    }
    if (acadItems.isNotEmpty) {
      sections.add(
        SidebarSection(
          title: context.tr('auto_vie_scolaire'),
          items: acadItems,
        ),
      );
    }

    // 3. ADMINISTRATION & FINANCE
    final List<SidebarItem> adminItems = [];
    if (isFondateur || isProviseur || isSecretaire) {
      adminItems.add(_navItem(loc, Icons.history_edu, 'recapYears'));
    }
    if (isFondateur || isProviseur || isSecretaire) {
      adminItems.add(
        _navItem(loc, Icons.admin_panel_settings, 'managementStaff'),
      );
    }
    if (isFondateur ||
        isProviseur ||
        isComptable ||
        canCenseurFunctions ||
        isParent) {
      adminItems.add(_navItem(loc, Icons.payments, 'payments'));
    }
    if (isFondateur || isProviseur || isComptable) {
      adminItems.add(_navItem(loc, Icons.account_balance, 'expenses'));
    }
    if (isFondateur || isProviseur || canCenseurFunctions || isComptable) {
      adminItems.add(_navItem(loc, Icons.fact_check, 'pensions'));
    }
    if (isFondateur ||
        isProviseur ||
        canCenseurFunctions ||
        isSecretaire ||
        isComptable) {
      adminItems.add(_navItem(loc, Icons.assignment_turned_in, 'examClasses'));
    }
    if (isFondateur ||
        isProviseur ||
        canCenseurFunctions ||
        isEnseignant ||
        isSecretaire) {
      adminItems.add(_navItem(loc, Icons.meeting_room, 'classes'));
    }
    if (isFondateur || isProviseur || canCenseurFunctions) {
      adminItems.add(_navItem(loc, Icons.book_outlined, 'subjects'));
    }
    if (isFondateur) {
      adminItems.add(_navItem(loc, Icons.settings, 'settings'));
    }

    if (adminItems.isNotEmpty) {
      sections.add(
        SidebarSection(title: context.tr('administration'), items: adminItems),
      );
    }

    // 4. COMMUNICATION
    final List<SidebarItem> commItems = [];
    if (isFondateur ||
        isSecretaire ||
        canSGFunctions ||
        isComptable ||
        isParent) {
      commItems.add(
        _navItem(loc, Icons.notifications_active, 'adminAnnouncements'),
      );
    }
    if (isParent) {
      commItems.add(_navItem(loc, Icons.assessment, 'receptionNotes'));
      commItems.add(_navItem(loc, Icons.library_books, 'receptionNotebooks'));
    }
    if (commItems.isNotEmpty) {
      sections.add(
        SidebarSection(
          title: context.tr('auto_communication'),
          items: commItems,
        ),
      );
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: isMobile
          ? Drawer(
              child: MySidebar(
                sections: _sidebarSections,
                userName: widget.currentUser.name,
                userRole: _displayUserRole(),
                onLogout: _logout,
              ),
            )
          : null,
      body: isMobile
          ? _buildMainArea(isMobile: true)
          : Row(
              children: [
                MySidebar(
                  sections: _sidebarSections,
                  userName: widget.currentUser.name,
                  userRole: _displayUserRole(),
                  onLogout: _logout,
                ),
                Expanded(child: _buildMainArea(isMobile: false)),
              ],
            ),
    );
  }

  Widget _buildMainArea({required bool isMobile}) {
    final content = selectedTab == 'settings'
        ? _buildBodyContent()
        : selectedTab == 'staffAttendance'
        ? Column(
            children: [
              _buildSchoolStatusBanner(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: _buildBodyContent(),
                ),
              ),
            ],
          )
        : SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildSchoolStatusBanner(), _buildBodyContent()],
            ),
          );
    return Column(
      children: [
        _buildHeader(isMobile),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildSchoolStatusBanner() {
    return ValueListenableBuilder<SchoolInfo?>(
      valueListenable: currentSchoolNotifier,
      builder: (context, school, _) {
        if (school == null || !school.waitingForNewYear) {
          return SizedBox.shrink();
        }
        return Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final button = widget.currentUser.role == UserRole.fondateur
                  ? ElevatedButton(
                      onPressed: () => _handleNavigation('settings', context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        context.tr('settings'),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                  : null;
              final message = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.pause_circle_filled,
                    color: Colors.deepOrange,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('yearWaitingRenewal'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.deepOrange,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          context.tr('previousYearClosed'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              if (button == null || constraints.maxWidth >= 560) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: message),
                    if (button != null)
                      Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: button,
                      ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  message,
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: button,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    final loc = AppLocalizations.of(context);
    return Container(
      height: 80,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          Expanded(
            child: ValueListenableBuilder<SchoolInfo?>(
              valueListenable: currentSchoolNotifier,
              builder: (context, school, _) {
                final schoolText = school?.name.isNotEmpty == true
                    ? school!.name
                    : "EduGest";
                final yearText = school?.currentYearId.isNotEmpty == true
                    ? " • ${school!.currentYearId}"
                    : "";

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tabLabel(loc, selectedTab),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${widget.currentUser.name} • ${_displayUserRole()} • $schoolText$yearText",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.swap_horiz, color: AppColors.textMuted),
            tooltip: context.tr('changeSchool'),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SchoolSelectionPage(user: widget.currentUser),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_none, color: AppColors.textMuted),
            tooltip: context.tr('notifications'),
            onPressed: _showNotifications,
          ),
          if (widget.currentUser.role == UserRole.fondateur ||
              widget.currentUser.displayRole.toLowerCase() == 'fondateur' ||
              widget.currentUser.displayRole.toLowerCase() == 'founder')
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.textMuted),
              tooltip: context.tr('settings'),
              onPressed: () => _handleNavigation('settings', context),
            ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => selectedTab = "profile"),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryPale,
              child: Text(
                widget.currentUser.initials,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotifications() async {
    try {
      final notifications = await ApiService.getUnreadNotifications(
        userId: widget.currentUser.id,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.tr('notifications')),
          content: SizedBox(
            width: (MediaQuery.sizeOf(context).width - 80).clamp(280.0, 460.0),
            child: notifications.isEmpty
                ? Text(context.tr('noUnreadNotifications'))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => Divider(),
                    itemBuilder: (_, index) {
                      final notification = notifications[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          notification['title']?.toString() ?? 'EduGest',
                        ),
                        subtitle: Text(
                          notification['message']?.toString() ?? '',
                        ),
                        onTap: () async {
                          final id = notification['id']?.toString();
                          if (id != null) {
                            await ApiService.markNotificationRead(
                              id,
                              userId: widget.currentUser.id,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('close')),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.tr('loadNotificationsError')}: '
              '${ApiService.friendlyErrorMessage(error)}',
            ),
          ),
        );
      }
    }
  }

  Widget _buildBodyContent() {
    switch (selectedTab) {
      case 'appel':
        return AppelPage(currentUser: widget.currentUser);
      case 'students':
        return ListeEleves(currentUser: widget.currentUser);
      case 'teachers':
        return ListeEnseignant();
      case 'myNotes':
        return Notes(currentUser: widget.currentUser);
      case 'receptionNotes':
        return ReceptionNotes(currentUser: widget.currentUser);
      case 'events':
        return Evenement();
      case 'adminAnnouncements':
        return ReceptionEvenements();
      case 'timetable':
        return EmploiDuTemps(currentUser: widget.currentUser);
      case 'payments':
        return Paiements(currentUser: widget.currentUser);
      case 'pensions':
        return PensionsPage();
      case 'examClasses':
        return ExamClassesPage(currentUser: widget.currentUser);
      case 'discipline':
        return Discipline(currentUser: widget.currentUser);
      case 'absences':
        return Absences();
      case 'myNotebook':
        return CahierTexte(currentUser: widget.currentUser);
      case 'receptionNotebooks':
        return ReceptionCahierTexte();
      case 'expenses':
        return Depenses(currentUser: widget.currentUser);
      case 'classes':
        return GestionClasses(
          readOnly: widget.currentUser.role == UserRole.enseignant,
          currentUser: widget.currentUser,
        );
      case 'subjects':
        return GestionMatieres();
      case 'bulletins':
        return BulletinsPage(currentUser: widget.currentUser);
      case 'recapYears':
        return RecapAnnees(currentUser: widget.currentUser);
      case 'settings':
        return Parametres(
          currentUser: widget.currentUser,
          onBack: () => setState(() => selectedTab = 'dashboard'),
        );
      case 'programme':
        return ProgrammePage(currentUser: widget.currentUser);
      case 'courseTracking':
        return SuiviCoursPage(currentUser: widget.currentUser);
      case 'teacherRoomChecks':
        return TeacherRoomCheckPage(currentUser: widget.currentUser);
      case 'staffAttendance':
        return StaffAttendancePage(currentUser: widget.currentUser);
      case 'profile':
        return Profil(user: widget.currentUser);
      case 'managementStaff':
        return GestionStaff(currentUser: widget.currentUser);
      default:
        return _buildRoleBasedOverview();
    }
  }

  Widget _buildRoleBasedOverview() {
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final role = widget.currentUser.role;

    final elevesStr = _isStatsLoading ? "..." : "$_studentCount";
    final staffStr = _isStatsLoading ? "..." : "$_staffCount";
    final financeStr = _isStatsLoading ? "..." : "$_financeReceived FCFA";

    if (role == UserRole.fondateur) {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard(
            context.tr('globalRevenue'),
            financeStr,
            Icons.trending_up,
            Colors.green,
          ),
          _statCard(
            context.tr('totalStudents'),
            elevesStr,
            Icons.people,
            Colors.blue,
          ),
          _statCard(
            context.tr('staffMembers'),
            staffStr,
            Icons.badge,
            Colors.purple,
          ),
        ],
        title: context.tr('founderVision'),
        activities: [
          context.tr('financeConsolidation'),
          context.tr('annualSchoolReport'),
          context.tr('criticalRolesManagement'),
        ],
      );
    } else if (role == UserRole.proviseur) {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard(
            context.tr('enrolledStudents'),
            elevesStr,
            Icons.school,
            Colors.blue,
          ),
          _statCard(
            context.tr('financialSituation'),
            financeStr,
            Icons.payments,
            Colors.orange,
          ),
          _statCard(
            context.tr('staffMembers'),
            staffStr,
            Icons.admin_panel_settings,
            Colors.purple,
          ),
        ],
        title: context.tr('leadershipSupervision'),
        activities: [
          context.tr('reportCardsValidation'),
          context.tr('teacherStaffReview'),
          context.tr('disciplineControl'),
        ],
      );
    } else if (role == UserRole.censeur) {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard(
            context.tr('totalStudents'),
            elevesStr,
            Icons.school,
            Colors.blue,
          ),
          _statCard(
            context.tr('courseTracking'),
            context.tr('open'),
            Icons.menu_book,
            Colors.teal,
          ),
        ],
        title: context.tr('academicMonitoring'),
        activities: [
          context.tr('timetableVerification'),
          context.tr('gradeEntryClosure'),
          context.tr('lessonBookControl'),
        ],
      );
    } else if (role == UserRole.surveillantGeneral) {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard(
            context.tr('enrolledStudents'),
            elevesStr,
            Icons.school,
            Colors.blue,
          ),
        ],
        title: context.tr('schoolLifeDiscipline'),
        activities: [
          context.tr('morningAttendance'),
          context.tr('absenceSlipProcessing'),
          context.tr('dailyConductReport'),
        ],
      );
    } else if (role == UserRole.comptable) {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard(
            context.tr('revenue'),
            financeStr,
            Icons.account_balance_wallet,
            Colors.green,
          ),
          _statCard(
            context.tr('expenses'),
            context.tr('toReview'),
            Icons.shopping_cart,
            Colors.red,
          ),
        ],
        title: context.tr('financialManagement'),
        activities: [
          context.tr('paymentRecording'),
          context.tr('supplierPayments'),
          context.tr('cashReport'),
        ],
      );
    } else if (role == UserRole.enseignant) {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard(
            context.tr('lessonBook'),
            context.tr('open'),
            Icons.menu_book,
            Colors.blue,
          ),
          _statCard(
            context.tr('courseProgram'),
            context.tr('open'),
            Icons.book,
            Colors.orange,
          ),
        ],
        title: context.tr('teacherSpace'),
        activities: [
          context.tr('fillLessonBook'),
          context.tr('takeAttendance'),
          context.tr('enterQuizGrades'),
        ],
      );
    } else {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard(
            context.tr('myProfile'),
            widget.currentUser.name,
            Icons.person,
            Colors.blue,
          ),
          _statCard(
            context.tr('role'),
            _displayUserRole(),
            Icons.badge,
            Colors.green,
          ),
          _statCard(
            context.tr('schoolLabel'),
            context.tr('selected'),
            Icons.school,
            Colors.orange,
          ),
        ],
        title: "${context.tr('dashboard')} - ${_displayUserRole()}",
        activities: [
          context.tr('auto_consulter_vos_informations'),
          context.tr('contactSchool'),
        ],
      );
    }
  }

  Widget _buildDashboardTemplate(
    bool isMobile,
    bool isTablet, {
    required List<Widget> stats,
    required String title,
    required List<String> activities,
  }) {
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            double aspectRatio = constraints.maxWidth < 600 ? 3.0 : 1.4;
            return GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: aspectRatio,
              children: stats,
            );
          },
        ),
        SizedBox(height: 32),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(
                radius: 4,
                backgroundColor: AppColors.primary,
              ),
              title: Text(activities[index], style: TextStyle(fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
