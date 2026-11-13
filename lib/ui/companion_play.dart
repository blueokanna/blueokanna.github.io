import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../companion.dart';

/// A real repeat-the-sequence game; all rounds and input are local to this dialog.
class CompanionPlay extends StatefulWidget {
  const CompanionPlay({super.key, required this.actor, required this.language});
  final CompanionController actor;
  final String language;
  @override
  State<CompanionPlay> createState() => _CompanionPlayState();
}

class _CompanionPlayState extends State<CompanionPlay>
    with WidgetsBindingObserver {
  final _random = Random();
  final _sequence = <int>[];
  int _input = 0, _generation = 0;
  int? _lit;
  bool _showing = false, _lost = false;
  bool get _zh => widget.language.startsWith('zh');
  String text(String zh, String en) => _zh ? zh : en;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _generation++;
      if (mounted) {
        setState(() {
          _showing = false;
          _lost = true;
          _lit = null;
        });
      }
    }
  }

  Future<void> _next({bool restart = false}) async {
    final generation = ++_generation;
    setState(() {
      if (restart) _sequence.clear();
      _sequence.add(_random.nextInt(4));
      _input = 0;
      _lost = false;
      _showing = true;
    });
    widget.actor.select(CompanionMood.game);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    for (final note in _sequence) {
      if (!mounted || generation != _generation) return;
      setState(() => _lit = note);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted || generation != _generation) return;
      setState(() => _lit = null);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (mounted && generation == _generation) setState(() => _showing = false);
  }

  void _press(int note) {
    if (_showing || _lost || _sequence.isEmpty) return;
    if (_sequence[_input] != note) {
      setState(() => _lost = true);
      widget.actor.select(CompanionMood.confused);
      return;
    }
    setState(() => _input++);
    if (_input == _sequence.length) {
      widget.actor.select(CompanionMood.celebrate);
      _next();
    }
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AlertDialog(
      title: Text(text('蓝色大肥鱼的记忆挑战', 'A little memory challenge')),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text(
                '记住亮起的顺序，再依次点击。每通过一轮就增加一步。',
                'Watch the sequence, then repeat it. Each round adds one step.',
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                _sequence.isEmpty
                    ? text('准备好了吗？', 'Ready?')
                    : _lost
                    ? text(
                        '这次记住了 ${_sequence.length - 1} 步，再来一次？',
                        'You remembered ${_sequence.length - 1} steps. Try again?',
                      )
                    : _showing
                    ? text(
                        '第 ${_sequence.length} 轮 · 看我示范',
                        'Round ${_sequence.length} · Watch',
                      )
                    : text(
                        '轮到你了 · $_input / ${_sequence.length}',
                        'Your turn · $_input / ${_sequence.length}',
                      ),
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                for (var i = 0; i < 4; i++)
                  Semantics(
                    label: '${i + 1}',
                    liveRegion: _lit == i,
                    child: AnimatedContainer(
                      duration: reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: _lit == i ? c.primary : c.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _lit == i ? c.onSurface : c.outlineVariant,
                          width: _lit == i ? 3 : 1,
                        ),
                      ),
                      child: TextButton(
                        onPressed: _showing || _lost || _sequence.isEmpty
                            ? null
                            : () => _press(i),
                        child: Text(
                          _lit == i ? '${i + 1} ●' : '${i + 1}',
                          style: TextStyle(
                            fontSize: 24,
                            color: _lit == i ? c.onPrimary : c.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(text('关闭', 'Close')),
        ),
        FilledButton(
          onPressed: _showing ? null : () => _next(restart: true),
          child: Text(
            text(
              _sequence.isEmpty ? '开始' : '重新开始',
              _sequence.isEmpty ? 'Start' : 'Restart',
            ),
          ),
        ),
      ],
    );
  }
}
