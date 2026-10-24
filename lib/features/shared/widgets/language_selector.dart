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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: locale.code,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.language_rounded,
            size: 16,
            color: Color(0xFF0F172A),
          ),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
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
