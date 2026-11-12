import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialShapes, MaterialShapeBorder;

abstract final class Motion {
  static const duration = Duration(milliseconds: 520);
  static const pageDuration = Duration(milliseconds: 320);
  static const curve = Curves.easeInOutCubicEmphasized;
  static final Curve spring = _ExpressiveSpring();
  static Duration of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  static Duration pageOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : pageDuration;
}

class _ExpressiveSpring extends Curve {
  final _simulation = SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 420, damping: 32),
    0,
    1,
    0,
  );
  @override
  double transformInternal(double t) =>
      _simulation.x(t * .52) / _simulation.x(.52);
}

/// One clock for decorative motion. Paint listeners never rebuild the page.
class Aurora extends StatefulWidget {
  const Aurora({super.key, required this.paused, required this.builder});
  final bool paused;
  final Widget Function(BuildContext, Animation<double>) builder;
  @override
  State<Aurora> createState() => _AuroraState();
}

class _AuroraState extends State<Aurora>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  void _sync() {
    final run =
        _foreground &&
        !widget.paused &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (run && !_clock.isAnimating) _clock.repeat();
    if (!run && _clock.isAnimating) _clock.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Aurora oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _clock);
}

class AuroraArt extends CustomPainter {
  static final _shapes = [
    MaterialShapes.cookie9Sided,
    MaterialShapes.clover4Leaf,
    MaterialShapes.softBurst,
    MaterialShapes.flower,
    MaterialShapes.puffy,
    MaterialShapes.gem,
  ];
  static final _borders = _shapes
      .map((shape) => MaterialShapeBorder(shape: shape))
      .toList();

  AuroraArt(
    this.clock, {
    required this.dark,
    this.hero = false,
    this.seed = const Color(0xFF52734D),
    this.variant = 0,
  }) : super(repaint: clock);
  final Animation<double> clock;
  final bool dark, hero;
  final Color seed;
  final int variant;
  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value * math.pi * 2;
    if (!hero) {
      final center = Offset(
        size.width * (.8 + .08 * math.sin(t)),
        size.height * .24,
      );
      final radius = size.longestSide * .7;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [seed.withValues(alpha: .22), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      // Large, translucent silhouettes carry the same shape language behind
      // every route. No blur filters or offscreen saveLayer allocations.
      for (var i = 0; i < 4; i++) {
        final phase = t + i * math.pi / 2;
        final position = Offset(
          size.width * (.12 + i * .27) + 28 * math.sin(phase),
          size.height * (.22 + (i % 2) * .58) + 32 * math.cos(phase),
        );
        final extent = size.shortestSide * (.22 + i * .025);
        final border = ShapeBorder.lerp(
          _borders[i],
          _borders[(i + 2) % 6],
          (1 - math.cos(t + i)) / 2,
        )!;
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(phase * (i.isEven ? 1 : -1));
        final rect = Rect.fromCircle(center: Offset.zero, radius: extent);
        canvas.drawPath(
          border.getOuterPath(rect),
          Paint()..color = seed.withValues(alpha: dark ? .045 : .055),
        );
        canvas.drawPath(
          border.getOuterPath(rect.deflate(12)),
          Paint()
            ..color = seed.withValues(alpha: .09)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        canvas.restore();
      }
      return;
    }
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .32;
    // All satellites share the same clock and repaint boundary as the bloom.
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + t;
      final orbit = size.shortestSide * .44;
      final position =
          center + Offset(math.cos(angle) * orbit, math.sin(angle) * orbit);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + .3 * math.sin(t + i));
      final little = size.shortestSide * (.046 + .009 * math.sin(t * 2 + i));
      final paint = Paint()
        ..color = Color.lerp(
          seed,
          dark ? Colors.white : Colors.black,
          .15,
        )!.withValues(alpha: .7);
      canvas.scale(little * 2);
      canvas.translate(-.5, -.5);
      canvas.drawPath(
        ShapeBorder.lerp(
          _borders[i],
          _borders[(i + 2) % 6],
          (1 - math.cos(t * 3 + i)) / 2,
        )!.getOuterPath(const Rect.fromLTWH(0, 0, 1, 1)),
        paint,
      );
      canvas.restore();
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Periodic rotation keeps the last frame continuous with the next cycle.
    canvas.rotate(t);
    final index = variant % _borders.length;
    final border = ShapeBorder.lerp(
      _borders[index],
      _borders[(index + 1) % _borders.length],
      (1 - math.cos(t * 2)) / 2,
    )!;
    final path = border.getOuterPath(
      Rect.fromCircle(center: Offset.zero, radius: radius),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(seed, Colors.white, .8)!,
            Color.lerp(seed, Colors.white, .4)!,
            seed,
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2 + .3 * math.sin(t));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 1.5,
          height: radius * .59,
        ),
        Paint()
          ..color = const Color(0xFF24493B).withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      Offset.zero,
      radius * .1,
      Paint()..color = const Color(0xFF24493B),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(AuroraArt oldDelegate) =>
      oldDelegate.dark != dark ||
      oldDelegate.hero != hero ||
      oldDelegate.seed != seed ||
      oldDelegate.variant != variant ||
      oldDelegate.clock != clock;
}
