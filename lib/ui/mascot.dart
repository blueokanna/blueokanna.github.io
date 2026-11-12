import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../motion.dart';
import 'clock_scope.dart';

enum CompanionMood { idle, wave, dance, read }

/// The approved character artwork is kept intact. Aurora only animates its
/// presentation; the face, costume, hair and whale details are never redrawn.
class CompanionStage extends StatefulWidget {
  const CompanionStage({
    super.key,
    required this.language,
    this.compact = false,
  });
  final String language;
  final bool compact;
  @override
  State<CompanionStage> createState() => _CompanionStageState();
}

class _CompanionStageState extends State<CompanionStage>
    with SingleTickerProviderStateMixin {
  final _gaze = ValueNotifier<Offset>(Offset.zero);
  late final _pose = AnimationController(
    vsync: this,
    duration: Motion.duration,
    value: 1,
  );
  List<double> _from = [1, 0, 0, 0], _to = [1, 0, 0, 0];
  CompanionMood _mood = CompanionMood.idle;
  Timer? _reset;
  bool get _zh => widget.language.startsWith('zh');
  String _label(String zh, String en) => _zh ? zh : en;
  void _changePose(CompanionMood mood) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final progress = reduced
        ? 1.0
        : Motion.spring.transform(_pose.value).clamp(0.0, 1.0);
    setState(() {
      _from = List.generate(
        4,
        (i) => _from[i] * (1 - progress) + _to[i] * progress,
      );
      _to = List.generate(4, (i) => i == mood.index ? 1.0 : 0.0);
      _mood = mood;
    });
    if (reduced) {
      _pose.value = 1;
    } else {
      _pose.forward(from: 0);
    }
  }

  void _act(CompanionMood mood) {
    _reset?.cancel();
    _changePose(mood);
    if (mood == CompanionMood.read) return;
    _reset = Timer(const Duration(seconds: 5), () {
      if (mounted) _changePose(CompanionMood.idle);
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    _gaze.dispose();
    _pose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final message = switch (_mood) {
      CompanionMood.idle => _label('我是蓝色大肥鱼。戳戳我？', 'I’m 蓝色大肥鱼. Say hello?'),
      CompanionMood.wave => _label(
        '收到！今天也一起探索吧。',
        'Hello! Let’s explore together.',
      ),
      CompanionMood.dance => _label(
        '代码要严谨，快乐不用。',
        'A little rhythm between builds.',
      ),
      CompanionMood.read => _label(
        '安静模式。陪你读完这一篇。',
        'Quiet mode. One good read at a time.',
      ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          child: AnimatedContainer(
            duration: Motion.of(context),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: c.secondaryContainer,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(24),
                topRight: const Radius.circular(24),
                bottomRight: const Radius.circular(24),
                bottomLeft: Radius.circular(
                  _mood == CompanionMood.idle ? 6 : 24,
                ),
              ),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, box) => MouseRegion(
            onHover: (event) {
              if (!reduced) {
                _gaze.value = Offset(
                  (event.localPosition.dx / box.maxWidth * 2 - 1).clamp(-1, 1),
                  (event.localPosition.dy / 320 * 2 - 1).clamp(-1, 1),
                );
              }
            },
            onExit: (_) => _gaze.value = Offset.zero,
            child: Semantics(
              button: true,
              label: _label(
                '蓝色大肥鱼，DeepSeek Q版吉祥物。点击打招呼',
                '蓝色大肥鱼, the DeepSeek chibi companion. Tap to say hello',
              ),
              child: GestureDetector(
                onTap: () => _act(CompanionMood.wave),
                child: RepaintBoundary(
                  child: SizedBox(
                    height: widget.compact ? 260 : 320,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ExcludeSemantics(
                          child: CustomPaint(
                            painter: AuroraArt(
                              MotionClock.of(context),
                              dark: c.brightness == Brightness.dark,
                              hero: true,
                              seed: c.primary,
                              variant: 2,
                            ),
                          ),
                        ),
                        CompanionArtwork(
                          asset: switch (_mood) {
                            CompanionMood.wave =>
                              'assets/mascot/blue-fat-fish-wave.png',
                            CompanionMood.read =>
                              'assets/mascot/blue-fat-fish-read.png',
                            _ => 'assets/mascot/blue-fat-fish.png',
                          },
                          clock: MotionClock.of(context),
                          gaze: _gaze,
                          pose: _pose,
                          from: _from,
                          to: _to,
                          reduced: reduced,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in [
              (
                CompanionMood.wave,
                Icons.waving_hand_outlined,
                _label('打招呼', 'Hello'),
              ),
              (
                CompanionMood.dance,
                Icons.music_note_outlined,
                _label('跳支舞', 'Dance'),
              ),
              (
                CompanionMood.read,
                Icons.auto_stories_outlined,
                _label('陪我读', 'Read'),
              ),
            ])
              ActionChip(
                avatar: Icon(item.$2, size: 18),
                label: Text(item.$3),
                onPressed: () => _act(item.$1),
              ),
          ],
        ),
      ],
    );
  }
}

/// Loads only the requested pose. Keep the last decoded frame while the next
/// bundled PNG loads; a failed request never substitutes a different character.
class CompanionArtwork extends StatefulWidget {
  const CompanionArtwork({
    super.key,
    required this.asset,
    required this.clock,
    required this.gaze,
    required this.pose,
    required this.from,
    required this.to,
    required this.reduced,
  });
  final String asset;
  final Animation<double> clock, pose;
  final ValueNotifier<Offset> gaze;
  final List<double> from, to;
  final bool reduced;
  @override
  State<CompanionArtwork> createState() => _CompanionArtworkState();
}

class _CompanionArtworkState extends State<CompanionArtwork>
    with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  )..addStatusListener(_releasePrevious);
  late final _listener = ImageStreamListener(_loaded, onError: _failed);
  ImageStream? _stream;
  ImageInfo? _current, _previous;
  bool _error = false;

  void _releasePrevious(AnimationStatus status) {
    if (status != AnimationStatus.completed || _previous == null || !mounted) {
      return;
    }
    setState(() {
      _previous!.dispose();
      _previous = null;
    });
  }

  void _loaded(ImageInfo image, bool synchronous) {
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() {
      _previous?.dispose();
      _previous = _current;
      _current = image;
      _error = false;
    });
    if (_previous == null || widget.reduced) {
      _fade.value = 1;
      _releasePrevious(AnimationStatus.completed);
    } else {
      _fade.forward(from: 0);
    }
  }

  void _failed(Object error, StackTrace? stack) {
    if (mounted) setState(() => _error = true);
  }

  void _resolve() {
    // Limit decode memory independently from the artwork's original resolution.
    final provider = ResizeImage(AssetImage(widget.asset), width: 640);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream;
    stream.addListener(_listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(CompanionArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _resolve();
    if (widget.reduced) {
      _fade.value = 1;
      _releasePrevious(AnimationStatus.completed);
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _fade.dispose();
    _previous?.dispose();
    _current?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (_current != null)
        CustomPaint(
          painter: CompanionFramePainter(
            current: _current!.image,
            previous: _previous?.image,
            fade: _fade,
            clock: widget.clock,
            gaze: widget.gaze,
            pose: widget.pose,
            from: widget.from,
            to: widget.to,
            reduced: widget.reduced,
          ),
        ),
      if (_current == null && !_error)
        Center(
          child: Semantics(
            label: '加载蓝色大肥鱼',
            child: const Icon(Icons.hourglass_empty),
          ),
        ),
      if (_error)
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            borderRadius: BorderRadius.circular(16),
            child: TextButton.icon(
              onPressed: () {
                _stream?.removeListener(_listener);
                _stream = null;
                setState(() => _error = false);
                _resolve();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试角色素材'),
            ),
          ),
        ),
    ],
  );
}

/// Presentation transforms leave the supplied face, hair, lace, embroidery and
/// whale emblem untouched. Idle motion has no additional ticker or rebuild.
class CompanionFramePainter extends CustomPainter {
  CompanionFramePainter({
    required this.current,
    required this.previous,
    required this.fade,
    required this.clock,
    required this.gaze,
    required this.pose,
    required this.from,
    required this.to,
    required this.reduced,
  }) : super(repaint: Listenable.merge([fade, clock, gaze, pose]));
  final ui.Image current;
  final ui.Image? previous;
  final Animation<double> fade, clock, pose;
  final ValueNotifier<Offset> gaze;
  final List<double> from, to;
  final bool reduced;
  @override
  void paint(Canvas canvas, Size size) {
    final t = reduced ? 0.0 : clock.value * math.pi * 2;
    final mix = reduced
        ? 1.0
        : Motion.spring.transform(pose.value).clamp(0.0, 1.0);
    double amount(CompanionMood mood) =>
        from[mood.index] * (1 - mix) + to[mood.index] * mix;
    final dance = amount(CompanionMood.dance);
    final wave = amount(CompanionMood.wave);
    final reading = amount(CompanionMood.read);
    final rhythm = math.sin(t * 8);
    final x = reduced ? 0.0 : gaze.value.dx * 3 + rhythm * dance * 7;
    final y = reduced
        ? 0.0
        : math.sin(t * 2) * 2 * (1 - reading) - rhythm.abs() * dance * 5;
    final angle = reduced
        ? 0.0
        : gaze.value.dx * .015 +
              rhythm * dance * .05 +
              math.sin(t * 4) * wave * .018;
    final breathe = reduced ? 1.0 : 1 + math.sin(t * 2) * .006 * (1 - reading);
    canvas.save();
    canvas.translate(size.width / 2 + x, size.height * .7 + y);
    canvas.rotate(angle);
    canvas.scale(breathe);
    canvas.translate(-size.width / 2, -size.height * .7);
    void draw(ui.Image image, double opacity) {
      final source = Size(image.width.toDouble(), image.height.toDouble());
      final available = Size(
        math.max(1, size.width - 28),
        math.max(1, size.height - 16),
      );
      final fitted = applyBoxFit(BoxFit.contain, source, available).destination;
      final destination = Rect.fromCenter(
        center: size.center(Offset.zero),
        width: fitted.width,
        height: fitted.height,
      );
      canvas.drawImageRect(
        image,
        Offset.zero & source,
        destination,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Colors.white.withValues(alpha: opacity),
      );
    }

    // Fade through, rather than superimposing two pairs of eyes and hands.
    final progress = reduced ? 1.0 : fade.value;
    if (previous != null && progress < .35) {
      draw(previous!, 1 - Curves.easeOut.transform(progress / .35));
    } else {
      draw(
        current,
        previous == null
            ? 1
            : Curves.easeOut.transform(
                ((progress - .35) / .65).clamp(0.0, 1.0),
              ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CompanionFramePainter old) =>
      old.current != current ||
      old.previous != previous ||
      old.fade != fade ||
      old.clock != clock ||
      old.gaze != gaze ||
      old.pose != pose ||
      old.from != from ||
      old.to != to ||
      old.reduced != reduced;
}
