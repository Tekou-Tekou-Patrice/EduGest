import 'package:edugest/localization/app_localizations.dart';
import 'package:edugest/localization/locale_notifier.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/pages/WelcomePage.dart';
import 'package:edugest/pages/home_router.dart';
import 'package:edugest/pages/school_selection_page.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/auth_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = await AuthSessionService.loadSession();
  final AppUser? user = session['user'] as AppUser?;
  final String? schoolId = session['schoolId'] as String?;

  if (schoolId != null && schoolId.isNotEmpty) {
    ApiService.setActiveSchool(schoolId);
  }

  runApp(MyApp(initialUser: user, initialSchoolId: schoolId));
}

class MyApp extends StatelessWidget {
  final AppUser? initialUser;
  final String? initialSchoolId;

  const MyApp({super.key, this.initialUser, this.initialSchoolId});

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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
          ),
          home: _AppSessionGate(
            initialUser: initialUser,
            initialSchoolId: initialSchoolId,
          ),
        );
      },
    );
  }
}

class _AppSessionGate extends StatefulWidget {
  final AppUser? initialUser;
  final String? initialSchoolId;

  const _AppSessionGate({this.initialUser, this.initialSchoolId});

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

    return const Welcomepage();
  }
}
