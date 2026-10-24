import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Shared building blocks so every screen looks and behaves the same.

/// Full-width primary action. Use one per screen.
class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool destructive;
  final bool loading;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.secondary = false,
    this.destructive = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 22), const SizedBox(width: AppSpacing.sm)],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    final size = const Size.fromHeight(AppSizes.primaryButton);
    if (secondary) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: size),
        onPressed: loading ? null : onPressed,
        child: child,
      );
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: size,
        backgroundColor: destructive ? AppColors.riskRed : AppColors.primary,
      ),
      onPressed: loading ? null : onPressed,
      child: child,
    );
  }
}

/// Flat bordered card. Optional tap and accent stripe (e.g. triage colour).
class InfoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final Color? color;

  const InfoCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.accent,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);
    if (accent != null) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Expanded(child: content),
          ],
        ),
      );
    }
    return Material(
      color: color ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Section title with optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Single number with a label. Tappable when [onTap] is set.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Large tappable action with icon + label, for home-screen task lists.
class ActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// Shown when a list has nothing in it.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(message!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
        ],
      ),
    );
  }
}

/// Label/value row for detail screens (vitals, profile fields).
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow(this.label, this.value, {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
