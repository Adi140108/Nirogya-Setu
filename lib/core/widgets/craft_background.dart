import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Hand-stitched craft motifs (rendered in nirogya-setu-logo/art/motifs.html).
enum CraftMotif { paisley, neem, kolam, phulkari, sun, sprig }

/// One motif cropped off a screen edge, like the cut-outs on a printed handbook cover.
/// [left]/[top]/[right]/[bottom] are fractions of the motif's size, so negative values
/// push it off-screen and the crop stays the same on every phone.
class CraftPiece {
  final CraftMotif motif;
  final double size; // fraction of the shorter screen side
  final double? left, top, right, bottom;
  final double turns;
  final double opacity;

  const CraftPiece(this.motif, this.size,
      {this.left, this.top, this.right, this.bottom, this.turns = 0, this.opacity = 1});
}

/// Mud-paper page: a faint stitched grid, paper grain, and craft motifs bleeding off the edges.
class CraftBackground extends StatelessWidget {
  final Widget child;
  final List<CraftPiece> pieces;
  final Color color;
  final bool grid;

  const CraftBackground({
    super.key,
    required this.child,
    this.pieces = const [],
    this.color = AppColors.mud,
    this.grid = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final side = c.biggest.shortestSide.clamp(320.0, 720.0);
      return Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: color),
          if (grid) CustomPaint(painter: _GridPainter()),
          Opacity(
            opacity: 0.35,
            child: Image.asset('assets/images/texture_grain.png', repeat: ImageRepeat.repeat, fit: BoxFit.none),
          ),
          for (final p in pieces) _place(p, side),
          child,
        ],
      );
    });
  }

  Widget _place(CraftPiece p, double side) {
    final s = p.size * side;
    return Positioned(
      left: p.left == null ? null : p.left! * s,
      top: p.top == null ? null : p.top! * s,
      right: p.right == null ? null : p.right! * s,
      bottom: p.bottom == null ? null : p.bottom! * s,
      width: s,
      height: s,
      child: IgnorePointer(
        child: Opacity(
          opacity: p.opacity,
          child: Transform.rotate(
            angle: p.turns * 6.283185,
            child: Image.asset('assets/images/motif_${p.motif.name}.png',
                fit: BoxFit.contain, filterQuality: FilterQuality.medium),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink.withOpacity(0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stitched kolam peeking into a green app bar (use as AppBar.flexibleSpace).
class CraftHeaderStitch extends StatelessWidget {
  final CraftMotif motif;

  const CraftHeaderStitch({super.key, this.motif = CraftMotif.kolam});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          Positioned(
            right: -46,
            top: -38,
            width: 150,
            height: 150,
            child: Opacity(
              opacity: 0.22,
              child: Image.asset('assets/images/motif_${motif.name}.png', fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark-neem bottom bar shared by the role dashboards.
class CraftNavTheme {
  static const Color background = AppColors.neemDark;
  static const Color selected = AppColors.haldi;
  static const Color unselected = Color(0xCCFBF4E8);
}

/// "Nirogya Setu" set in the brand serif: terracotta, then neem italic.
class NirogyaWordmark extends StatelessWidget {
  final double size;
  final TextAlign align;

  const NirogyaWordmark({super.key, this.size = 34, this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(fontFamily: 'Fraunces', fontSize: size, height: 1.0, letterSpacing: -0.02 * size),
        children: const [
          TextSpan(text: 'Nirogya ', style: TextStyle(color: AppColors.terraDark, fontWeight: FontWeight.w700)),
          TextSpan(
              text: 'Setu',
              style: TextStyle(color: AppColors.neem, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
        ],
      ),
      textAlign: align,
    );
  }
}

/// Ink pill with a terracotta arrow disc: the one primary action on a screen.
class CraftPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData icon;
  final Color color;

  const CraftPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon = Icons.arrow_forward_rounded,
    this.color = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null ? color.withOpacity(0.6) : color,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: busy ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: busy
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                            width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.paint, strokeWidth: 2.4)),
                      )
                    : Text(label,
                        style: const TextStyle(
                            color: AppColors.paint, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: AppColors.terra, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.paint, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
