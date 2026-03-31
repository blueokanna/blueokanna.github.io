import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

import 'l10n.dart';
import 'services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  PulseLinkApp — root
// ═══════════════════════════════════════════════════════════════════════════════
class PulseLinkApp extends StatefulWidget {
  const PulseLinkApp({super.key});
  @override
  State<PulseLinkApp> createState() => _PulseLinkAppState();
}

class _PulseLinkAppState extends State<PulseLinkApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  AppLanguage _lang = AppLanguage.zh;

  void _toggleTheme() => setState(() {
        _themeMode =
            _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      });

  void _toggleLang() => setState(() {
        _lang = _lang == AppLanguage.zh ? AppLanguage.en : AppLanguage.zh;
      });

  @override
  Widget build(BuildContext context) {
    final s = S.of(_lang);
    return MaterialApp(
      title: s.appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: PulseLinkHomePage(
        themeMode: _themeMode,
        lang: _lang,
        onToggleTheme: _toggleTheme,
        onToggleLang: _toggleLang,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Theme (M3 Expressive)
// ═══════════════════════════════════════════════════════════════════════════════
ThemeData _buildTheme(Brightness brightness) {
  final seed = const Color(0xFF0F7A65);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
  );
  final isDark = brightness == Brightness.dark;
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF091411) : const Color(0xFFF8F4EC),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      side: BorderSide.none,
    ),
    cardTheme: CardThemeData(
      color: isDark
          ? const Color(0xFF11211B)
          : Colors.white.withValues(alpha: .82),
      shadowColor: Colors.black.withValues(alpha: .06),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(64)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStatePropertyAll(
        base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      height: 74,
      backgroundColor: isDark
          ? const Color(0xFF102019).withValues(alpha: .92)
          : Colors.white.withValues(alpha: .92),
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(40)),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HomePage
// ═══════════════════════════════════════════════════════════════════════════════
class PulseLinkHomePage extends StatefulWidget {
  const PulseLinkHomePage({
    super.key,
    required this.themeMode,
    required this.lang,
    required this.onToggleTheme,
    required this.onToggleLang,
  });
  final ThemeMode themeMode;
  final AppLanguage lang;
  final VoidCallback onToggleTheme, onToggleLang;

  @override
  State<PulseLinkHomePage> createState() => _PulseLinkHomePageState();
}

class _PulseLinkHomePageState extends State<PulseLinkHomePage>
    with TickerProviderStateMixin {
  late final AnimationController _ambientCtrl;
  late final AnimationController _pulseCtrl;
  late final ScrollController _scrollCtrl;

  WeatherSnapshot? _weather;
  GitHubSnapshot? _github;
  bool _loadingGH = true;
  String? _ghError;
  int _selectedIdx = 0;
  bool _showTop = false;
  late final HolidayTheme _holiday;

  // Blog state
  final List<BlogArticle> _articles = [];
  bool _generatingArticle = false;

  // AI Chat state
  bool _chatOpen = false;
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatInputCtrl = TextEditingController();
  bool _chatLoading = false;

  S get s => S.of(widget.lang);

  List<NavSection> get _sections => [
        NavSection(id: 'hero', label: s.navHome, icon: Icons.home_rounded),
        NavSection(id: 'about', label: s.navAbout, icon: Icons.person_rounded),
        NavSection(
          id: 'skills',
          label: s.navSkills,
          icon: Icons.auto_awesome_rounded,
        ),
        NavSection(id: 'blog', label: s.navBlog, icon: Icons.article_rounded),
        NavSection(
          id: 'projects',
          label: s.navProjects,
          icon: Icons.folder_copy_rounded,
        ),
        NavSection(
            id: 'contact', label: s.navContact, icon: Icons.forum_rounded),
      ];

  late final Map<String, GlobalKey> _sectionKeys = {
    for (final sec in _sections) sec.id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _holiday = HolidayTheme.forToday(DateTime.now());
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    _loadWeather();
    _loadGitHub();
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _ambientCtrl.dispose();
    _pulseCtrl.dispose();
    _chatInputCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollCtrl.offset > 540;
    if (show != _showTop && mounted) setState(() => _showTop = show);
    int active = _selectedIdx;
    for (var i = 0; i < _sections.length; i++) {
      final box =
          _sectionKeys[_sections[i].id]?.currentContext?.findRenderObject();
      if (box is RenderBox) {
        final top = box.localToGlobal(Offset.zero).dy;
        final bottom = top + box.size.height;
        if (top <= 160 && bottom > 160) {
          active = i;
          break;
        }
      }
    }
    if (active != _selectedIdx && mounted)
      setState(() => _selectedIdx = active);
  }

  Future<void> _scrollTo(String id) async {
    final ctx = _sectionKeys[id]?.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubicEmphasized,
        alignment: .03,
      );
    }
  }

  Future<void> _loadWeather() async {
    final w = await WeatherSnapshot.load();
    if (mounted) setState(() => _weather = w);
  }

  Future<void> _loadGitHub() async {
    try {
      final gh = await GitHubSnapshot.load();
      if (mounted)
        setState(() {
          _github = gh;
          _loadingGH = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loadingGH = false;
          _ghError = e.toString();
          _github = GitHubSnapshot.fallback();
        });
    }
  }

  Future<void> _generateArticle() async {
    if (_generatingArticle || !ZhipuAiService.isConfigured) return;
    setState(() => _generatingArticle = true);
    final article = await ZhipuAiService.generateTechArticle(widget.lang);
    if (mounted) {
      setState(() {
        _generatingArticle = false;
        if (article != null) _articles.insert(0, article);
      });
    }
  }

  Future<void> _sendChat() async {
    final text = _chatInputCtrl.text.trim();
    if (text.isEmpty || _chatLoading || !ZhipuAiService.isConfigured) return;
    setState(() {
      _chatMessages.add(ChatMessage(role: 'user', content: text));
      _chatLoading = true;
    });
    _chatInputCtrl.clear();
    final messages = [
      ChatMessage(
        role: 'system',
        content: widget.lang == AppLanguage.zh
            ? '你是Blue的个人博客AI助手，基于智谱清言GLM-4-Flash。请用中文回答，简洁专业。'
            : "You are Blue's personal blog AI assistant, powered by Zhipu GLM-4-Flash. Answer concisely and professionally.",
      ),
      ..._chatMessages,
    ].map((m) => m.toMap()).toList();
    final response = await ZhipuAiService.chat(messages);
    if (mounted) {
      setState(() {
        _chatMessages.add(
          ChatMessage(
            role: 'assistant',
            content: response ??
                (s.isZh ? '抱歉，暂时无法回复。' : 'Sorry, unable to respond right now.'),
          ),
        );
        _chatLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final dc = DeviceClass.fromWidth(constraints.maxWidth);
        final hp = switch (dc) {
          DeviceClass.mobile => 16.0,
          DeviceClass.tablet => 28.0,
          DeviceClass.desktop => 52.0,
        };
        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              // ── Ambient backdrop ──
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ambientCtrl,
                  builder: (context, _) => CustomPaint(
                    painter: _AmbientPainter(
                      progress: _ambientCtrl.value,
                      colors: [
                        cs.primary.withValues(alpha: .10),
                        cs.tertiary.withValues(alpha: .08),
                        _holiday.accent.withValues(alpha: .10),
                      ],
                      brightness: theme.brightness,
                    ),
                  ),
                ),
              ),
              // ── Gradient overlay ──
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.brightness == Brightness.dark
                            ? const Color(0xFF0B1713)
                            : const Color(0xFFF6F2EA),
                        theme.scaffoldBackgroundColor,
                        theme.scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
              // ── Main content ──
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(hp, 12, hp, 0),
                      child: _TopBar(
                        weather: _weather,
                        holiday: _holiday,
                        sections: _sections,
                        selectedIdx: _selectedIdx,
                        isDesktop: dc == DeviceClass.desktop,
                        isDark: widget.themeMode == ThemeMode.dark,
                        lang: widget.lang,
                        onSectionTap: _scrollTo,
                        onToggleTheme: widget.onToggleTheme,
                        onToggleLang: widget.onToggleLang,
                      ),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        controller: _scrollCtrl,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          _sliverSection(
                            'hero',
                            hp,
                            24,
                            _HeroSection(
                              dc: dc,
                              pulse: _pulseCtrl,
                              holiday: _holiday,
                              weather: _weather,
                              lang: widget.lang,
                              onPrimary: () => _scrollTo('projects'),
                              onSecondary: () => _scrollTo('contact'),
                            ),
                          ),
                          _sliverSection(
                            'about',
                            hp,
                            28,
                            _AboutSection(
                              github: _github,
                              dc: dc,
                              lang: widget.lang,
                            ),
                          ),
                          _sliverSection(
                            'skills',
                            hp,
                            28,
                            _SkillsSection(
                              pulse: _pulseCtrl,
                              holiday: _holiday,
                              lang: widget.lang,
                            ),
                          ),
                          _sliverSection(
                            'blog',
                            hp,
                            28,
                            _BlogSection(
                              articles: _articles,
                              generating: _generatingArticle,
                              lang: widget.lang,
                              onGenerate: _generateArticle,
                            ),
                          ),
                          _sliverSection(
                            'projects',
                            hp,
                            28,
                            _ProjectsSection(
                              loading: _loadingGH,
                              github: _github,
                              error: _ghError,
                              lang: widget.lang,
                            ),
                          ),
                          _sliverSection(
                            'contact',
                            hp,
                            dc == DeviceClass.mobile ? 120.0 : 44.0,
                            _ContactSection(dc: dc, lang: widget.lang),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Back to top ──
              if (_showTop)
                Positioned(
                  right: dc == DeviceClass.mobile ? 16 : 24,
                  bottom: dc == DeviceClass.mobile ? 170 : 88,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      alignment: Alignment.bottomRight,
                      child: child,
                    ),
                    child: FloatingActionButton.small(
                      heroTag: 'top',
                      onPressed: () => _scrollCtrl.animateTo(
                        0,
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeInOutCubicEmphasized,
                      ),
                      child: const Icon(Icons.keyboard_arrow_up_rounded),
                    ),
                  ),
                ),
              // ── AI Chat FAB ──
              if (ZhipuAiService.isConfigured)
                Positioned(
                  right: dc == DeviceClass.mobile ? 16 : 24,
                  bottom: dc == DeviceClass.mobile ? 108 : 24,
                  child: FloatingActionButton(
                    heroTag: 'ai',
                    onPressed: () => setState(() => _chatOpen = !_chatOpen),
                    backgroundColor: cs.primaryContainer,
                    child: Icon(
                      _chatOpen ? Icons.close_rounded : Icons.smart_toy_rounded,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              // ── AI Chat Panel ──
              if (_chatOpen && ZhipuAiService.isConfigured)
                Positioned(
                  right: dc == DeviceClass.mobile ? 0 : 24,
                  bottom: dc == DeviceClass.mobile ? 0 : 88,
                  width: dc == DeviceClass.mobile ? constraints.maxWidth : 400,
                  height: dc == DeviceClass.mobile
                      ? constraints.maxHeight * .7
                      : 520,
                  child: _AiChatPanel(
                    messages: _chatMessages,
                    loading: _chatLoading,
                    lang: widget.lang,
                    controller: _chatInputCtrl,
                    onSend: _sendChat,
                    onClose: () => setState(() => _chatOpen = false),
                  ),
                ),
              // ── Mobile nav bar ──
              if (dc == DeviceClass.mobile)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: _MobileNav(
                    sections: _sections,
                    selectedIdx: _selectedIdx,
                    onSelect: (i) => _scrollTo(_sections[i].id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _sliverSection(
    String id,
    double hp,
    double bottom,
    Widget child,
  ) {
    return SliverToBoxAdapter(
      key: _sectionKeys[id],
      child: Padding(
        padding: EdgeInsets.fromLTRB(hp, 0, hp, bottom),
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Top Glass Bar
// ═══════════════════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.weather,
    required this.holiday,
    required this.sections,
    required this.selectedIdx,
    required this.isDesktop,
    required this.isDark,
    required this.lang,
    required this.onSectionTap,
    required this.onToggleTheme,
    required this.onToggleLang,
  });
  final WeatherSnapshot? weather;
  final HolidayTheme holiday;
  final List<NavSection> sections;
  final int selectedIdx;
  final bool isDesktop, isDark;
  final AppLanguage lang;
  final ValueChanged<String> onSectionTap;
  final VoidCallback onToggleTheme, onToggleLang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = S.of(lang);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: .05)
                : Colors.white.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: .08)
                  : Colors.white.withValues(alpha: .45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              // Weather & holiday pills
              Flexible(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Pill(
                      icon: weather?.icon ?? '⛅',
                      label: weather == null
                          ? s.weatherLoading
                          : '${weather!.city} ${weather!.tempText}',
                      accent: cs.primary,
                    ),
                    _Pill(
                      icon: holiday.emoji,
                      label: holiday.shortLabel(s),
                      accent: holiday.accent,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _BrandMark(lang: lang),
              const SizedBox(width: 12),
              if (isDesktop)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 4,
                      children: List.generate(sections.length, (i) {
                        final sec = sections[i];
                        final sel = selectedIdx == i;
                        return _NavChip(
                          label: sec.label,
                          selected: sel,
                          onTap: () => onSectionTap(sec.id),
                        );
                      }),
                    ),
                  ),
                )
              else ...[
                IconButton(
                  onPressed: onToggleLang,
                  icon: Text(
                    s.switchLang,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onToggleTheme,
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  ),
                ),
                _NavMenuButton(sections: sections, onTap: onSectionTap),
              ],
              if (isDesktop) ...[
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onToggleLang,
                  icon: Text(
                    s.switchLang,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  onPressed: onToggleTheme,
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavChip extends StatefulWidget {
  const _NavChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  State<_NavChip> createState() => _NavChipState();
}

class _NavChipState extends State<_NavChip> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        transform: Matrix4.identity()..scale(_hovered ? 1.06 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.selected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.selected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavMenuButton extends StatelessWidget {
  const _NavMenuButton({required this.sections, required this.onTap});
  final List<NavSection> sections;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final sec in sections)
          MenuItemButton(
            leadingIcon: Icon(sec.icon),
            onPressed: () => onTap(sec.id),
            child: Text(sec.label),
          ),
      ],
      builder: (context, ctrl, _) => IconButton.filledTonal(
        onPressed: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
        icon: const Icon(Icons.menu_rounded),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.lang});
  final AppLanguage lang;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(lang);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F7A65), Color(0xFF46C7A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F7A65).withValues(alpha: .22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  top: 8,
                  child: Transform.rotate(
                    angle: -.28,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.travel_explore_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PulseLink',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -.5,
              ),
            ),
            Text(
              s.brandSubtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.accent});
  final String icon, label;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Hero Section
// ═══════════════════════════════════════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.dc,
    required this.pulse,
    required this.holiday,
    required this.weather,
    required this.lang,
    required this.onPrimary,
    required this.onSecondary,
  });
  final DeviceClass dc;
  final Animation<double> pulse;
  final HolidayTheme holiday;
  final WeatherSnapshot? weather;
  final AppLanguage lang;
  final VoidCallback onPrimary, onSecondary;

  @override
  Widget build(BuildContext context) {
    final isDesk = dc == DeviceClass.desktop;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = S.of(lang);
    final greet = greetingForNow(s);

    final textCol = Column(
      crossAxisAlignment:
          isDesk ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        _Reveal(
          delay: 0,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: isDesk ? WrapAlignment.start : WrapAlignment.center,
            children: [
              Chip(
                avatar: Text(greet.emoji),
                label: Text(greet.label),
                backgroundColor: cs.primary.withValues(alpha: .09),
              ),
              Chip(
                avatar: Icon(deviceIcon(dc), size: 16),
                label: Text(s.deviceDetected(dc.label(s))),
                backgroundColor: cs.secondaryContainer.withValues(alpha: .7),
              ),
              Chip(
                avatar: Text(holiday.emoji),
                label: Text(holiday.name(s)),
                backgroundColor: holiday.accent.withValues(alpha: .12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _Reveal(
          delay: 80,
          child: Text(
            s.heroTitle,
            textAlign: isDesk ? TextAlign.left : TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1.6,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Reveal(
          delay: 160,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              s.heroSubtitle,
              textAlign: isDesk ? TextAlign.left : TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _Reveal(
          delay: 240,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: isDesk ? WrapAlignment.start : WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onPrimary,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: Text(s.exploreProjects),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onSecondary,
                icon: const Icon(Icons.waving_hand_rounded),
                label: Text(s.letsConnect),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Reveal(
          delay: 310,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: isDesk ? WrapAlignment.start : WrapAlignment.center,
            children: [
              _Badge(
                label: s.flutterWebOnly,
                icon: Icons.language_rounded,
                accent: cs.primary,
              ),
              _Badge(
                label: s.materialDesign3,
                icon: Icons.layers_rounded,
                accent: cs.tertiary,
              ),
              _Badge(
                label: weather == null ? s.weatherSyncing : weather!.summary(s),
                icon: Icons.cloud_rounded,
                accent: holiday.accent,
              ),
            ],
          ),
        ),
      ],
    );

    final visual = _Reveal(
      delay: 200,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) => _HeroVisual(
          progress: pulse.value,
          holiday: holiday,
          dc: dc,
          lang: lang,
        ),
      ),
    );

    return _Glass(
      child: Padding(
        padding: EdgeInsets.all(isDesk ? 32 : 22),
        child: isDesk
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 6, child: textCol),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: visual),
                ],
              )
            : Column(children: [visual, const SizedBox(height: 24), textCol]),
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({
    required this.progress,
    required this.holiday,
    required this.dc,
    required this.lang,
  });
  final double progress;
  final HolidayTheme holiday;
  final DeviceClass dc;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final s = S.of(lang);
    final size = switch (dc) {
      DeviceClass.mobile => 290.0,
      DeviceClass.tablet => 360.0,
      DeviceClass.desktop => 430.0,
    };
    final cubes = [
      FloatingCubeData(
        icon: Icons.coffee_rounded,
        label: 'Java',
        colorA: const Color(0xFFAA4B12),
        colorB: const Color(0xFFFFA94D),
        alignment: const Alignment(-.88, -.78),
        phase: 0,
      ),
      FloatingCubeData(
        icon: Icons.hive_rounded,
        label: 'Rust',
        colorA: const Color(0xFF8B2E0B),
        colorB: const Color(0xFFFF7A45),
        alignment: const Alignment(.9, -.84),
        phase: .7,
      ),
      FloatingCubeData(
        icon: Icons.blur_on_rounded,
        label: 'Cloud',
        colorA: const Color(0xFF0F7A65),
        colorB: const Color(0xFF4BD7B3),
        alignment: const Alignment(-.92, .32),
        phase: 1.2,
      ),
      FloatingCubeData(
        icon: Icons.smart_toy_rounded,
        label: 'AI',
        colorA: const Color(0xFF6C2DA8),
        colorB: const Color(0xFFD89AFF),
        alignment: const Alignment(.9, .56),
        phase: 1.9,
      ),
    ];
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background glow
          Center(
            child: Container(
              width: size * .72,
              height: size * .72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    holiday.highlight.withValues(alpha: .16),
                    holiday.accent.withValues(alpha: .06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Avatar (rendered before cubes so cubes always stay on top)
          Center(
            child: Transform.translate(
              offset: Offset(0, math.sin(progress * math.pi * 2) * 6),
              child: _AvatarHalo(progress: progress, holiday: holiday),
            ),
          ),
          // Floating cubes (on top of avatar, never hidden behind it)
          for (final c in cubes)
            Align(
              alignment: c.alignment,
              child: Transform.translate(
                offset: Offset(
                  math.sin((progress * math.pi * 2) + c.phase) * 8,
                  math.cos((progress * math.pi * 2) + c.phase) * 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ThreeDCube(
                      icon: c.icon,
                      colorA: c.colorA,
                      colorB: c.colorB,
                      size: size * .16,
                      rotation: progress + c.phase,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarHalo extends StatelessWidget {
  const _AvatarHalo({required this.progress, required this.holiday});
  final double progress;
  final HolidayTheme holiday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sc = 1 + (math.sin(progress * math.pi * 2) * .03);
    return Transform.scale(
      scale: sc,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  holiday.accent.withValues(alpha: .08),
                  cs.primary.withValues(alpha: .24),
                  holiday.highlight.withValues(alpha: .16),
                  cs.secondary.withValues(alpha: .08),
                ],
              ),
            ),
          ),
          Container(
            width: 160,
            height: 160,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: .9),
                  holiday.highlight.withValues(alpha: .4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: holiday.accent.withValues(alpha: .16),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surface,
              ),
              child: ClipOval(
                child: Image.network(
                  'https://avatars.githubusercontent.com/u/56761243?v=4',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primaryContainer,
                          holiday.highlight.withValues(alpha: .9),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'B',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  About Section
// ═══════════════════════════════════════════════════════════════════════════════
class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.github,
    required this.dc,
    required this.lang,
  });
  final GitHubSnapshot? github;
  final DeviceClass dc;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final s = S.of(lang);
    final isDesk = dc == DeviceClass.desktop;
    final m = github ?? GitHubSnapshot.fallback();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(
          eyebrow: s.aboutEyebrow,
          title: s.aboutTitle,
          subtitle: s.aboutSubtitle,
        ),
        const SizedBox(height: 18),
        if (isDesk)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _Glass(
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StoryRow(lang: lang),
                        const SizedBox(height: 16),
                        Text(
                          s.aboutP1,
                          style: const TextStyle(height: 1.7, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.aboutP2,
                          style: const TextStyle(height: 1.7, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: _MetricGrid(metrics: m, lang: lang),
              ),
            ],
          )
        else ...[
          _Glass(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StoryRow(lang: lang),
                  const SizedBox(height: 16),
                  Text(
                    s.aboutP1,
                    style: const TextStyle(height: 1.7, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.aboutP2,
                    style: const TextStyle(height: 1.7, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _MetricGrid(metrics: m, lang: lang),
        ],
      ],
    );
  }
}

class _StoryRow extends StatelessWidget {
  const _StoryRow({required this.lang});
  final AppLanguage lang;
  @override
  Widget build(BuildContext context) {
    final s = S.of(lang);
    return Row(
      children: [
        const ThreeDCube(
          icon: Icons.psychology_alt_rounded,
          colorA: Color(0xFF0F7A65),
          colorB: Color(0xFF5BDEC0),
          size: 56,
          rotation: .16,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            s.storyHeading,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics, required this.lang});
  final GitHubSnapshot metrics;
  final AppLanguage lang;
  @override
  Widget build(BuildContext context) {
    final s = S.of(lang);
    final items = [
      MetricItem(
        s.repositories,
        metrics.publicRepos,
        Icons.folder_copy_rounded,
        const Color(0xFF0F7A65),
        const Color(0xFF55D7B6),
      ),
      MetricItem(
        s.totalStars,
        metrics.totalStars,
        Icons.auto_awesome_rounded,
        const Color(0xFF9B6A00),
        const Color(0xFFFFC65A),
      ),
      MetricItem(
        s.followers,
        metrics.followers,
        Icons.groups_rounded,
        const Color(0xFF1547A8),
        const Color(0xFF6EA5FF),
      ),
      MetricItem(
        s.yearsBuilding,
        6,
        Icons.timelapse_rounded,
        const Color(0xFF7A2EA8),
        const Color(0xFFD99AFF),
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, i) {
        final it = items[i];
        return _SpringHover(
          child: _Glass(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  ThreeDCube(
                    icon: it.icon,
                    colorA: it.colorA,
                    colorB: it.colorB,
                    size: 44,
                    rotation: .3 + i * .12,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AnimNum(
                          value: it.value,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.5,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          it.label,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Skills / Capabilities Section
// ═══════════════════════════════════════════════════════════════════════════════
class _SkillsSection extends StatelessWidget {
  const _SkillsSection({
    required this.pulse,
    required this.holiday,
    required this.lang,
  });
  final Animation<double> pulse;
  final HolidayTheme holiday;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final s = S.of(lang);
    final cards = [
      CapabilityCardData(
        title: s.backendSystems,
        text: s.backendDesc,
        icon: Icons.developer_board_rounded,
        colorA: const Color(0xFF0F7A65),
        colorB: const Color(0xFF5AE0C1),
        chips: s.backendChips,
      ),
      CapabilityCardData(
        title: s.aiLlm,
        text: s.aiLlmDesc,
        icon: Icons.smart_toy_rounded,
        colorA: const Color(0xFF6C2DA8),
        colorB: const Color(0xFFD89AFF),
        chips: s.aiChips,
      ),
      CapabilityCardData(
        title: s.webCraft,
        text: s.webCraftDesc,
        icon: Icons.web_asset_rounded,
        colorA: const Color(0xFF1547A8),
        colorB: const Color(0xFF72A9FF),
        chips: s.webChips,
      ),
      CapabilityCardData(
        title: s.iotEmbedded,
        text: s.iotEmbeddedDesc,
        icon: Icons.memory_rounded,
        colorA: const Color(0xFF166C78),
        colorB: const Color(0xFF74E4F7),
        chips: s.iotChips,
      ),
      CapabilityCardData(
        title: s.cryptoSecurity,
        text: s.cryptoSecurityDesc,
        icon: Icons.enhanced_encryption_rounded,
        colorA: const Color(0xFF82420A),
        colorB: const Color(0xFFFFBA64),
        chips: s.cryptoChips,
      ),
      CapabilityCardData(
        title: s.systemArch,
        text: s.systemArchDesc,
        icon: Icons.hub_rounded,
        colorA: const Color(0xFF8B2E0B),
        colorB: const Color(0xFFFF875D),
        chips: s.archChips,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(
          eyebrow: s.skillsEyebrow,
          title: s.skillsTitle,
          subtitle: s.skillsSubtitle,
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: pulse,
          builder: (context, _) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent:
                    MediaQuery.sizeOf(context).width < 700 ? 520 : 360,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 240,
              ),
              itemBuilder: (context, i) {
                final c = cards[i];
                return _SpringHover(
                  child: _Glass(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Transform.translate(
                                offset: Offset(
                                  math.sin((pulse.value * math.pi * 2) + i) * 3,
                                  0,
                                ),
                                child: ThreeDCube(
                                  icon: c.icon,
                                  colorA: c.colorA,
                                  colorB: c.colorB,
                                  size: 58,
                                  rotation: pulse.value + i * .18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -.3,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      c.text,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            height: 1.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: c.chips
                                .map(
                                  (p) => Chip(
                                    label: Text(p),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Blog Section (AI-powered)
// ═══════════════════════════════════════════════════════════════════════════════
class _BlogSection extends StatelessWidget {
  const _BlogSection({
    required this.articles,
    required this.generating,
    required this.lang,
    required this.onGenerate,
  });
  final List<BlogArticle> articles;
  final bool generating;
  final AppLanguage lang;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final s = S.of(lang);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final configured = ZhipuAiService.isConfigured;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(
          eyebrow: s.blogEyebrow,
          title: s.blogTitle,
          subtitle: s.blogSubtitle,
        ),
        const SizedBox(height: 18),
        if (!configured)
          _Glass(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  ThreeDCube(
                    icon: Icons.key_rounded,
                    colorA: const Color(0xFF9B6A00),
                    colorB: const Color(0xFFFFC65A),
                    size: 52,
                    rotation: .2,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      s.aiNotConfigured,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          if (articles.isEmpty && !generating)
            _Glass(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    ThreeDCube(
                      icon: Icons.auto_awesome_rounded,
                      colorA: const Color(0xFF6C2DA8),
                      colorB: const Color(0xFFD89AFF),
                      size: 52,
                      rotation: .2,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        s.noArticlesYet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (generating)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _Glass(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          s.generating,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          for (final article in articles)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _ArticleCard(article: article, lang: lang),
            ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.tonalIcon(
              onPressed: generating ? null : onGenerate,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(s.generateArticle),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ArticleCard extends StatefulWidget {
  const _ArticleCard({required this.article, required this.lang});
  final BlogArticle article;
  final AppLanguage lang;
  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final s = S.of(widget.lang);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a = widget.article;
    return _SpringHover(
      child: _Glass(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ThreeDCube(
                    icon: Icons.article_rounded,
                    colorA: const Color(0xFF1547A8),
                    colorB: const Color(0xFF72A9FF),
                    size: 48,
                    rotation: .24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                s.articleGenerated,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _fmtDate(a.generatedAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (a.summary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  a.summary,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 350),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  a.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                ),
                secondChild: Text(
                  a.content,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? s.collapse : s.readMore),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  AI Chat Panel
// ═══════════════════════════════════════════════════════════════════════════════
class _AiChatPanel extends StatelessWidget {
  const _AiChatPanel({
    required this.messages,
    required this.loading,
    required this.lang,
    required this.controller,
    required this.onSend,
    required this.onClose,
  });
  final List<ChatMessage> messages;
  final bool loading;
  final AppLanguage lang;
  final TextEditingController controller;
  final VoidCallback onSend, onClose;

  @override
  Widget build(BuildContext context) {
    final s = S.of(lang);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF10211A).withValues(alpha: .95)
                : Colors.white.withValues(alpha: .95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: .10)
                  : cs.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: .3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy_rounded, color: cs.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.aiChatTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              // Messages
              Expanded(
                child: messages.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            s.aiWelcome,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length + (loading ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == messages.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: cs.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    s.generating,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final msg = messages[i];
                          final isUser = msg.role == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 18),
                                ),
                              ),
                              child: SelectableText(
                                msg.content,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                  color: isUser
                                      ? cs.onPrimaryContainer
                                      : cs.onSurface,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Input bar
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: .3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: s.aiChatHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(
                            alpha: .5,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (_) => onSend(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      onPressed: loading ? null : onSend,
                      icon: const Icon(Icons.send_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Projects Section
// ═══════════════════════════════════════════════════════════════════════════════
class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({
    required this.loading,
    required this.github,
    required this.error,
    required this.lang,
  });
  final bool loading;
  final GitHubSnapshot? github;
  final String? error;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final s = S.of(lang);
    final repos = github?.topRepos ?? const <RepoCardData>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(
          eyebrow: s.projectsEyebrow,
          title: s.projectsTitle,
          subtitle: s.projectsSubtitle,
        ),
        const SizedBox(height: 18),
        if (loading)
          _Glass(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      s.loadingRepos,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (repos.isEmpty)
          _Glass(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(error ?? 'Unavailable'),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: repos.length,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent:
                  MediaQuery.sizeOf(context).width < 760 ? 720 : 400,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 260,
            ),
            itemBuilder: (context, i) =>
                _ProjectCard(repo: repos[i], lang: lang),
          ),
        const SizedBox(height: 18),
        Center(
          child: Link(
            uri: Uri.parse('https://github.com/blueokanna'),
            target: LinkTarget.blank,
            builder: (context, follow) => FilledButton.tonalIcon(
              onPressed: follow,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(s.viewGitHub),
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.repo, required this.lang});
  final RepoCardData repo;
  final AppLanguage lang;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(lang);
    return Link(
      uri: Uri.parse(repo.url),
      target: LinkTarget.blank,
      builder: (context, follow) => _SpringHover(
        child: _Glass(
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: follow,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ThreeDCube(
                        icon: repo.icon,
                        colorA: repo.colorA,
                        colorB: repo.colorB,
                        size: 54,
                        rotation: .24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repo.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: repo.colorA.withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                repo.language,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    repo.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _IconLabel(
                        icon: Icons.star_rounded,
                        text: s.stars(repo.stars),
                      ),
                      _IconLabel(
                        icon: Icons.call_split_rounded,
                        text: s.forks(repo.forks),
                      ),
                      _IconLabel(
                        icon: Icons.schedule_rounded,
                        text: repo.updatedLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Contact Section
// ═══════════════════════════════════════════════════════════════════════════════
class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.dc, required this.lang});
  final DeviceClass dc;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final s = S.of(lang);
    final theme = Theme.of(context);
    final cards = [
      ContactCardData(
        title: 'GitHub',
        subtitle: '@blueokanna',
        icon: Icons.code_rounded,
        url: 'https://github.com/blueokanna',
        colorA: const Color(0xFF0F7A65),
        colorB: const Color(0xFF56E1C1),
      ),
      ContactCardData(
        title: 'PulseLink',
        subtitle: 'www.pulselink.top',
        icon: Icons.language_rounded,
        url: 'https://www.pulselink.top',
        colorA: const Color(0xFF1547A8),
        colorB: const Color(0xFF6AA2FF),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(
          eyebrow: s.contactEyebrow,
          title: s.contactTitle,
          subtitle: s.contactSubtitle,
        ),
        const SizedBox(height: 18),
        _Glass(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: dc == DeviceClass.desktop
                      ? WrapAlignment.start
                      : WrapAlignment.center,
                  children: cards.map((c) => _ContactCard(card: c)).toList(),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      s.appTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      s.copyright,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.favorite_rounded, size: 14),
                      label: Text(s.madeWith),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.card});
  final ContactCardData card;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Link(
        uri: Uri.parse(card.url),
        target: LinkTarget.blank,
        builder: (context, follow) => _SpringHover(
          child: _Glass(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: follow,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    ThreeDCube(
                      icon: card.icon,
                      colorA: card.colorA,
                      colorB: card.colorB,
                      size: 50,
                      rotation: .2,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded, size: 18),
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

// ═══════════════════════════════════════════════════════════════════════════════
//  Shared Widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// M3 Expressive glass surface (squircle shape)
class _Glass extends StatelessWidget {
  const _Glass({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isDark
            ? const Color(0xFF10211A).withValues(alpha: .84)
            : Colors.white.withValues(alpha: .72),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: .07)
              : Colors.white.withValues(alpha: .50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Hover scale effect for cards (Wise-style)
class _SpringHover extends StatefulWidget {
  const _SpringHover({required this.child});
  final Widget child;
  @override
  State<_SpringHover> createState() => _SpringHoverState();
}

class _SpringHoverState extends State<_SpringHover> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _hovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          child: widget.child,
        ),
      );
}

/// Delayed reveal with spring overshoot (M3 Expressive motion)
class _Reveal extends StatelessWidget {
  const _Reveal({required this.delay, required this.child});
  final int delay;
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 700 + delay),
        curve: Curves.easeOutBack,
        builder: (_, v, c) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: c),
        ),
        child: child,
      );
}

/// Section header
class _SectionHead extends StatelessWidget {
  const _SectionHead({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  final String eyebrow, title, subtitle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            subtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// 3D Icon Cube
class ThreeDCube extends StatelessWidget {
  const ThreeDCube({
    super.key,
    required this.icon,
    required this.colorA,
    required this.colorB,
    required this.size,
    required this.rotation,
  });
  final IconData icon;
  final Color colorA, colorB;
  final double size, rotation;

  @override
  Widget build(BuildContext context) {
    final d = size * .16;
    return SizedBox(
      width: size + d,
      height: size + d,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom face
          Positioned(
            left: d * .55,
            top: d * .88,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .001)
                ..rotateX(.72)
                ..rotateZ(.06),
              child: Container(
                width: size,
                height: d,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_shade(colorA, -.16), _shade(colorA, -.30)],
                  ),
                  borderRadius: BorderRadius.circular(size * .20),
                ),
              ),
            ),
          ),
          // Right face
          Positioned(
            left: d * .82,
            top: d * .30,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .001)
                ..rotateY(-.76)
                ..rotateZ(-.02),
              child: Container(
                width: d,
                height: size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_shade(colorA, -.12), _shade(colorA, -.28)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(size * .20),
                ),
              ),
            ),
          ),
          // Front face
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .001)
              ..rotateX(.18 + math.sin(rotation * math.pi * 2) * .02)
              ..rotateY(-.22 + math.cos(rotation * math.pi * 2) * .03),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorA, colorB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(size * .26),
                boxShadow: [
                  BoxShadow(
                    color: colorA.withValues(alpha: .22),
                    blurRadius: size * .30,
                    offset: Offset(0, size * .18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size * .26),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: .28),
                            Colors.white.withValues(alpha: 0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(icon, color: Colors.white, size: size * .40),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _shade(Color c, double amt) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amt).clamp(0.0, 1.0)).toColor();
  }
}

/// Trust badge
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, required this.accent});
  final String label;
  final IconData icon;
  final Color accent;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: .16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

/// Icon + label row
class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      );
}

/// Animated number counter
class _AnimNum extends StatelessWidget {
  const _AnimNum({required this.value, this.style});
  final int value;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Text(v.round().toString(), style: style),
      );
}

/// Mobile bottom navigation bar
class _MobileNav extends StatelessWidget {
  const _MobileNav({
    required this.sections,
    required this.selectedIdx,
    required this.onSelect,
  });
  final List<NavSection> sections;
  final int selectedIdx;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: NavigationBar(
            selectedIndex: selectedIdx,
            onDestinationSelected: onSelect,
            destinations: sections
                .map(
                  (s) =>
                      NavigationDestination(icon: Icon(s.icon), label: s.label),
                )
                .toList(),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Ambient Backdrop Painter (no dots — fixes black dot issue)
// ═══════════════════════════════════════════════════════════════════════════════
class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.progress,
    required this.colors,
    required this.brightness,
  });
  final double progress;
  final List<Color> colors;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < colors.length; i++) {
      final x = size.width * (.15 + i * .32) +
          math.sin((progress * math.pi * 2) + i) * 38;
      final y = size.height * (.12 + i * .24) +
          math.cos((progress * math.pi * 2) + i * .8) * 30;
      paint.shader =
          RadialGradient(colors: [colors[i], Colors.transparent]).createShader(
        Rect.fromCircle(center: Offset(x, y), radius: size.width * .28),
      );
      canvas.drawCircle(Offset(x, y), size.width * .28, paint);
    }
    // Removed dot grid to fix black dot artifacts
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) =>
      old.progress != progress || old.brightness != brightness;
}
