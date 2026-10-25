import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_locale.dart';

/// App-wide language dropdown. Place in an AppBar's actions or anywhere in
/// a Column; changing it re-renders the whole app in the chosen language.
class LanguageSelector extends StatelessWidget {
  final bool dark; // style for light backgrounds (welcome screen)

  const LanguageSelector({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppLocale>();
    final fg = dark ? AppColors.ink : AppColors.paint;
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 8),
      decoration: BoxDecoration(
        color: dark ? AppColors.paint : AppColors.paint.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? AppColors.border : AppColors.paint.withOpacity(0.45)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: locale.code,
          dropdownColor: AppColors.paint,
          borderRadius: BorderRadius.circular(14),
          icon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(Icons.language_rounded, size: 16, color: fg),
          ),
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg),
          selectedItemBuilder: (_) => AppLocale.codes
              .map((c) => Center(
                    child: Text(AppLocale.names[c] ?? c,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg)),
                  ))
              .toList(),
          items: AppLocale.codes
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      AppLocale.names[c] ?? c,
                      style: const TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) locale.setLanguage(v);
          },
        ),
      ),
    );
  }
}
