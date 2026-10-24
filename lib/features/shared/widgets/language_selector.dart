import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_locale.dart';

/// App-wide language dropdown. Place in an AppBar's actions or anywhere in
/// a Column; changing it re-renders the whole app in the chosen language.
class LanguageSelector extends StatelessWidget {
  final bool dark; // style for light backgrounds (welcome screen)

  const LanguageSelector({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppLocale>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.8) : const Color(0xFF065F46),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: locale.code,
          dropdownColor: Colors.white,
          icon: Icon(Icons.language_rounded,
              size: 16, color: dark ? const Color(0xFF0F172A) : Colors.white),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: dark ? const Color(0xFF0F172A) : Colors.white,
          ),
          items: AppLocale.codes
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      AppLocale.names[c] ?? c,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
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
