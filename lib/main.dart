import 'package:edugest/localization/app_localizations.dart';
import 'package:edugest/localization/locale_notifier.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/pages/WelcomePage.dart';
import 'package:edugest/pages/home_router.dart';
import 'package:edugest/pages/login_page.dart';
import 'package:edugest/pages/school_selection_page.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/auth_session_service.dart';
import 'package:edugest/components/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await appLocale.loadSavedLocale();
  final session = await AuthSessionService.loadSession();
  final storedUser = session['user'] as AppUser?;
  final hasValidToken =
      storedUser?.token != null && storedUser!.token!.trim().isNotEmpty;
  final AppUser? user = hasValidToken ? storedUser : null;
  final String? schoolId = user == null ? null : session['schoolId'] as String?;
  final bool welcomeSeen = await AuthSessionService.hasSeenWelcome();

  if (storedUser != null && !hasValidToken) {
    await AuthSessionService.clearSession();
  }

  if (user != null) {
    ApiService.setActiveUser(user);
  }
  if (schoolId != null && schoolId.isNotEmpty) {
    ApiService.setActiveSchool(schoolId);
  }

  runApp(
    MyApp(
      initialUser: user,
      initialSchoolId: schoolId,
      showWelcome: !welcomeSeen,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppUser? initialUser;
  final String? initialSchoolId;
  final bool showWelcome;

  const MyApp({
    super.key,
    this.initialUser,
    this.initialSchoolId,
    required this.showWelcome,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EduGest',
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light,
          home: _AppSessionGate(
            initialUser: initialUser,
            initialSchoolId: initialSchoolId,
            showWelcome: showWelcome,
          ),
        );
      },
    );
  }
}

class _AppSessionGate extends StatefulWidget {
  final AppUser? initialUser;
  final String? initialSchoolId;
  final bool showWelcome;

  const _AppSessionGate({
    this.initialUser,
    this.initialSchoolId,
    required this.showWelcome,
  });

  @override
  State<_AppSessionGate> createState() => _AppSessionGateState();
}

class _AppSessionGateState extends State<_AppSessionGate> {
  bool _isLoading = true;
  AppUser? _user;
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    _schoolId = widget.initialSchoolId;
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user != null) {
      if (_schoolId != null && _schoolId!.trim().isNotEmpty) {
        return HomeRouter(userRole: _user!.displayRole, user: _user);
      }
      return SchoolSelectionPage(user: _user!);
    }

    return widget.showWelcome ? const Welcomepage() : const LoginPage();
  }
}
