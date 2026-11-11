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
  bool _hover = false, _focus = false;
  @override
  Widget build(BuildContext context) {
    final active = _hover || _focus;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: widget.color ?? colors.surfaceContainerLow,
      elevation: active ? 3 : 0,
      shadowColor: colors.shadow.withValues(alpha: .2),
      animationDuration: Motion.pageOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(active ? 32 : 24),
          topRight: Radius.circular(widget.variant.isEven ? 48 : 24),
          bottomLeft: Radius.circular(widget.variant.isEven ? 24 : 48),
          bottomRight: Radius.circular(active ? 32 : 24),
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
        onHover: (value) => setState(() => _hover = value),
        onFocusChange: (value) => setState(() => _focus = value),
        child: widget.child,
      ),
    );
  }
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
