import 'package:edugest/localization/app_localizations.dart';
import 'package:edugest/localization/locale_notifier.dart';
import 'package:edugest/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('language can be chosen on sign-in and registration screen', (
    tester,
  ) async {
    await appLocale.setLocale(const Locale('fr'));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: appLocale,
        builder: (context, locale, _) => MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('auth-language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anglais').last);
    await tester.pumpAndSettle();

    expect(appLocale.value.languageCode, 'en');
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Email or phone number'), findsOneWidget);

    await tester.tap(find.text('Create an account').last);
    await tester.pumpAndSettle();

    expect(find.text('Create an account'), findsWidgets);
    expect(
      find.text('Create your account. You can join a school using its code.'),
      findsOneWidget,
    );
    expect(
      (await SharedPreferences.getInstance()).getString('edugest_language'),
      'en',
    );
  });
}
