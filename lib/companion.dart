import 'dart:async';

import 'package:flutter/material.dart';

enum CompanionMood {
  idle('idle', '待机', 'Idle', '我是蓝色大肥鱼。戳戳我？', 'I’m 蓝色大肥鱼. Say hello?'),
  wave(
    'wave',
    '打招呼',
    'Hello',
    '收到！今天也一起探索吧。',
    'Hello! Let’s explore together.',
  ),
  dance(
    'dance',
    '跳支舞',
    'Dance',
    '代码要严谨，快乐不用。',
    'A little rhythm between builds.',
  ),
  read(
    'read',
    '陪我读',
    'Read',
    '安静模式。陪你读完这一篇。',
    'Quiet mode. One good read at a time.',
  ),
  happy('happy', '开心', 'Happy', '好心情，分享给你。', 'A little happiness for you.'),
  think('think', '思考', 'Think', '别急，让我陪你理一理。', 'Let’s think it through.'),
  confused(
    'confused',
    '疑惑',
    'Puzzled',
    '这里好像还有一个问号。',
    'There is something to figure out.',
  ),
  sleep(
    'sleep',
    '打盹',
    'Nap',
    '眯一会儿。回来时叫我。',
    'Taking a little nap. Wake me when you return.',
  ),
  shy('shy', '害羞', 'Shy', '被你发现啦。', 'Oh, you noticed me.'),
  surprised(
    'surprised',
    '惊喜',
    'Surprise',
    '换个角度，又是新发现。',
    'A fresh perspective!',
  ),
  write(
    'write',
    '写作',
    'Write',
    '把灵感写下来，我陪你。',
    'Let’s put that idea into words.',
  ),
  celebrate(
    'celebrate',
    '庆祝',
    'Celebrate',
    '值得庆祝的一小步！',
    'A small step worth celebrating!',
  ),
  search(
    'think',
    '寻找文章',
    'Searching',
    '正在按关键词找文章。',
    'Looking through the articles.',
  ),
  empty(
    'confused',
    '没有结果',
    'No results',
    '暂时没找到，试试短一点的关键词？',
    'No match. Try a shorter search?',
  ),
  loading(
    'think',
    '处理中',
    'Working',
    '请求还在处理中，稍等一下。',
    'The request is still in progress.',
  ),
  saved(
    'happy',
    '已保存',
    'Saved',
    '本机草稿保存好了。',
    'The draft is saved in this browser.',
  ),
  error(
    'confused',
    '遇到问题',
    'Problem',
    '这一步没有完成，看看错误提示再试。',
    'That did not complete. Check the error before retrying.',
  ),
  finished(
    'celebrate',
    '读到末尾',
    'Finished',
    '读到这里啦。要不要聊聊你的想法？',
    'You reached the end. What do you think?',
  ),
  explore(
    'surprised',
    '探索项目',
    'Explore',
    '一起看看这个项目怎么实现。',
    'Let’s explore how this project works.',
  );

  const CompanionMood(
    this.pose,
    this.zh,
    this.en,
    this.messageZh,
    this.messageEn,
  );
  final String pose, zh, en, messageZh, messageEn;
  String get asset =>
      'assets/mascot/blue-fat-fish${pose == 'idle' ? '' : '-$pose'}.png';
  String label(String language) => language.startsWith('zh') ? zh : en;
  String message(String language) =>
      language.startsWith('zh') ? messageZh : messageEn;
  static const actions = [
    idle,
    wave,
    dance,
    read,
    happy,
    think,
    confused,
    sleep,
    shy,
    surprised,
    write,
    celebrate,
  ];
}

/// One scene, one temporary reaction and one inactivity timer. Request tickets
/// prevent late network responses from overwriting a newer route or operation.
class CompanionController extends ChangeNotifier {
  CompanionController({this.idleAfter = const Duration(seconds: 45)}) {
    _armIdle();
  }
  final Duration idleAfter;
  CompanionMood _mood = CompanionMood.idle, _scene = CompanionMood.idle;
  CompanionMood get mood => _mood;
  Timer? _reaction, _idle;
  bool _foreground = true, _disposed = false, _manual = false, _working = false;
  int _priority = 0, _ticket = 0;
  String _route = '';
  void _set(CompanionMood value) {
    if (_disposed || value == _mood) return;
    _mood = value;
    notifyListeners();
  }

  void _armIdle() {
    _idle?.cancel();
    if (!_foreground ||
        _disposed ||
        _priority > 0 ||
        _scene != CompanionMood.idle) {
      return;
    }
    _idle = Timer(idleAfter, () => _set(CompanionMood.sleep));
  }

  void activity() {
    if (!_foreground || _disposed) return;
    if (!_manual && _mood == CompanionMood.sleep) _set(_scene);
    _armIdle();
  }

  void setRoute(String route) {
    if (route == _route || _disposed) return;
    _route = route;
    _ticket++;
    _reaction?.cancel();
    _idle?.cancel();
    _priority = 0;
    _manual = false;
    _working = false;
    final parts = Uri.parse(route).pathSegments;
    _scene = parts.length < 2
        ? CompanionMood.idle
        : switch (parts[1]) {
            'posts' =>
              parts.length > 2 ? CompanionMood.read : CompanionMood.think,
            'projects' => CompanionMood.explore,
            'studio' => CompanionMood.write,
            'friends' || 'about' => CompanionMood.wave,
            _ => CompanionMood.idle,
          };
    _set(_scene);
    _armIdle();
  }

  void select(CompanionMood mood) {
    if (!_foreground || _disposed || _working) return;
    _priority = 0;
    _manual = true;
    react(
      mood,
      priority: 2,
      duration:
          {
            CompanionMood.read,
            CompanionMood.sleep,
            CompanionMood.write,
            CompanionMood.idle,
          }.contains(mood)
          ? null
          : const Duration(seconds: 7),
    );
  }

  void reset() {
    if (_disposed || _working) return;
    _reaction?.cancel();
    _priority = 0;
    _manual = false;
    _set(_scene);
    _armIdle();
  }

  void react(
    CompanionMood mood, {
    int priority = 1,
    Duration? duration = const Duration(seconds: 5),
  }) {
    if (_disposed || !_foreground || _working || priority < _priority) return;
    _reaction?.cancel();
    _idle?.cancel();
    _priority = priority;
    _set(mood);
    if (duration != null) {
      _reaction = Timer(duration, () {
        _priority = 0;
        _manual = false;
        _set(_scene);
        _armIdle();
      });
    }
  }

  int beginWork() {
    final ticket = ++_ticket;
    if (_disposed) return ticket;
    _working = true;
    _manual = false;
    _priority = 3;
    _reaction?.cancel();
    _idle?.cancel();
    _set(CompanionMood.loading);
    return ticket;
  }

  void completeWork(int ticket, CompanionMood result) {
    if (_disposed || !_working || ticket != _ticket) return;
    // Also release the busy lock if the operation finishes in the background.
    _ticket++;
    _working = false;
    _priority = 0;
    if (_foreground) {
      react(result, priority: 3);
    } else {
      _set(_scene);
    }
  }

  void setForeground(bool value) {
    if (_foreground == value || _disposed) return;
    _foreground = value;
    _reaction?.cancel();
    _idle?.cancel();
    if (value) {
      if (!_working) {
        _priority = 0;
        _manual = false;
        _set(_scene);
        _armIdle();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticket++;
    _reaction?.cancel();
    _idle?.cancel();
    super.dispose();
  }
}

class CompanionScope extends InheritedWidget {
  const CompanionScope({
    super.key,
    required this.controller,
    required super.child,
  });
  final CompanionController controller;
  static CompanionController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CompanionScope>()?.controller;
  static CompanionController? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CompanionScope>()?.controller;
  @override
  bool updateShouldNotify(CompanionScope oldWidget) =>
      oldWidget.controller != controller;
}

class CompanionHost extends StatefulWidget {
  const CompanionHost({super.key, required this.route, required this.child});
  final String route;
  final Widget child;
  @override
  State<CompanionHost> createState() => _CompanionHostState();
}

class _CompanionHostState extends State<CompanionHost>
    with WidgetsBindingObserver {
  final _controller = CompanionController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.setRoute(widget.route);
    final state = WidgetsBinding.instance.lifecycleState;
    _controller.setForeground(
      state == null || state == AppLifecycleState.resumed,
    );
  }

  @override
  void didUpdateWidget(CompanionHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route != widget.route) {
      final route = widget.route;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.route == route) _controller.setRoute(route);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _controller.setForeground(state == AppLifecycleState.resumed);
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CompanionScope(
    controller: _controller,
    child: Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        _controller.activity();
        return KeyEventResult.ignored;
      },
      child: Listener(
        onPointerDown: (_) => _controller.activity(),
        onPointerSignal: (_) => _controller.activity(),
        child: widget.child,
      ),
    ),
  );
}
