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
    'sleep-rest',
    '睡觉',
    'Sleeping',
    '呼……今晚也要睡个好觉，早上八点见。',
    'Zzz… See you at eight in the morning.',
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
  eat('eat', '吃饭', 'Meal', '认真吃饭，十分钟后再一起玩。', 'Time for a ten-minute meal.'),
  wash(
    'wash',
    '洗漱',
    'Freshen up',
    '刷刷牙、洗洗脸，清清爽爽开始新一天。',
    'Brushing teeth and getting ready for the day.',
  ),
  wake('wake', '起床', 'Wake up', '伸个懒腰，早安！', 'A big stretch. Good morning!'),
  game('game', '玩游戏', 'Gaming', '这一关，让我再试一次！', 'One more try at this level!'),
  bedtime(
    'bedtime',
    '准备睡觉',
    'Wind down',
    '收好今天的小心事，准备睡觉。',
    'Putting the day away. Bedtime soon.',
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
    eat,
    wash,
    wake,
    game,
    bedtime,
  ];
}

/// A wall-clock schedule, independent of browser locale and elapsed timers.
/// UTC+08:00 is China Standard Time; it has no seasonal clock changes.
class CompanionRoutine {
  static DateTime chinaTime(DateTime instant) =>
      instant.toUtc().add(const Duration(hours: 8));

  static CompanionMood? appointment(DateTime instant) {
    final time = chinaTime(instant);
    final minute = time.hour * 60 + time.minute;
    if (minute >= 23 * 60 + 45 || minute < 8 * 60) return CompanionMood.sleep;
    if (minute < 8 * 60 + 2) return CompanionMood.wake;
    if (minute < 8 * 60 + 10) return CompanionMood.wash;
    for (final start in [8 * 60 + 30, 12 * 60 + 30, 18 * 60]) {
      if (minute >= start && minute < start + 10) return CompanionMood.eat;
    }
    if (minute >= 23 * 60 + 40) return CompanionMood.bedtime;
    return null;
  }

  static CompanionMood activity(DateTime instant) {
    final scheduled = appointment(instant);
    if (scheduled != null) return scheduled;
    // Seeded time slots: refresh resumes the same activity, every day differs.
    final slot = instant.toUtc().millisecondsSinceEpoch ~/ 180000;
    var seed = (slot ^ (slot >> 16)) & 0x7fffffff;
    seed = (seed * 1664525 + 1013904223) & 0x7fffffff;
    const choices = [
      CompanionMood.idle,
      CompanionMood.read,
      CompanionMood.game,
      CompanionMood.write,
      CompanionMood.think,
      CompanionMood.dance,
      CompanionMood.happy,
      CompanionMood.shy,
    ];
    return choices[(seed ^ (seed >> 13)) % choices.length];
  }
}

/// Schedule > in-flight work > temporary interaction > autonomous activity.
/// Request generations isolate late callbacks from navigation and disposal.
class CompanionController extends ChangeNotifier {
  CompanionController({
    this.idleAfter = const Duration(seconds: 45),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _mood = CompanionRoutine.activity(_now());
    _scheduled = CompanionRoutine.appointment(_now());
    _armClock();
  }
  final Duration idleAfter;
  final DateTime Function() _now;
  late CompanionMood _mood;
  CompanionMood? _scheduled;
  CompanionMood get mood => _mood;
  bool get scheduled => CompanionRoutine.appointment(_now()) != null;
  DateTime get chinaTime => CompanionRoutine.chinaTime(_now());
  Timer? _reaction, _clock;
  bool _foreground = true, _disposed = false, _working = false;
  int _priority = 0, _ticket = 0, _interactions = 0;
  String _route = '';
  void _set(CompanionMood value) {
    if (_disposed || value == _mood) return;
    _mood = value;
    notifyListeners();
  }

  CompanionMood get _baseline => CompanionRoutine.activity(_now());
  void _armClock() {
    _clock?.cancel();
    if (!_foreground || _disposed) return;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => synchronize());
  }

  void synchronize() {
    if (_disposed || !_foreground) return;
    final appointment = CompanionRoutine.appointment(_now());
    if (appointment != _scheduled) {
      _scheduled = appointment;
      _reaction?.cancel();
      _priority = 0;
      _set(appointment ?? (_working ? CompanionMood.loading : _baseline));
    } else if (appointment != null) {
      _set(appointment);
    } else if (_priority == 0 && !_working) {
      _set(_baseline);
    }
  }

  void activity() {
    // Reading/scrolling does not repeatedly restart the character's day.
    if (_foreground && !_disposed) synchronize();
  }

  void setRoute(String route) {
    if (route == _route || _disposed) return;
    _route = route;
    _ticket++;
    _working = false;
    reset();
  }

  void select(CompanionMood mood) {
    if (!_foreground || _disposed || _working) return;
    react(mood, priority: 2, duration: const Duration(seconds: 18));
  }

  void pet() {
    const reactions = [
      CompanionMood.happy,
      CompanionMood.shy,
      CompanionMood.wave,
      CompanionMood.celebrate,
      CompanionMood.surprised,
    ];
    select(reactions[_interactions++ % reactions.length]);
  }

  void reset() {
    if (_disposed || _working) return;
    _reaction?.cancel();
    _priority = 0;
    _set(_baseline);
  }

  void react(
    CompanionMood mood, {
    int priority = 1,
    Duration? duration = const Duration(seconds: 5),
  }) {
    if (_disposed || !_foreground || _working || priority < _priority) return;
    synchronize();
    if (scheduled) return;
    _reaction?.cancel();
    _priority = priority;
    _set(mood);
    // Every interaction eventually returns to daily life.
    _reaction = Timer(duration ?? idleAfter, () {
      _priority = 0;
      _set(_baseline);
    });
  }

  int beginWork() {
    final ticket = ++_ticket;
    if (_disposed) return ticket;
    _working = true;
    _priority = 3;
    _reaction?.cancel();
    _set(CompanionRoutine.appointment(_now()) ?? CompanionMood.loading);
    return ticket;
  }

  void completeWork(int ticket, CompanionMood result) {
    if (_disposed || !_working || ticket != _ticket) return;
    _ticket++;
    _working = false;
    _priority = 0;
    if (_foreground) {
      react(result, priority: 3);
    } else {
      _set(_baseline);
    }
  }

  void setForeground(bool value) {
    if (_foreground == value || _disposed) return;
    _foreground = value;
    _reaction?.cancel();
    _clock?.cancel();
    if (value) {
      _priority = 0;
      _scheduled = CompanionRoutine.appointment(_now());
      _set(_scheduled ?? (_working ? CompanionMood.loading : _baseline));
      _armClock();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticket++;
    _reaction?.cancel();
    _clock?.cancel();
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
  const CompanionHost({
    super.key,
    required this.route,
    required this.child,
    this.now,
  });
  final String route;
  final DateTime Function()? now;
  final Widget child;
  @override
  State<CompanionHost> createState() => _CompanionHostState();
}

class _CompanionHostState extends State<CompanionHost>
    with WidgetsBindingObserver {
  late final _controller = CompanionController(now: widget.now);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.setRoute(widget.route);
    final state = WidgetsBinding.instance.lifecycleState;
    _controller.setForeground(state == null || _visible(state));
  }

  // A focused same-origin iframe makes Flutter inactive while the page is still
  // visible. Only hidden/paused/detached states suspend the companion's life.
  bool _visible(AppLifecycleState state) =>
      state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;

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
      _controller.setForeground(_visible(state));
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
