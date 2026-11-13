import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'companion_play.dart';

import 'package:flutter/material.dart';

import '../motion.dart';
import '../companion.dart';
export '../companion.dart' show CompanionMood;
import 'clock_scope.dart';

/// The bundled character artwork is kept intact. Aurora only animates its
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
  List<double> _from = List.generate(
        CompanionMood.values.length,
        (i) => i == 0 ? 1 : 0,
      ),
      _to = List.generate(CompanionMood.values.length, (i) => i == 0 ? 1 : 0);
  CompanionMood _mood = CompanionMood.idle;
  CompanionController? _actor, _local;
  bool _expanded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final actor =
        CompanionScope.maybeOf(context) ?? (_local ??= CompanionController());
    if (_actor == actor) return;
    _actor?.removeListener(_syncMood);
    _actor = actor;
    actor.addListener(_syncMood);
    _syncMood();
  }

  void _syncMood() {
    if (_actor!.mood != _mood) _changePose(_actor!.mood);
  }

  bool get _zh => widget.language.startsWith('zh');
  String _label(String zh, String en) => _zh ? zh : en;
  void _changePose(CompanionMood mood) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final progress = reduced
        ? 1.0
        : Motion.spring.transform(_pose.value).clamp(0.0, 1.0);
    setState(() {
      _from = List.generate(
        CompanionMood.values.length,
        (i) => _from[i] * (1 - progress) + _to[i] * progress,
      );
      _to = List.generate(
        CompanionMood.values.length,
        (i) => i == mood.index ? 1.0 : 0.0,
      );
      _mood = mood;
    });
    if (reduced) {
      _pose.value = 1;
    } else {
      _pose.forward(from: 0);
    }
  }

  void _act(CompanionMood mood) => _actor!.select(mood);

  @override
  void dispose() {
    _actor?.removeListener(_syncMood);
    _local?.dispose();
    _gaze.dispose();
    _pose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final message = _mood.message(widget.language);
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
            onEnter: (_) => _actor?.activity(),
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
                onTap: () => _actor!.pet(),
                onDoubleTap: () => _act(CompanionMood.celebrate),
                onLongPress: () => _act(CompanionMood.shy),
                child: RepaintBoundary(
                  child: SizedBox(
                    height: widget.compact ? 260 : 320,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CompanionArtwork(
                          asset: _mood.asset,
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
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _label(
              '北京时间 · 自由活动随时间变化',
              'China Standard Time ? A little life of her own',
            ),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mood
                in _expanded
                    ? CompanionMood.actions
                    : [
                        CompanionMood.wave,
                        CompanionMood.dance,
                        CompanionMood.read,
                        CompanionMood.game,
                        CompanionMood.write,
                        CompanionMood.eat,
                      ])
              ActionChip(
                avatar: Icon(companionIcon(mood), size: 18),
                label: Text(mood.label(widget.language)),
                onPressed: () => _act(mood),
              ),
            TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.apps),
              label: Text(
                _label(
                  _expanded ? '收起动作' : '更多动作 · 17',
                  _expanded ? 'Less' : 'All 17 activities',
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    CompanionPlay(actor: _actor!, language: widget.language),
              ),
              icon: const Icon(Icons.sports_esports_outlined),
              label: Text(_label('一起玩记忆游戏', 'Memory game')),
            ),
            if (_expanded)
              TextButton(
                onPressed: _actor!.reset,
                child: Text(_label('恢复作息', 'Daily routine')),
              ),
          ],
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _label(
                '23:45–08:00 睡觉 · 08:00 起床 · 08:02–08:10 洗漱\n08:30 / 12:30 / 18:00 用餐，各 10 分钟\n点击摸摸头 · 双击庆祝 · 长按害羞。作息期间会专心休息或吃饭。',
                'Sleep 23:45–08:00 · Wake 08:00 · Wash 08:02–08:10\nMeals 08:30 / 12:30 / 18:00, ten minutes each\nTap to pet · Double tap to celebrate · Hold for a shy reaction.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
    this.decodeWidth = 640,
    this.compact = false,
  });
  final String asset;
  final Animation<double> clock, pose;
  final ValueNotifier<Offset> gaze;
  final List<double> from, to;
  final bool reduced;
  final int decodeWidth;
  final bool compact;
  @override
  State<CompanionArtwork> createState() => _CompanionArtworkState();
}

class _CompanionArtworkState extends State<CompanionArtwork>
    with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
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
    final provider = ResizeImage(
      AssetImage(widget.asset),
      width: widget.decodeWidth,
    );
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
    if (oldWidget.asset != widget.asset ||
        oldWidget.decodeWidth != widget.decodeWidth) {
      _resolve();
    }
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
            child: widget.compact
                ? IconButton(
                    tooltip: '重试角色素材',
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: _retry,
                  )
                : TextButton.icon(
                    onPressed: () {
                      _retry();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试角色素材'),
                  ),
          ),
        ),
    ],
  );

  void _retry() {
    _stream?.removeListener(_listener);
    _stream = null;
    setState(() => _error = false);
    _resolve();
  }
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
    final reading = amount(CompanionMood.read) + amount(CompanionMood.write);
    final sleepy = amount(CompanionMood.sleep);
    final eating = amount(CompanionMood.eat);
    final washing = amount(CompanionMood.wash);
    final gaming = amount(CompanionMood.game);
    final waking = amount(CompanionMood.wake);
    final joy =
        amount(CompanionMood.happy) +
        amount(CompanionMood.saved) +
        amount(CompanionMood.celebrate) +
        amount(CompanionMood.finished);
    final thoughtful =
        amount(CompanionMood.think) +
        amount(CompanionMood.search) +
        amount(CompanionMood.loading);
    final puzzled =
        amount(CompanionMood.confused) +
        amount(CompanionMood.empty) +
        amount(CompanionMood.error);
    final shy = amount(CompanionMood.shy);
    final surprise =
        amount(CompanionMood.surprised) + amount(CompanionMood.explore);
    final quiet = (1 - reading * .9 - sleepy * .7).clamp(0.0, 1.0);
    final rhythm = math.sin(t * 8);
    final x = reduced ? 0.0 : gaze.value.dx * 3 * quiet + rhythm * dance * 7;
    final y = reduced
        ? 0.0
        : math.sin(t * 2) * 2 * quiet -
              rhythm.abs() * dance * 5 -
              math.sin(t * 4).abs() * joy * 3 +
              math.sin(t) * sleepy * 1.5 +
              math.sin(t * 10) * eating * 1.2 +
              math.sin(t * 14) * washing * .8 +
              math.sin(t * 6) * gaming * 1.5 -
              math.sin(t * 2).abs() * waking * 4 +
              shy * 2 -
              surprise * 2;
    final angle = reduced
        ? 0.0
        : gaze.value.dx * .015 * quiet +
              rhythm * dance * .05 +
              math.sin(t * 4) * wave * .018 +
              math.sin(t) * sleepy * .012 +
              math.sin(t * 2) * thoughtful * .008 +
              math.sin(t * 2) * puzzled * .018 +
              shy * .012;
    final breathe = reduced
        ? 1.0
        : 1 + math.sin(t * 2) * (.006 + sleepy * .009);
    canvas.save();
    canvas.translate(size.width / 2 + x, size.height * .7 + y);
    canvas.rotate(angle);
    canvas.scale(breathe);
    canvas.translate(-size.width / 2, -size.height * .7);
    void draw(ui.Image image, double opacity) {
      final source = Size(image.width.toDouble(), image.height.toDouble());
      final available = Size(
        math.max(1, size.width - math.min(28, size.width * .08)),
        math.max(1, size.height - math.min(16, size.height * .05)),
      );
      final fitted = applyBoxFit(BoxFit.contain, source, available).destination;
      final destination = Rect.fromCenter(
        center: size.center(Offset.zero),
        width: fitted.width,
        height: fitted.height,
      );
      if (reduced) {
        canvas.drawImageRect(
          image,
          Offset.zero & source,
          destination,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..color = Colors.white.withValues(alpha: opacity),
        );
        return;
      }
      const columns = 16, rows = 24;
      final positions = Float32List((columns + 1) * (rows + 1) * 2);
      final texture = Float32List(positions.length);
      final indices = Uint16List(columns * rows * 6);
      for (var row = 0; row <= rows; row++) {
        for (var col = 0; col <= columns; col++) {
          final u = col / columns, v = row / rows;
          final i = (row * (columns + 1) + col) * 2;
          // Keep face and costume center stable; move the outer hair and hands.
          final edge = math.pow((u - .5).abs() * 2, 1.5).toDouble();
          final middle = math.sin(v * math.pi);
          final hands = math.exp(-math.pow((v - .57) * 8, 2));
          final sway =
              math.sin(t * 3 + v * 5) * edge * middle * (1 - sleepy * .7);
          final handMotion =
              hands *
              edge *
              (math.sin(t * 12) * washing * 2 +
                  math.sin(t * 8) * eating * 1.5 +
                  math.sin(t * 10) * gaming +
                  math.sin(t * 6) * wave * 2);
          positions[i] =
              destination.left + u * destination.width + sway * 2 + handMotion;
          positions[i + 1] =
              destination.top +
              v * destination.height +
              math.sin(t * 2) * middle * (1 - edge) * (sleepy * 2 + .5);
          texture[i] = u * image.width;
          texture[i + 1] = v * image.height;
        }
      }
      var cursor = 0;
      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < columns; col++) {
          final a = row * (columns + 1) + col, b = a + columns + 1;
          for (final index in [a, b, a + 1, a + 1, b, b + 1]) {
            indices[cursor++] = index;
          }
        }
      }
      final vertices = ui.Vertices.raw(
        ui.VertexMode.triangles,
        positions,
        textureCoordinates: texture,
        indices: indices,
      );
      final shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
      );
      canvas.drawVertices(
        vertices,
        BlendMode.modulate,
        Paint()
          ..shader = shader
          ..filterQuality = FilterQuality.medium
          ..colorFilter = ColorFilter.mode(
            Colors.white.withValues(alpha: opacity),
            BlendMode.modulate,
          ),
      );
      vertices.dispose();
      shader.dispose();
    }

    final progress = reduced
        ? 1.0
        : Curves.easeInOutCubic.transform(fade.value);
    // Keep one fully opaque image behind the incoming frame: no blank flash.
    if (previous != null && progress < 1) draw(previous!, 1);
    draw(current, previous == null ? 1 : progress);
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

IconData companionIcon(CompanionMood mood) => switch (mood) {
  CompanionMood.eat => Icons.ramen_dining,
  CompanionMood.wash => Icons.water_drop_outlined,
  CompanionMood.wake => Icons.wb_sunny_outlined,
  CompanionMood.game => Icons.sports_esports_outlined,
  CompanionMood.bedtime => Icons.nights_stay_outlined,
  CompanionMood.wave => Icons.waving_hand_outlined,
  CompanionMood.dance => Icons.music_note_outlined,
  CompanionMood.read => Icons.auto_stories_outlined,
  CompanionMood.sleep => Icons.bedtime_outlined,
  CompanionMood.write => Icons.edit_note,
  CompanionMood.think ||
  CompanionMood.search ||
  CompanionMood.loading => Icons.psychology_outlined,
  CompanionMood.celebrate ||
  CompanionMood.finished => Icons.celebration_outlined,
  CompanionMood.confused ||
  CompanionMood.empty ||
  CompanionMood.error => Icons.help_outline,
  CompanionMood.shy => Icons.favorite_border,
  CompanionMood.surprised ||
  CompanionMood.explore => Icons.auto_awesome_outlined,
  CompanionMood.saved => Icons.check_circle_outline,
  _ => Icons.sentiment_satisfied_alt,
};

/// A small, keyboard-accessible companion stays visible outside the hero.
class CompanionDock extends StatefulWidget {
  const CompanionDock({
    super.key,
    required this.language,
    required this.clock,
    required this.onOpen,
    this.inline = false,
  });
  final String language;
  final Animation<double> clock;
  final VoidCallback onOpen;
  final bool inline;
  @override
  State<CompanionDock> createState() => _CompanionDockState();
}

class _CompanionDockState extends State<CompanionDock> {
  final _gaze = ValueNotifier<Offset>(Offset.zero);
  @override
  void dispose() {
    _gaze.dispose();
    super.dispose();
  }

  Widget _portrait(CompanionMood mood) => RepaintBoundary(
    child: CompanionArtwork(
      asset: mood.asset,
      clock: widget.clock,
      gaze: _gaze,
      pose: const AlwaysStoppedAnimation(1),
      from: List.generate(
        CompanionMood.values.length,
        (i) => i == mood.index ? 1 : 0,
      ),
      to: List.generate(
        CompanionMood.values.length,
        (i) => i == mood.index ? 1 : 0,
      ),
      reduced: MediaQuery.disableAnimationsOf(context),
      decodeWidth: 160,
      compact: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final actor = CompanionScope.maybeOf(context);
    if (actor == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: actor,
      builder: (context, _) => Tooltip(
        message: widget.language.startsWith('zh') ? '叫出蓝色大肥鱼' : 'Meet 蓝色大肥鱼',
        child: SizedBox(
          width: widget.inline ? double.infinity : 88,
          height: widget.inline ? 76 : 112,
          child: Material(
            elevation: 2,
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onOpen,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: widget.inline
                    ? Row(
                        children: [
                          SizedBox(width: 64, child: _portrait(actor.mood)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '蓝色大肥鱼',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  actor.mood.label(widget.language),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium,
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.keyboard_arrow_up),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: _portrait(actor.mood)),
                          Text(
                            actor.mood.label(widget.language),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
