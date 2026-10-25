import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/sync_status.dart';

/// Visual tokens for the Admin Portal. They reuse the slate/white surfaces and
/// role accent colours already used on the role-selection and citizen screens.
class AdminColors {
  static const Color background = Color(0xFFF3E8D5);
  static const Color ink = Color(0xFF33200F);
  static const Color muted = Color(0xFF6B5443);
  static const Color border = Color(0xFFE2D2B6);
  static const Color accent = Color(0xFF3B6634);
  static const Color accentSurface = Color(0xFFE4E6CC);

  static const Color asha = Color(0xFF3B6634);
  static const Color ashaSurface = Color(0xFFE4E6CC);
  static const Color doctor = Color(0xFF2C4D27);
  static const Color doctorSurface = Color(0xFFDCE3C8);
  static const Color hospital = Color(0xFFA8452A);
  static const Color hospitalSurface = Color(0xFFF3DCC4);
  static const Color video = Color(0xFFB23A22);
  static const Color videoSurface = Color(0xFFF4D6C8);
  static const Color citizen = Color(0xFF3B6634);
  static const Color citizenSurface = Color(0xFFE4E6CC);
}

class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AdminCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(0xFFFBF4E8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AdminIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color surface;
  final double size;

  const AdminIconBadge({super.key, required this.icon, required this.color, required this.surface, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class AdminStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color surface;
  final String? caption;

  const AdminStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.surface,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminIconBadge(icon: icon, color: color, surface: surface, size: 34),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminColors.ink)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.ink)),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AdminColors.muted)),
          ],
        ],
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const AdminSectionTitle({super.key, required this.title, this.trailing, this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AdminColors.ink)),
          ),
          if (trailing != null)
            TextButton(
              onPressed: onTrailingTap,
              style: TextButton.styleFrom(
                foregroundColor: AdminColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(trailing!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminIconBadge(icon: icon, color: AdminColors.muted, surface: Colors.white, size: 64),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AdminColors.ink)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AdminColors.muted, height: 1.35)),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const AdminSearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AdminColors.muted),
        prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.muted),
        isDense: true,
      ),
    );
  }
}

class AdminChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color surface;
  final IconData? icon;

  const AdminChip({super.key, required this.label, required this.color, required this.surface, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class AdminSyncChip extends StatelessWidget {
  final SyncStatus status;

  const AdminSyncChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return AdminChip(
      label: status == SyncStatus.synced ? 'Synced' : 'Pending sync',
      icon: status.icon,
      color: status.color,
      surface: status.color.withOpacity(0.1),
    );
  }
}

class AdminActiveChip extends StatelessWidget {
  final bool isActive;

  const AdminActiveChip({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AdminChip(
      label: isActive ? 'Active' : 'Inactive',
      color: isActive ? AppColors.riskGreen : AppColors.riskRed,
      surface: isActive ? AppColors.riskGreenSurface : AppColors.riskRedSurface,
    );
  }
}

class AdminInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const AdminInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AdminColors.muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AdminColors.muted)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminColors.ink)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// White card grouping related form fields under a heading.
class AdminFormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const AdminFormSection({super.key, required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AdminCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AdminColors.ink)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Field spacing helper used inside [AdminFormSection].
class AdminField extends StatelessWidget {
  final Widget child;

  const AdminField({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
}

InputDecoration adminInput(String label, {String? hint, IconData? icon, String? prefixText}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    prefixIcon: icon != null ? Icon(icon, size: 20) : null,
  );
}

/// Primary full-width save button used at the bottom of admin forms.
class AdminPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isBusy;

  const AdminPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isBusy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
        ),
        icon: isBusy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }
}

void showAdminSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: isError ? const Color(0xFFB23A22) : AppColors.primaryDark,
      behavior: SnackBarBehavior.floating,
      content: Text(message),
    ));
}

Future<bool> showAdminConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Color(0xFFFBF4E8),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AdminColors.ink)),
      content: Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF4A3626), height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: AdminColors.muted, fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? const Color(0xFFB23A22) : AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return result == true;
}

/// Shows the login credentials of a newly created (or reset) ASHA worker / doctor.
Future<void> showCredentialsDialog(
  BuildContext context, {
  required String title,
  required String name,
  required String mobile,
  required String password,
  required Color color,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Color(0xFFFBF4E8),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
      title: Row(
        children: [
          AdminIconBadge(icon: Icons.verified_user_rounded, color: color, surface: color.withOpacity(0.12)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AdminColors.ink)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Share these login details with $name. They sign in with the mobile number and this password.',
              style: const TextStyle(fontSize: 13, color: AdminColors.muted, height: 1.35)),
          const SizedBox(height: 14),
          _CredentialLine(label: 'Mobile number', value: mobile),
          const SizedBox(height: 8),
          _CredentialLine(label: 'Password', value: password, highlight: true),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: 'Nirogya Setu login\nMobile: $mobile\nPassword: $password'));
            showAdminSnack(ctx, 'Login details copied');
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

class _CredentialLine extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _CredentialLine({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primarySurface : AdminColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AdminColors.muted))),
          SelectableText(value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: highlight ? AppColors.primaryDark : AdminColors.ink,
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }
}

/// Password row with show/hide and copy, used on staff detail screens.
class AdminPasswordRow extends StatefulWidget {
  final String password;

  const AdminPasswordRow({super.key, required this.password});

  @override
  State<AdminPasswordRow> createState() => _AdminPasswordRowState();
}

class _AdminPasswordRowState extends State<AdminPasswordRow> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.key_rounded, size: 18, color: AdminColors.muted),
        const SizedBox(width: 10),
        const SizedBox(width: 110, child: Text('Password', style: TextStyle(fontSize: 12.5, color: AdminColors.muted))),
        Expanded(
          child: Text(
            _visible ? widget.password : '•' * widget.password.length.clamp(6, 10),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.ink, letterSpacing: 0.5),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: _visible ? 'Hide password' : 'Show password',
          icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
          onPressed: () => setState(() => _visible = !_visible),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Copy password',
          icon: const Icon(Icons.copy_rounded, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.password));
            showAdminSnack(context, 'Password copied');
          },
        ),
      ],
    );
  }
}

/// Form field that opens a searchable list in a bottom sheet (used for long
/// lists such as Indian states and districts). With [allowCustom], a value
/// that is not in the list can be typed and used as-is.
class AdminSearchSelectField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? disabledHint;
  final bool allowCustom;

  const AdminSearchSelectField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.disabledHint,
    this.allowCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey('$label|$value|$enabled'),
      initialValue: value,
      validator: validator,
      builder: (field) {
        final hasValue = (value ?? '').isNotEmpty;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: !enabled
              ? null
              : () async {
                  final picked = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Color(0xFFFBF4E8),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (_) => _SearchPickerSheet(title: label, options: options, allowCustom: allowCustom),
                  );
                  if (picked != null && picked.trim().isNotEmpty) {
                    field.didChange(picked);
                    onChanged(picked.trim());
                  }
                },
          child: InputDecorator(
            isEmpty: !hasValue,
            decoration: adminInput(label, icon: icon).copyWith(
              enabled: enabled,
              errorText: field.errorText,
              hintText: enabled ? null : disabledHint,
              suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
            ),
            child: Text(
              hasValue ? value! : '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        );
      },
    );
  }
}

class _SearchPickerSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final bool allowCustom;

  const _SearchPickerSheet({required this.title, required this.options, required this.allowCustom});

  @override
  State<_SearchPickerSheet> createState() => _SearchPickerSheetState();
}

class _SearchPickerSheetState extends State<_SearchPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final results = widget.options.where((o) => q.isEmpty || o.toLowerCase().contains(q)).toList();
    final exactMatch = widget.options.any((o) => o.toLowerCase() == q);
    final showCustom = widget.allowCustom && q.length >= 2 && !exactMatch;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AdminColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title.replaceAll(' *', ''),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AdminColors.ink)),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AdminSearchField(hint: 'Search', onChanged: (v) => setState(() => _query = v)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  if (showCustom)
                    ListTile(
                      leading: const Icon(Icons.edit_location_alt_outlined, color: AppColors.primary),
                      title: Text('Use "${_query.trim()}"',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                      subtitle: const Text('Not in the list? Use what you typed'),
                      onTap: () => Navigator.pop(context, _query.trim()),
                    ),
                  for (final o in results)
                    ListTile(
                      title: Text(o, style: const TextStyle(fontSize: 14.5)),
                      onTap: () => Navigator.pop(context, o),
                    ),
                  if (results.isEmpty && !showCustom)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No matches', textAlign: TextAlign.center, style: TextStyle(color: AdminColors.muted)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
