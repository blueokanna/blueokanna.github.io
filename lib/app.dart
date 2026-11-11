import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/link.dart';

import 'content.dart';
import 'motion.dart';
import 'services.dart';

const ink = Color(0xFF243F34);
const lime = Color(0xFFD9F29D);

class PulseLinkApp extends StatefulWidget {
  const PulseLinkApp({super.key});
  @override
  State<PulseLinkApp> createState() => _PulseLinkAppState();
}

class _PulseLinkAppState extends State<PulseLinkApp> {
  bool dark = false, english = false, paused = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Blue · PulseLink',
    debugShowCheckedModeBanner: false,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: BlogHome(
      dark: dark,
      english: english,
      paused: paused,
      onTheme: () => setState(() => dark = !dark),
      onLanguage: () => setState(() => english = !english),
      onMotion: () => setState(() => paused = !paused),
    ),
  );
}

ThemeData _theme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: ink,
    brightness: brightness,
    primary: dark ? lime : ink,
    onPrimary: dark ? ink : Colors.white,
    surface: dark ? const Color(0xFF15251F) : const Color(0xFFF6F7EF),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'sans-serif',
    textTheme: TextTheme(
      bodyMedium: TextStyle(fontSize: 15, height: 1.7, color: scheme.onSurface),
      bodyLarge: TextStyle(fontSize: 17, height: 1.8, color: scheme.onSurface),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.onSurface.withValues(alpha: .15),
    ),
  );
}

class BlogHome extends StatefulWidget {
  const BlogHome({
    super.key,
    required this.dark,
    required this.english,
    required this.paused,
    required this.onTheme,
    required this.onLanguage,
    required this.onMotion,
  });
  final bool dark, english, paused;
  final VoidCallback onTheme, onLanguage, onMotion;
  @override
  State<BlogHome> createState() => _BlogHomeState();
}

class _BlogHomeState extends State<BlogHome> {
  final _scroll = ScrollController();
  final _keys = List.generate(5, (_) => GlobalKey());
  final _service = RepositoryService();
  late Future<List<Repository>> _repos;
  int _selected = 0;
  String tr(String zh, String en) => widget.english ? en : zh;
  @override
  void initState() {
    super.initState();
    _repos = _service.load();
    _scroll.addListener(_track);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _service.dispose();
    super.dispose();
  }

  void _track() {
    var next = 0;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject();
      if (box is RenderBox && box.localToGlobal(Offset.zero).dy < 220) next = i;
    }
    if (next != _selected) setState(() => _selected = next);
  }

  void _go(int i) {
    final target = _keys[i].currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: widget.paused ? Duration.zero : Motion.of(context),
        curve: Motion.curve,
      );
    }
  }

  void _read(int index) {
    final entry = journal[index];
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: tr('关闭阅读', 'Close reader'),
      barrierColor: Colors.black54,
      transitionDuration: widget.paused ? Duration.zero : Motion.of(context),
      pageBuilder: (context, animation, secondary) =>
          _Reader(entry: entry, english: widget.english),
      transitionBuilder: (context, animation, secondary, child) {
        final curved = animation.drive(CurveTween(curve: Motion.curve));
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: curved.drive(
              Tween(begin: const Offset(0, .08), end: Offset.zero),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Aurora(
      paused: widget.paused,
      builder: (context, clock) => Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: AuroraArt(clock, dark: widget.dark),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _header(),
                  Expanded(
                    child: SelectionArea(
                      child: SingleChildScrollView(
                        controller: _scroll,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1240),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.sizeOf(context).width < 700
                                    ? 22
                                    : 48,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(key: _keys[0], height: 32),
                                  _hero(clock),
                                  const SizedBox(height: 48),
                                  _ribbon(),
                                  const SizedBox(height: 88),
                                  _heading(
                                    1,
                                    '01 / JOURNAL',
                                    tr('写下来，慢慢想。', 'Notes worth keeping.'),
                                    tr('本站技术笔记', 'Notes from this site'),
                                  ),
                                  const SizedBox(height: 28),
                                  _journal(),
                                  const SizedBox(height: 88),
                                  _heading(
                                    2,
                                    '02 / OPEN SOURCE',
                                    tr(
                                      '在代码里，保持好奇。',
                                      'Stay curious. Build things.',
                                    ),
                                    'GITHUB / BLUEOKANNA',
                                  ),
                                  const SizedBox(height: 28),
                                  _projects(),
                                  const SizedBox(height: 20),
                                  const ExternalLink(
                                    url: 'https://github.com/blueokanna/m3u8-downloader',
                                    label: 'M3U8 Downloader / GitHub ↗',
                                  ),
                                  const SizedBox(height: 88),
                                  _heading(
                                    3,
                                    '03 / FRIENDS',
                                    tr(
                                      '互联网里的好邻居。',
                                      'Good neighbors on the web.',
                                    ),
                                    tr(
                                      '友链 · 连接有趣的灵魂',
                                      'A small, connected web',
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  _friends(),
                                  const SizedBox(height: 88),
                                  Container(
                                    key: _keys[4],
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: widget.dark
                                          ? const Color(0xFF233B30)
                                          : const Color(0xFFE8EDDF),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(40),
                                        topRight: Radius.circular(40),
                                        bottomRight: Radius.circular(40),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                    ),
                                    child: Wrap(
                                      spacing: 40,
                                      runSpacing: 24,
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 520,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const _Eyebrow(
                                                'A LITTLE ABOUT THIS PLACE',
                                              ),
                                              const SizedBox(height: 18),
                                              Text(
                                                tr(
                                                  '你好，我是 Blue。',
                                                  'Hello, I’m Blue.',
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                tr(
                                                  '这里是 PulseLink，我的个人博客与开源项目入口。记录实现，分享思考，也留一扇通往朋友们的门。',
                                                  'PulseLink is my personal blog and a home for open-source projects. A place for implementation notes, ideas, and friends.',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const ExternalLink(
                                          url: 'https://github.com/blueokanna',
                                          label: 'GitHub / blueokanna',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 42),
                                  Divider(color: colors.outlineVariant),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 22,
                                    ),
                                    child: Wrap(
                                      spacing: 24,
                                      runSpacing: 12,
                                      alignment: WrapAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '© ${DateTime.now().year} Blue · PulseLink',
                                        ),
                                        Text(
                                          'BUILT WITH FLUTTER  /  HOSTED ON GITHUB PAGES',
                                          style: TextStyle(
                                            fontSize: 11,
                                            letterSpacing: 1,
                                            color: colors.onSurfaceVariant,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => _go(0),
                                          child: Text(
                                            tr('回到顶部 ↑', 'Back to top ↑'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      final labels = [
        tr('首页', 'Home'),
        tr('笔记', 'Journal'),
        tr('项目', 'Projects'),
        tr('友链', 'Friends'),
        tr('关于', 'About'),
      ];
      final nav = Wrap(
        spacing: 4,
        children: List.generate(
          labels.length,
          (i) => TextButton(
            onPressed: () => _go(i),
            style: TextButton.styleFrom(
              backgroundColor: _selected == i
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            ),
            child: Text(labels[i]),
          ),
        ),
      );
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant
                  .withValues(alpha: .5),
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.blur_on_rounded, size: 34),
                const SizedBox(width: 10),
                const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'PulseLink',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (wide) nav,
                if (wide) const Spacer(),
                IconButton(
                  onPressed: widget.onMotion,
                  tooltip: tr(
                    widget.paused ? '开启动效' : '暂停动效',
                    widget.paused ? 'Play motion' : 'Pause motion',
                  ),
                  icon: Icon(
                    widget.paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                ),
                IconButton(
                  onPressed: widget.onTheme,
                  tooltip: tr('切换明暗主题', 'Toggle theme'),
                  icon: Icon(
                    widget.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                ),
                IconButton(
                  onPressed: widget.onLanguage,
                  tooltip: tr('Switch to English', '切换中文'),
                  icon: Text(
                    widget.english ? '中' : 'EN',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (!wide)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: nav,
              ),
          ],
        ),
      );
    },
  );
  Widget _hero(Animation<double> clock) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth > 760;
      final title = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(
            tr('BLUE 的数字花园 / 保持生长', 'BLUE’S DIGITAL GARDEN / ALWAYS GROWING'),
          ),
          const SizedBox(height: 28),
          Text(
            tr('代码有逻辑，', 'Built with logic.'),
            style: TextStyle(
              fontSize: wide ? 58 : 38,
              height: 1.3,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
            ),
          ),
          Text(
            tr('生活有回响。', 'Alive with ideas.'),
            style: TextStyle(
              fontSize: wide ? 58 : 38,
              height: 1.4,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
              color: widget.dark ? lime : const Color(0xFF698350),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              tr(
                '你好，欢迎来到我的一小片互联网。\n关于技术、创造，以及值得留下的思考。',
                'Welcome to my little corner of the internet.\nTechnology, making things, and thoughts worth keeping.',
              ),
              style: TextStyle(
                fontSize: 17,
                height: 1.9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => _go(1),
                label: Text(tr('走进笔记', 'Read the journal')),
                icon: const Icon(Icons.arrow_outward_rounded, size: 19),
              ),
              OutlinedButton.icon(
                onPressed: () => _go(3),
                label: Text(tr('认识朋友', 'Meet my friends')),
                icon: const Icon(Icons.spa_outlined, size: 19),
              ),
            ],
          ),
        ],
      );
      final artwork = SizedBox(
        height: wide ? 420 : 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: AuroraArt(clock, dark: widget.dark, hero: true),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 22,
              right: 8,
              child: Transform.rotate(
                angle: .10,
                child: _tag('A WORK IN BLOOM', Icons.north_east),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 8,
              child: Transform.rotate(
                angle: -.06,
                child: _tag('STAY CURIOUS.', Icons.auto_awesome_outlined),
              ),
            ),
          ],
        ),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: wide
            ? Row(
                children: [
                  Expanded(flex: 6, child: title),
                  Expanded(flex: 5, child: artwork),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [title, const SizedBox(height: 24), artwork],
              ),
      );
    },
  );
  Widget _tag(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );
  Widget _ribbon() => Container(
    padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(
      border: Border.symmetric(
        horizontal: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    ),
    child: Wrap(
      spacing: 24,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      children:
          [
                'CODE & CURIOSITY',
                '✳',
                'SMALL IDEAS, REAL THINGS',
                '✳',
                'A PERSONAL SPACE',
              ]
              .map(
                (s) => Text(
                  s,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
              .toList(),
    ),
  );
  Widget _heading(int index, String eyebrow, String title, String side) =>
      Column(
        key: _keys[index],
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(eyebrow),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              Text(
                side,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      );
  Widget _journal() => _ResponsiveGrid(
    minWidth: 280,
    children: List.generate(journal.length, (i) {
      final entry = journal[i];
      final bg = widget.dark
          ? [
              const Color(0xFF304B32),
              const Color(0xFF353D35),
              const Color(0xFF403C31),
            ][i]
          : [lime, const Color(0xFFE7EBE2), const Color(0xFFF0E6D4)][i];
      return _Surface(
        color: bg,
        onTap: () => _read(i),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Eyebrow(entry.tag),
                const Spacer(),
                const Icon(Icons.north_east_rounded, size: 22),
              ],
            ),
            const SizedBox(height: 46),
            Icon(
              [Icons.blur_on, Icons.fingerprint, Icons.interests_outlined][i],
              size: 44,
            ),
            const SizedBox(height: 26),
            Text(
              widget.english ? entry.titleEn : entry.title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(widget.english ? entry.summaryEn : entry.summary),
            const SizedBox(height: 32),
            Text(
              tr('阅读笔记  ↗', 'Read note  ↗'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }),
  );
  Widget _projects() => FutureBuilder<List<Repository>>(
    future: _repos,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(tr('正在读取 GitHub 项目…', 'Loading GitHub projects…')),
              ),
            ],
          ),
        );
      }
      if (snapshot.hasError || snapshot.data!.isEmpty) {
        return _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(
                  snapshot.hasError ? '暂时无法读取 GitHub 项目。' : '暂时没有可显示的公开项目。',
                  snapshot.hasError
                      ? 'GitHub is temporarily unavailable.'
                      : 'No public projects to display.',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        setState(() => _repos = _service.load(refresh: true)),
                    icon: const Icon(Icons.refresh),
                    label: Text(tr('重试', 'Retry')),
                  ),
                  const ExternalLink(
                    url: 'https://github.com/blueokanna?tab=repositories',
                    label: 'GitHub ↗',
                  ),
                ],
              ),
            ],
          ),
        );
      }
      return _ResponsiveGrid(
        minWidth: 300,
        children: snapshot.data!
            .map(
              (repo) => _Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.code_rounded),
                        const Spacer(),
                        Text('☆ ${repo.stars}'),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      repo.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      repo.description.isEmpty
                          ? tr(
                              '项目说明见 GitHub 仓库。',
                              'Details in the GitHub repository.',
                            )
                          : repo.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(repo.language),
                        ExternalLink(
                          url: repo.url,
                          label: tr('查看源码', 'Source'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    },
  );
  Widget _friends() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ResponsiveGrid(
        minWidth: 340,
        children: List.generate(friends.length, (i) {
          final friend = friends[i];
          return _Surface(
            color: widget.dark
                ? const Color(0xFF2C3833)
                : i == 0
                ? const Color(0xFFE3EBE9)
                : const Color(0xFFF1E4DC),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(i == 0 ? 18 : 28),
                      ),
                      child: friend.avatar == null
                          ? const Icon(
                              Icons.grain_rounded,
                              color: ink,
                              size: 32,
                            )
                          : SvgPicture.network(
                              friend.avatar!,
                              semanticsLabel: friend.name,
                              placeholderBuilder: (_) =>
                                  const Icon(Icons.spa, color: ink),
                              errorBuilder: (_, error, stack) =>
                                  const Icon(Icons.spa, color: ink),
                            ),
                    ),
                    const Spacer(),
                    Text(
                      '0${i + 1}',
                      style: const TextStyle(fontSize: 12, letterSpacing: 2),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.english ? friend.descEn : friend.desc),
                const SizedBox(height: 20),
                ExternalLink(
                  url: friend.url,
                  label: '${Uri.parse(friend.url).host} ↗',
                ),
              ],
            ),
          );
        }),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(tr('交换一扇窗，看见更大的世界。', 'Another window onto a wider world.')),
          TextButton.icon(
            onPressed: () async {
              try {
                await Clipboard.setData(
                  const ClipboardData(
                    text: '{"name":"Blue 的 PulseLink","url":"https://www.pulselink.top/","desc":"Blue 的个人博客与开源项目","avatar":"https://www.pulselink.top/favicon.png"}',
                  ),
                );
              } on PlatformException {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      tr(
                        '浏览器未允许写入剪贴板，请手动复制本站地址。',
                        'Clipboard access was denied. Please copy the site address manually.',
                      ),
                    ),
                  ),
                );
                return;
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('本站友链信息已复制', 'Site link copied'))),
              );
            },
            icon: const Icon(Icons.copy_outlined, size: 17),
            label: Text(tr('复制本站友链', 'Copy this site’s link')),
          ),
        ],
      ),
    ],
  );
}

class _Reader extends StatelessWidget {
  const _Reader({required this.entry, required this.english});
  final JournalEntry entry;
  final bool english;
  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(18),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 12, 12, 12),
            child: Row(
              children: [
                Expanded(child: _Eyebrow(entry.tag)),
                IconButton(
                  autofocus: true,
                  tooltip: english ? 'Close' : '关闭',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      english ? entry.titleEn : entry.title,
                      style: const TextStyle(
                        fontSize: 32,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      english ? entry.bodyEn : entry.body,
                      style: const TextStyle(fontSize: 17, height: 2),
                    ),
                    const SizedBox(height: 32),
                    const ExternalLink(
                      url: 'https://github.com/blueokanna/blueokanna.github.io',
                      label: 'PulseLink / Source ↗',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
    ),
  );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.color, this.onTap});
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? Theme.of(context).colorScheme.surfaceContainerLow,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(28),
      ),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(28), child: child),
    ),
  );
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children, required this.minWidth});
  final List<Widget> children;
  final double minWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = ((constraints.maxWidth + 20) / (minWidth + 20))
          .floor()
          .clamp(1, 3);
      final width = (constraints.maxWidth - 20 * (columns - 1)) / columns;
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}

class ExternalLink extends StatelessWidget {
  const ExternalLink({super.key, required this.url, required this.label});
  final String url, label;
  @override
  Widget build(BuildContext context) {
    final uri = safeWebUri(url);
    if (uri == null) return Text(label);
    return Link(
      uri: uri,
      target: LinkTarget.blank,
      builder: (context, followLink) =>
          TextButton(onPressed: followLink, child: Text(label)),
    );
  }
}
