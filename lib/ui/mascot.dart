import 'package:flutter/material.dart';

import '../motion.dart';
import '../companion.dart';
export '../companion.dart' show CompanionMood;
import 'companion_scene.dart';

/// The 3D scene owns its geometry and animation mixer; Flutter owns daily life.
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

class _CompanionStageState extends State<CompanionStage> {
  CompanionMood _mood = CompanionMood.idle;
  CompanionController? _actor, _local;
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
  void _changePose(CompanionMood mood) => setState(() => _mood = mood);
  void _sceneAction(String action) {
    switch (action) {
      case 'pet':
        _actor!.pet();
      case 'celebrate':
        _act(CompanionMood.celebrate);
      case 'shy':
        _act(CompanionMood.shy);
    }
  }

  void _act(CompanionMood mood) => _actor!.select(mood);

  @override
  void dispose() {
    _actor?.removeListener(_syncMood);
    _local?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
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
        SizedBox(
          height: widget.compact ? 300 : 360,
          width: double.infinity,
          child: CompanionScene(mood: _mood, onAction: _sceneAction),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _label(
              '北京时间 · ${_mood.label(widget.language)}',
              'China Standard Time · ${_mood.label(widget.language)}',
            ),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
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
  Widget _portrait(CompanionMood mood) => CompanionScene(
    mood: mood,
    compact: true,
    onAction: (_) => widget.onOpen(),
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
