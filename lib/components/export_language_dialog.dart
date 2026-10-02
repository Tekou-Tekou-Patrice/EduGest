import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class ExportLanguageDialog {
  static Future<String?> show(
    BuildContext context, {
    String? initialLanguageCode,
  }) {
    final supportedCodes = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();
    final requestedCode =
        initialLanguageCode ?? Localizations.localeOf(context).languageCode;
    var selectedCode = supportedCodes.contains(requestedCode)
        ? requestedCode
        : 'fr';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('chooseDocumentLanguage')),
          content: DropdownButtonFormField<String>(
            initialValue: selectedCode,
            decoration: InputDecoration(
              labelText: context.tr('documentLanguage'),
            ),
            items: [
              DropdownMenuItem(
                value: 'fr',
                child: Text(context.tr('languageFrench')),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(context.tr('languageEnglish')),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedCode = value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selectedCode),
              child: Text(context.tr('continueButton')),
            ),
          ],
        ),
      ),
    );
  }
}
