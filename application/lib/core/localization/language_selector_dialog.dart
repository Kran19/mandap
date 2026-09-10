import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'locale_notifier.dart';

/// Global Language Selector Dialog allowing immediate language switching.
class LanguageSelectorDialog extends StatelessWidget {
  const LanguageSelectorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const LanguageSelectorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<LocaleNotifier>();
    final currentCode = notifier.locale.languageCode;

    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.headerBorder),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.trussLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.language_rounded, color: AppColors.trussPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Language / भाषा',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                'Select Application Language',
                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
            ],
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: kApprovedLanguages.map((lang) {
              final isSelected = lang.code == currentCode;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: InkWell(
                  onTap: () {
                    notifier.setLanguageByCode(lang.code);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.trussLight : AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.trussPrimary : AppColors.inputBorder,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.nativeName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.trussPrimary : AppColors.primaryText,
                                ),
                              ),
                              if (lang.nativeName != lang.englishName)
                                Text(
                                  lang.englishName,
                                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.trussPrimary, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: AppColors.secondaryText)),
        ),
      ],
    );
  }
}
