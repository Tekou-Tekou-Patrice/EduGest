import 'package:edugest/localization/app_localizations.dart';
import 'package:edugest/localization/locale_notifier.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every localization key exists in French and English', () {
    for (final key in AppLocalizations.translationKeys) {
      expect(AppLocalizations.hasTranslation('fr', key), isTrue, reason: key);
      expect(AppLocalizations.hasTranslation('en', key), isTrue, reason: key);
    }
  });

  test('primary teacher terminology is available in French and English', () {
    final french = AppLocalizations(Locale('fr'));
    final english = AppLocalizations(Locale('en'));
    expect(
      french.translateRole('enseignant', schoolLevel: 'PRIMARY'),
      'Maître / Maîtresse',
    );
    expect(
      english.translateRole('enseignant', schoolLevel: 'PRIMARY'),
      'Primary Teacher',
    );
    expect(
      french.translate('teacherListPrimary'),
      'Liste des maîtres et maîtresses',
    );
    expect(english.translate('teacherListPrimary'), 'Primary Teachers');
    expect(
      french.translateRole('enseignant', schoolLevel: 'COLLEGE'),
      'Enseignant',
    );
    expect(
      english.translateRole('enseignant', schoolLevel: 'LYCEE'),
      'Teacher',
    );
  });

  test('account without a language preference falls back to French', () async {
    SharedPreferences.setMockInitialValues({
      'edugest_language_first-user': 'en',
    });
    final locale = LocaleNotifier();

    await locale.loadForUser('first-user');
    expect(locale.value.languageCode, 'en');

    await locale.loadForUser('second-user');
    expect(locale.value.languageCode, 'fr');
  });
}
