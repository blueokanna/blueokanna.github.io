import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class Motion {
  static const duration = Duration(milliseconds: 520);
  static const curve = Curves.easeInOutCubicEmphasized;
  static Duration of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
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
    duration: const Duration(seconds: 24),
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
  AuroraArt(this.clock, {required this.dark, this.hero = false})
    : super(repaint: clock);
  final Animation<double> clock;
  final bool dark, hero;
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
            colors: [
              (dark ? const Color(0xFF65843A) : const Color(0xFFDBE9B6))
                  .withValues(alpha: .22),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      return;
    }
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .40;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Periodic rotation keeps the last frame continuous with the next cycle.
    canvas.rotate(math.sin(t) * .15);
    final path = Path();
    for (var i = 0; i <= 240; i++) {
      final a = i / 240 * math.pi * 2;
      final r = radius * (1 + .085 * math.cos(8 * a + math.sin(t)));
      final x = r * math.cos(a), y = r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3F9AA), Color(0xFFB9DF72), Color(0xFF709D64)],
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
      oldDelegate.clock != clock;
}
