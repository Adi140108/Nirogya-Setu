import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Card body that shows a short summary and opens to the full details on tap.
/// [builder] receives whether the card is open and returns the content to show.
class ExpandableDetails extends StatefulWidget {
  final Widget Function(BuildContext context, bool open) builder;
  final String showLabel;
  final String hideLabel;

  const ExpandableDetails({
    super.key,
    required this.builder,
    this.showLabel = 'Show details',
    this.hideLabel = 'Hide details',
  });

  @override
  State<ExpandableDetails> createState() => _ExpandableDetailsState();
}

class _ExpandableDetailsState extends State<ExpandableDetails> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _open = !_open),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.builder(context, _open),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  _open ? widget.hideLabel : widget.showLabel,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.neem),
                ),
                const SizedBox(width: 2),
                Icon(
                  _open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.neem,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
