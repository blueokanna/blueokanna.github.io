import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialShapes, MaterialShapeBorder;

import '../motion.dart';
import 'clock_scope.dart';

abstract final class LayoutSpace {
  static const section = 80.0;
  static double gutter(double width) => width < 600
      ? 20
      : width < 1000
      ? 32
      : 48;
}

/// Material state layers and elevation provide feedback on both pointer and
/// keyboard navigation. The shape never clips the card's reading area.
class ExpressiveCard extends StatefulWidget {
  const ExpressiveCard({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.variant = 0,
  });
  final Widget child;
  final VoidCallback onTap;
  final Color? color;
  final int variant;
  @override
  State<ExpressiveCard> createState() => _ExpressiveCardState();
}

class _ExpressiveCardState extends State<ExpressiveCard> {
  bool _hover = false, _focus = false, _pressed = false;
  @override
  Widget build(BuildContext context) {
    final active = _hover || _focus;
    final colors = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: _pressed ? .985 : 1,
      duration: Motion.of(context),
      curve: Motion.spring,
      child: Material(
        color: widget.color ?? colors.surfaceContainerLow,
        elevation: active ? 3 : 0,
        shadowColor: colors.shadow.withValues(alpha: .2),
        animationDuration: Motion.pageOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(active ? 48 : 28),
            topRight: Radius.circular(
              active ? 28 : (widget.variant.isEven ? 76 : 28),
            ),
            bottomLeft: Radius.circular(
              active ? 28 : (widget.variant.isEven ? 28 : 64),
            ),
            bottomRight: Radius.circular(active ? 48 : 28),
          ),
          side: BorderSide(
            color: active
                ? colors.primary
                : colors.outlineVariant.withValues(alpha: .35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onHover: (value) => setState(() => _hover = value),
          onFocusChange: (value) => setState(() => _focus = value),
          child: widget.child,
        ),
      ),
    );
  }
}

/// The illustration is painted separately from card text. The shared clock
/// drives all six compositions; no per-card ticker or widget rebuild is needed.
class ProjectArtwork extends StatelessWidget {
  const ProjectArtwork({super.key, required this.variant, required this.icon});
  final int variant;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final tones = [
      c.primaryContainer,
      c.secondaryContainer,
      c.tertiaryContainer,
    ];
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: 164,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ColoredBox(
              color: tones[variant % 3].withValues(alpha: .55),
              child: CustomPaint(
                painter: _ProjectPainter(MotionClock.of(context), variant, c),
                child: Center(
                  child: ShapeEmblem(variant: variant, icon: icon, size: 112),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectPainter extends CustomPainter {
  _ProjectPainter(this.clock, this.variant, this.colors)
    : super(repaint: clock);
  final Animation<double> clock;
  final int variant;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value * math.pi * 2;
    final paint = Paint()
      ..color = colors.primary.withValues(alpha: .24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final center = size.center(Offset.zero);
    if (variant == 1 || variant == 5) {
      // Nested orbital ribbons for the network client and the blog itself.
      canvas.save();
      canvas.translate(center.dx, center.dy);
      for (var i = 0; i < 6; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 6 + t);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: size.width * .8,
            height: 44 + i * 8,
          ),
          paint,
        );
        canvas.restore();
      }
      canvas.restore();
    } else if (variant == 2 || variant == 3) {
      // Routed paths: traveling dots follow the same curves they decorate.
      for (var i = 0; i < 6; i++) {
        final y = 16.0 + i * 26;
        final path = Path()
          ..moveTo(0, y)
          ..cubicTo(
            size.width * .24,
            y,
            size.width * .26,
            center.dy,
            center.dx,
            center.dy,
          )
          ..cubicTo(
            size.width * .74,
            center.dy,
            size.width * .76,
            size.height - y,
            size.width,
            size.height - y,
          );
        canvas.drawPath(path, paint);
        // Analytic cubic sampling avoids per-frame path metric allocation.
        final u = (clock.value * 2 + i / 6) % 1;
        final v = u < .5 ? u * 2 : (u - .5) * 2;
        final a = 1 - v;
        final points = u < .5
            ? [
                Offset(0, y),
                Offset(size.width * .24, y),
                Offset(size.width * .26, center.dy),
                center,
              ]
            : [
                center,
                Offset(size.width * .74, center.dy),
                Offset(size.width * .76, size.height - y),
                Offset(size.width, size.height - y),
              ];
        final point =
            points[0] * (a * a * a) +
            points[1] * (3 * a * a * v) +
            points[2] * (3 * a * v * v) +
            points[3] * (v * v * v);
        canvas.drawCircle(
          point,
          3,
          Paint()..color = colors.primary.withValues(alpha: .55),
        );
      }
    } else {
      for (var i = 0; i < 5; i++) {
        final path = Path();
        for (var x = 0.0; x <= size.width; x += 4) {
          final wave = math.sin(
            x / size.width * math.pi * (2 + variant % 3) + t + i * .4,
          );
          final y = size.height / 2 + wave * (22 + i * 9);
          if (x == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path, paint);
      }
    }
    for (var i = 0; i < 4; i++) {
      final angle = t * (i.isEven ? 1 : -1) + i * math.pi / 2;
      final p =
          center +
          Offset(
            math.cos(angle) * size.width * .35,
            math.sin(angle) * size.height * .34,
          );
      canvas.drawCircle(
        p,
        4 + i.toDouble(),
        Paint()..color = colors.primary.withValues(alpha: .5),
      );
    }
  }

  @override
  bool shouldRepaint(_ProjectPainter old) =>
      old.colors != colors || old.variant != variant || old.clock != clock;
}

class ShapeEmblem extends StatelessWidget {
  const ShapeEmblem({
    super.key,
    required this.variant,
    required this.icon,
    this.size = 96,
  });
  final int variant;
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pairs = [
      (colors.primaryContainer, colors.onPrimaryContainer),
      (colors.secondaryContainer, colors.onSecondaryContainer),
      (colors.tertiaryContainer, colors.onTertiaryContainer),
    ];
    final pair = pairs[variant % pairs.length];
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _EmblemPainter(MotionClock.of(context), variant, pair.$1),
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, color: pair.$2, size: size * .32),
          ),
        ),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  _EmblemPainter(this.clock, this.variant, this.color) : super(repaint: clock);
  final Animation<double> clock;
  final int variant;
  final Color color;
  static final _shapes = [
    MaterialShapes.cookie9Sided,
    MaterialShapes.gem,
    MaterialShapes.clover4Leaf,
    MaterialShapes.puffyDiamond,
    MaterialShapes.sunny,
    MaterialShapes.pentagon,
  ].map((shape) => MaterialShapeBorder(shape: shape)).toList();
  @override
  void paint(Canvas canvas, Size size) {
    final phase = clock.value * 2 * math.pi;
    final index = variant % _shapes.length;
    final shape = ShapeBorder.lerp(
      _shapes[index],
      _shapes[(index + 1) % _shapes.length],
      .5 + .5 * math.sin(phase),
    )!;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(.16 * math.sin(phase + variant));
    canvas.drawPath(
      shape.getOuterPath(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * .94,
          height: size.height * .94,
        ),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_EmblemPainter old) =>
      old.clock != clock || old.color != color || old.variant != variant;
}
