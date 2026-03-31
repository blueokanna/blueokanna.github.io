import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/link.dart';

class PulseLinkApp extends StatefulWidget {
  const PulseLinkApp({super.key});

  @override
  State<PulseLinkApp> createState() => _PulseLinkAppState();
}

class _PulseLinkAppState extends State<PulseLinkApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Blue's PulseLink Blog",
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: PulseLinkHomePage(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final seed = const Color(0xFF0F7A65);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
  );

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF091411)
        : const Color(0xFFF8F4EC),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    cardTheme: CardThemeData(
      color: brightness == Brightness.dark
          ? const Color(0xFF11211B)
          : Colors.white.withValues(alpha: .82),
      shadowColor: Colors.black.withValues(alpha: .08),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStatePropertyAll(
        base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      height: 74,
      backgroundColor: brightness == Brightness.dark
          ? const Color(0xFF102019).withValues(alpha: .92)
          : Colors.white.withValues(alpha: .92),
      indicatorColor: scheme.primaryContainer,
      shadowColor: Colors.black.withValues(alpha: .08),
    ),
  );
}

class PulseLinkHomePage extends StatefulWidget {
  const PulseLinkHomePage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<PulseLinkHomePage> createState() => _PulseLinkHomePageState();
}

class _PulseLinkHomePageState extends State<PulseLinkHomePage>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _pulseController;
  late final ScrollController _scrollController;

  final List<_NavSection> _sections = const [
    _NavSection(id: 'hero', label: 'Home', icon: Icons.home_rounded),
    _NavSection(id: 'about', label: 'About', icon: Icons.person_rounded),
    _NavSection(
      id: 'capabilities',
      label: 'Skills',
      icon: Icons.auto_awesome_rounded,
    ),
    _NavSection(
      id: 'projects',
      label: 'Projects',
      icon: Icons.folder_copy_rounded,
    ),
    _NavSection(id: 'contact', label: 'Contact', icon: Icons.forum_rounded),
  ];

  late final Map<String, GlobalKey> _sectionKeys = {
    for (final section in _sections) section.id: GlobalKey(),
  };

  WeatherSnapshot? _weather;
  GitHubSnapshot? _github;
  bool _loadingGitHub = true;
  int _selectedIndex = 0;
  bool _showBackToTop = false;
  String? _githubError;
  late final HolidayTheme _holiday;

  @override
  void initState() {
    super.initState();
    _holiday = HolidayTheme.forToday(DateTime.now());
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _scrollController = ScrollController()..addListener(_handleScroll);
    _loadWeather();
    _loadGitHub();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _ambientController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final show = _scrollController.offset > 540;
    if (show != _showBackToTop && mounted) {
      setState(() {
        _showBackToTop = show;
      });
    }

    int activeIndex = _selectedIndex;
    for (var index = 0; index < _sections.length; index++) {
      final box = _sectionKeys[_sections[index].id]?.currentContext
          ?.findRenderObject();
      if (box is RenderBox) {
        final top = box.localToGlobal(Offset.zero).dy;
        final bottom = top + box.size.height;
        if (top <= 160 && bottom > 160) {
          activeIndex = index;
          break;
        }
      }
    }

    if (activeIndex != _selectedIndex && mounted) {
      setState(() {
        _selectedIndex = activeIndex;
      });
    }
  }

  Future<void> _scrollTo(String sectionId) async {
    final context = _sectionKeys[sectionId]?.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubicEmphasized,
        alignment: .03,
      );
    }
  }

  Future<void> _loadWeather() async {
    try {
      final geoResponse = await http.get(Uri.parse('https://ipapi.co/json/'));
      final geoMap = jsonDecode(geoResponse.body) as Map<String, dynamic>;
      final lat = (geoMap['latitude'] as num?)?.toDouble() ?? 39.9042;
      final lon = (geoMap['longitude'] as num?)?.toDouble() ?? 116.4074;
      final city = (geoMap['city'] as String?) ?? 'Current city';
      final weatherUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code&timezone=auto',
      );
      final weatherResponse = await http.get(weatherUri);
      final weatherMap =
          jsonDecode(weatherResponse.body) as Map<String, dynamic>;
      final current = weatherMap['current'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _weather = WeatherSnapshot(
          city: city,
          temperatureC: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
          weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _weather = const WeatherSnapshot(
          city: 'PulseLink',
          temperatureC: 26,
          weatherCode: 1,
        );
      });
    }
  }

  Future<void> _loadGitHub() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('https://api.github.com/users/blueokanna')),
        http.get(
          Uri.parse(
            'https://api.github.com/users/blueokanna/repos?per_page=100&sort=updated',
          ),
        ),
        http.get(
          Uri.parse(
            'https://api.github.com/orgs/AstralQuanta/repos?per_page=100&sort=updated',
          ),
        ),
      ]);

      final userMap = jsonDecode(responses[0].body) as Map<String, dynamic>;
      final userReposJson = jsonDecode(responses[1].body) as List<dynamic>;
      final orgReposJson =
          responses[2].statusCode >= 200 && responses[2].statusCode < 300
          ? jsonDecode(responses[2].body) as List<dynamic>
          : <dynamic>[];

      final allRepos = [
        ...userReposJson.cast<Map<String, dynamic>>(),
        ...orgReposJson.cast<Map<String, dynamic>>(),
      ];

      final filtered = allRepos
          .where((repo) => (repo['archived'] as bool? ?? false) == false)
          .toList();
      final totalStars = filtered.fold<int>(
        0,
        (sum, repo) => sum + ((repo['stargazers_count'] as num?)?.toInt() ?? 0),
      );

      filtered.sort((a, b) {
        final starsA = (a['stargazers_count'] as num?)?.toInt() ?? 0;
        final starsB = (b['stargazers_count'] as num?)?.toInt() ?? 0;
        if (starsA != starsB) {
          return starsB.compareTo(starsA);
        }
        final updatedA =
            DateTime.tryParse(a['updated_at'] as String? ?? '') ??
            DateTime(1970);
        final updatedB =
            DateTime.tryParse(b['updated_at'] as String? ?? '') ??
            DateTime(1970);
        return updatedB.compareTo(updatedA);
      });

      final repos = filtered.take(8).map(RepoCardData.fromGitHub).toList();
      if (!mounted) return;
      setState(() {
        _github = GitHubSnapshot(
          publicRepos:
              (userMap['public_repos'] as num?)?.toInt() ?? repos.length,
          followers: (userMap['followers'] as num?)?.toInt() ?? 0,
          totalStars: totalStars,
          topRepos: repos,
        );
        _loadingGitHub = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingGitHub = false;
        _githubError = error.toString();
        _github = GitHubSnapshot.fallback();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceClass = DeviceClass.fromWidth(constraints.maxWidth);
        final horizontalPadding = switch (deviceClass) {
          DeviceClass.mobile => 20.0,
          DeviceClass.tablet => 32.0,
          DeviceClass.desktop => 56.0,
        };

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: AmbientBackdropPainter(
                        progress: _ambientController.value,
                        colors: [
                          colorScheme.primary.withValues(alpha: .10),
                          colorScheme.tertiary.withValues(alpha: .08),
                          _holiday.accent.withValues(alpha: .10),
                        ],
                        holiday: _holiday,
                        brightness: theme.brightness,
                      ),
                    );
                  },
                ),
              ),
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
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        0,
                      ),
                      child: _TopGlassBar(
                        weather: _weather,
                        holiday: _holiday,
                        sections: _sections,
                        selectedIndex: _selectedIndex,
                        isDesktop: deviceClass == DeviceClass.desktop,
                        isDark: widget.themeMode == ThemeMode.dark,
                        onSectionTap: (id) => _scrollTo(id),
                        onToggleTheme: widget.onToggleTheme,
                      ),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            key: _sectionKeys['hero'],
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                28,
                                horizontalPadding,
                                0,
                              ),
                              child: _HeroSection(
                                deviceClass: deviceClass,
                                pulse: _pulseController,
                                holiday: _holiday,
                                weather: _weather,
                                onPrimaryTap: () => _scrollTo('projects'),
                                onSecondaryTap: () => _scrollTo('contact'),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            key: _sectionKeys['about'],
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                32,
                                horizontalPadding,
                                0,
                              ),
                              child: _AboutSection(
                                github: _github,
                                deviceClass: deviceClass,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            key: _sectionKeys['capabilities'],
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                32,
                                horizontalPadding,
                                0,
                              ),
                              child: _CapabilitiesSection(
                                pulse: _pulseController,
                                holiday: _holiday,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            key: _sectionKeys['projects'],
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                32,
                                horizontalPadding,
                                0,
                              ),
                              child: _ProjectsSection(
                                loading: _loadingGitHub,
                                github: _github,
                                error: _githubError,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            key: _sectionKeys['contact'],
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                32,
                                horizontalPadding,
                                deviceClass == DeviceClass.mobile ? 120 : 48,
                              ),
                              child: _ContactSection(deviceClass: deviceClass),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: deviceClass == DeviceClass.mobile ? 20 : 28,
                bottom: deviceClass == DeviceClass.mobile ? 104 : 32,
                child: IgnorePointer(
                  ignoring: !_showBackToTop,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    offset: _showBackToTop ? Offset.zero : const Offset(0, .4),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _showBackToTop ? 1 : 0,
                      child: FloatingActionButton.small(
                        onPressed: () => _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeInOutCubicEmphasized,
                        ),
                        child: const Icon(Icons.keyboard_arrow_up_rounded),
                      ),
                    ),
                  ),
                ),
              ),
              if (deviceClass == DeviceClass.mobile)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _MobileNavigationBar(
                    sections: _sections,
                    selectedIndex: _selectedIndex,
                    onSelect: (index) => _scrollTo(_sections[index].id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TopGlassBar extends StatelessWidget {
  const _TopGlassBar({
    required this.weather,
    required this.holiday,
    required this.sections,
    required this.selectedIndex,
    required this.isDesktop,
    required this.isDark,
    required this.onSectionTap,
    required this.onToggleTheme,
  });

  final WeatherSnapshot? weather;
  final HolidayTheme holiday;
  final List<_NavSection> sections;
  final int selectedIndex;
  final bool isDesktop;
  final bool isDark;
  final ValueChanged<String> onSectionTap;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: .05)
                : Colors.white.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: .08)
                  : Colors.white.withValues(alpha: .45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .06),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              Flexible(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _InfoPill(
                      icon: weather?.icon ?? '⛅',
                      label: weather == null
                          ? 'Weather loading'
                          : '${weather!.city} ${weather!.temperatureText}',
                      accent: colorScheme.primary,
                    ),
                    _InfoPill(
                      icon: holiday.emoji,
                      label: holiday.shortLabel,
                      accent: holiday.accent,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const _BrandWordmark(),
              const SizedBox(width: 16),
              if (isDesktop)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      children: List.generate(sections.length, (index) {
                        final section = sections[index];
                        final selected = selectedIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: selected
                                ? colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => onSectionTap(section.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Text(
                                section.label,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                )
              else ...[
                IconButton.filledTonal(
                  onPressed: onToggleTheme,
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  ),
                ),
                MenuAnchor(
                  menuChildren: [
                    for (final section in sections)
                      MenuItemButton(
                        leadingIcon: Icon(section.icon),
                        onPressed: () => onSectionTap(section.id),
                        child: Text(section.label),
                      ),
                  ],
                  builder: (context, controller, child) {
                    return IconButton.filledTonal(
                      onPressed: () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
                      icon: const Icon(Icons.menu_rounded),
                    );
                  },
                ),
              ],
              if (isDesktop) ...[
                const SizedBox(width: 8),
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

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F7A65).withValues(alpha: .25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              children: [
                Positioned(
                  left: 10,
                  top: 10,
                  child: Transform.rotate(
                    angle: -.28,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.travel_explore_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
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
              'Material 3 x Flutter Web',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final String icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: .20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.deviceClass,
    required this.pulse,
    required this.holiday,
    required this.weather,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
  });

  final DeviceClass deviceClass;
  final Animation<double> pulse;
  final HolidayTheme holiday;
  final WeatherSnapshot? weather;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final isDesktop = deviceClass == DeviceClass.desktop;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeGreeting = _greetingForNow();

    final heroText = Column(
      crossAxisAlignment: isDesktop
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        _DelayedReveal(
          delay: 0,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
            children: [
              Chip(
                avatar: Text(timeGreeting.emoji),
                label: Text(timeGreeting.label),
                backgroundColor: colorScheme.primary.withValues(alpha: .09),
              ),
              Chip(
                avatar: Icon(_deviceIcon(deviceClass), size: 16),
                label: Text('${deviceClass.label} detected'),
                backgroundColor: colorScheme.secondaryContainer.withValues(
                  alpha: .7,
                ),
              ),
              Chip(
                avatar: Text(holiday.emoji),
                label: Text(holiday.name),
                backgroundColor: holiday.accent.withValues(alpha: .12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _DelayedReveal(
          delay: 80,
          child: Text(
            'Blue builds fast, calm and expressive products for the web.',
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1.8,
              height: 1.02,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _DelayedReveal(
          delay: 170,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: Text(
              'A Flutter Web rewrite for Blue\'s personal blog, grounded in Material Design 3, adaptive layouts, kinetic 3D icon systems and the clean confidence that makes Wise feel effortless.',
              textAlign: isDesktop ? TextAlign.left : TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _DelayedReveal(
          delay: 250,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onPrimaryTap,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('Explore Projects'),
              ),
              OutlinedButton.icon(
                onPressed: onSecondaryTap,
                icon: const Icon(Icons.waving_hand_rounded),
                label: const Text('Let\'s Connect'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        _DelayedReveal(
          delay: 320,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
            children: [
              _TrustBadge(
                label: 'Flutter Web only',
                icon: Icons.language_rounded,
                accent: colorScheme.primary,
              ),
              _TrustBadge(
                label: 'Material 3 all the way',
                icon: Icons.layers_rounded,
                accent: colorScheme.tertiary,
              ),
              _TrustBadge(
                label: weather == null ? 'Weather syncing' : weather!.summary,
                icon: Icons.cloud_rounded,
                accent: holiday.accent,
              ),
            ],
          ),
        ),
      ],
    );

    final heroVisual = _DelayedReveal(
      delay: 200,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          return _HeroVisual(
            progress: pulse.value,
            holiday: holiday,
            deviceClass: deviceClass,
          );
        },
      ),
    );

    return _GlassSection(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 36 : 24),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 6, child: heroText),
                  const SizedBox(width: 28),
                  Expanded(flex: 5, child: heroVisual),
                ],
              )
            : Column(
                children: [heroVisual, const SizedBox(height: 28), heroText],
              ),
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({
    required this.progress,
    required this.holiday,
    required this.deviceClass,
  });

  final double progress;
  final HolidayTheme holiday;
  final DeviceClass deviceClass;

  @override
  Widget build(BuildContext context) {
    final size = switch (deviceClass) {
      DeviceClass.mobile => 310.0,
      DeviceClass.tablet => 380.0,
      DeviceClass.desktop => 460.0,
    };

    final cubes = <_FloatingCubeData>[
      _FloatingCubeData(
        icon: Icons.coffee_rounded,
        label: 'Java',
        colorA: const Color(0xFFAA4B12),
        colorB: const Color(0xFFFFA94D),
        alignment: const Alignment(-.88, -.78),
        phase: 0,
      ),
      _FloatingCubeData(
        icon: Icons.hive_rounded,
        label: 'Rust',
        colorA: const Color(0xFF8B2E0B),
        colorB: const Color(0xFFFF7A45),
        alignment: const Alignment(.9, -.84),
        phase: .7,
      ),
      _FloatingCubeData(
        icon: Icons.blur_on_rounded,
        label: 'Cloud',
        colorA: const Color(0xFF0F7A65),
        colorB: const Color(0xFF4BD7B3),
        alignment: const Alignment(-.92, .32),
        phase: 1.2,
      ),
      _FloatingCubeData(
        icon: Icons.security_rounded,
        label: 'Systems',
        colorA: const Color(0xFF1547A8),
        colorB: const Color(0xFF69A3FF),
        alignment: const Alignment(.9, .56),
        phase: 1.9,
      ),
      _FloatingCubeData(
        icon: holiday.icon,
        label: holiday.shortLabel,
        colorA: holiday.accent,
        colorB: holiday.highlight,
        alignment: const Alignment(.08, -.2),
        phase: 2.6,
      ),
    ];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: size * .74,
              height: size * .74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    holiday.highlight.withValues(alpha: .18),
                    holiday.accent.withValues(alpha: .08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          for (final cube in cubes)
            Align(
              alignment: cube.alignment,
              child: Transform.translate(
                offset: Offset(
                  math.sin((progress * math.pi * 2) + cube.phase) * 10,
                  math.cos((progress * math.pi * 2) + cube.phase) * 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ThreeDIconCube(
                      icon: cube.icon,
                      colorA: cube.colorA,
                      colorB: cube.colorB,
                      size: cube == cubes.last ? size * .22 : size * .18,
                      rotation: progress + cube.phase,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cube.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(0, math.sin(progress * math.pi * 2) * 8),
              child: _AvatarHalo(progress: progress, holiday: holiday),
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
    final colorScheme = theme.colorScheme;
    final scale = 1 + (math.sin(progress * math.pi * 2) * .04);

    return Transform.scale(
      scale: scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  holiday.accent.withValues(alpha: .08),
                  colorScheme.primary.withValues(alpha: .28),
                  holiday.highlight.withValues(alpha: .18),
                  colorScheme.secondary.withValues(alpha: .10),
                ],
              ),
            ),
          ),
          Container(
            width: 176,
            height: 176,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: .9),
                  holiday.highlight.withValues(alpha: .45),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: holiday.accent.withValues(alpha: .18),
                  blurRadius: 42,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
              ),
              child: ClipOval(
                child: Image.network(
                  'https://avatars.githubusercontent.com/u/56761243?v=4',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primaryContainer,
                            holiday.highlight.withValues(alpha: .9),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'B',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.github, required this.deviceClass});

  final GitHubSnapshot? github;
  final DeviceClass deviceClass;

  @override
  Widget build(BuildContext context) {
    final isDesktop = deviceClass == DeviceClass.desktop;
    final metrics = github ?? GitHubSnapshot.fallback();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'About',
          title:
              'A personal studio for systems, calm motion and technical depth.',
          subtitle:
              'The site is designed to feel alive without feeling noisy: weather-aware, holiday-aware, device-aware and still reliable on mobile, tablet and desktop.',
        ),
        const SizedBox(height: 20),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _GlassSection(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _StoryHeading(),
                        SizedBox(height: 18),
                        Text(
                          'Blue focuses on backend engineering, open-source tooling and product thinking that respects latency, trust and clarity. The new site treats a personal blog like a polished product surface rather than a demo page.',
                          style: TextStyle(height: 1.7, fontSize: 16),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'That means composable sections, stable animations, Material 3 semantics, responsive behavior tuned for real browser widths, and a tone that feels both technical and human.',
                          style: TextStyle(height: 1.7, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(flex: 5, child: _MetricGrid(metrics: metrics)),
            ],
          )
        else ...[
          _GlassSection(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StoryHeading(),
                  SizedBox(height: 18),
                  Text(
                    'Blue focuses on backend engineering, open-source tooling and product thinking that respects latency, trust and clarity. The new site treats a personal blog like a polished product surface rather than a demo page.',
                    style: TextStyle(height: 1.7, fontSize: 16),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'That means composable sections, stable animations, Material 3 semantics, responsive behavior tuned for real browser widths, and a tone that feels both technical and human.',
                    style: TextStyle(height: 1.7, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _MetricGrid(metrics: metrics),
        ],
      ],
    );
  }
}

class _StoryHeading extends StatelessWidget {
  const _StoryHeading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const ThreeDIconCube(
          icon: Icons.psychology_alt_rounded,
          colorA: Color(0xFF0F7A65),
          colorB: Color(0xFF5BDEC0),
          size: 62,
          rotation: .16,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Psychology-first UI: confidence, rhythm, clear hierarchy.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              letterSpacing: -.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final GitHubSnapshot metrics;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricItem(
        'Repositories',
        metrics.publicRepos,
        Icons.folder_copy_rounded,
        const Color(0xFF0F7A65),
        const Color(0xFF55D7B6),
      ),
      _MetricItem(
        'Total Stars',
        metrics.totalStars,
        Icons.auto_awesome_rounded,
        const Color(0xFF9B6A00),
        const Color(0xFFFFC65A),
      ),
      _MetricItem(
        'Followers',
        metrics.followers,
        Icons.groups_rounded,
        const Color(0xFF1547A8),
        const Color(0xFF6EA5FF),
      ),
      _MetricItem(
        'Years Building',
        6,
        Icons.timelapse_rounded,
        const Color(0xFF7A2EA8),
        const Color(0xFFD99AFF),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _GlassSection(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThreeDIconCube(
                  icon: item.icon,
                  colorA: item.colorA,
                  colorB: item.colorB,
                  size: 58,
                  rotation: .3 + (index * .12),
                ),
                const Spacer(),
                AnimatedNumber(
                  value: item.value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CapabilitiesSection extends StatelessWidget {
  const _CapabilitiesSection({required this.pulse, required this.holiday});

  final Animation<double> pulse;
  final HolidayTheme holiday;

  @override
  Widget build(BuildContext context) {
    final cards = [
      CapabilityCardData(
        title: 'Backend Systems',
        text:
            'Java, Rust, API design, concurrency and careful performance tuning.',
        icon: Icons.developer_board_rounded,
        colorA: const Color(0xFF0F7A65),
        colorB: const Color(0xFF5AE0C1),
        points: const ['Spring Boot', 'Rust services', 'Clean contracts'],
      ),
      CapabilityCardData(
        title: 'Web Craft',
        text:
            'Flutter Web interfaces with stable breakpoints, silky motion and strong hierarchy.',
        icon: Icons.web_asset_rounded,
        colorA: const Color(0xFF1547A8),
        colorB: const Color(0xFF72A9FF),
        points: const ['Material 3', 'Adaptive layout', 'Browser-safe motion'],
      ),
      CapabilityCardData(
        title: 'Product Thinking',
        text:
            'Attention to friction, trust cues, empty states, loading states and readable flows.',
        icon: Icons.psychology_rounded,
        colorA: const Color(0xFF82420A),
        colorB: const Color(0xFFFFBA64),
        points: const ['Microcopy', 'Mood-aware accents', 'Conversion paths'],
      ),
      CapabilityCardData(
        title: holiday.name,
        text:
            'Seasonal visual accents, dynamic header context and festive icon behavior.',
        icon: holiday.icon,
        colorA: holiday.accent,
        colorB: holiday.highlight,
        points: const ['Holiday badge', 'Adaptive particles', 'Mood refresh'],
      ),
      CapabilityCardData(
        title: 'Deployment Ready',
        text:
            'A web-only Flutter source folder plus generated root output for GitHub Pages.',
        icon: Icons.rocket_launch_rounded,
        colorA: const Color(0xFF6C2DA8),
        colorB: const Color(0xFFD89AFF),
        points: const ['Release build', 'Static hosting', 'Clean README flow'],
      ),
      CapabilityCardData(
        title: 'Future Friendly',
        text:
            'Structured enough for future content modules, data cards and richer interactive sections.',
        icon: Icons.extension_rounded,
        colorA: const Color(0xFF8B2E0B),
        colorB: const Color(0xFFFF875D),
        points: const [
          'Composable widgets',
          'Service layer',
          'Scalable sections',
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'Capabilities',
          title: '3D icon language with a real system behind it.',
          subtitle:
              'This is not decorative-only motion. The interface uses depth to signal grouping, priority and delight while remaining usable on smaller devices.',
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: pulse,
          builder: (context, child) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: MediaQuery.sizeOf(context).width < 700
                    ? 520
                    : 380,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                mainAxisExtent: 260,
              ),
              itemBuilder: (context, index) {
                final card = cards[index];
                return _GlassSection(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.translate(
                              offset: Offset(
                                math.sin((pulse.value * math.pi * 2) + index) *
                                    4,
                                0,
                              ),
                              child: ThreeDIconCube(
                                icon: card.icon,
                                colorA: card.colorA,
                                colorB: card.colorB,
                                size: 66,
                                rotation: pulse.value + (index * .18),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -.4,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    card.text,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          height: 1.6,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: card.points.map((point) {
                            return Chip(label: Text(point));
                          }).toList(),
                        ),
                      ],
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

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({
    required this.loading,
    required this.github,
    required this.error,
  });

  final bool loading;
  final GitHubSnapshot? github;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final repos = github?.topRepos ?? const <RepoCardData>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'Projects',
          title:
              'Open-source work, surfaced like products instead of raw links.',
          subtitle:
              'GitHub data is pulled live and presented in cards that remain clear even on narrow screens.',
        ),
        const SizedBox(height: 20),
        if (loading)
          const _LoadingProjects()
        else if (repos.isEmpty)
          _GlassSection(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(error ?? 'Project data is temporarily unavailable.'),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: repos.length,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: MediaQuery.sizeOf(context).width < 760
                  ? 720
                  : 420,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              mainAxisExtent: 260,
            ),
            itemBuilder: (context, index) => ProjectCard(repo: repos[index]),
          ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.center,
          child: Link(
            uri: Uri.parse('https://github.com/blueokanna'),
            target: LinkTarget.blank,
            builder: (context, followLink) {
              return FilledButton.tonalIcon(
                onPressed: followLink,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('View full GitHub profile'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LoadingProjects extends StatelessWidget {
  const _LoadingProjects();

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.8),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Loading repositories from GitHub…',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.deviceClass});

  final DeviceClass deviceClass;

  @override
  Widget build(BuildContext context) {
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
      ContactCardData(
        title: 'Blueokanna',
        subtitle: 'blueokanna.gay',
        icon: Icons.travel_explore_rounded,
        url: 'https://blueokanna.gay',
        colorA: const Color(0xFF8B2E0B),
        colorB: const Color(0xFFFF9169),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'Contact',
          title:
              'Built to feel like a complete personal product, not a placeholder.',
          subtitle:
              'The final section keeps the energy up with strong calls-to-action and enough breathing room to end the page cleanly on every screen size.',
        ),
        const SizedBox(height: 20),
        _GlassSection(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: deviceClass == DeviceClass.desktop
                      ? WrapAlignment.start
                      : WrapAlignment.center,
                  children: cards
                      .map((card) => ContactCard(card: card))
                      .toList(),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Blue\'s PulseLink Blog',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '2023–2026',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.favorite_rounded, size: 16),
                      label: const Text('Made with Flutter Web + MD3'),
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

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.repo});

  final RepoCardData repo;

  @override
  Widget build(BuildContext context) {
    return Link(
      uri: Uri.parse(repo.url),
      target: LinkTarget.blank,
      builder: (context, followLink) {
        return _GlassSection(
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: followLink,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ThreeDIconCube(
                        icon: repo.icon,
                        colorA: repo.colorA,
                        colorB: repo.colorB,
                        size: 62,
                        rotation: .24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repo.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.4,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: repo.colorA.withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                repo.language,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    repo.description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.65,
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 14,
                    runSpacing: 10,
                    children: [
                      _MetricText(
                        icon: Icons.star_rounded,
                        text: '${repo.stars} stars',
                      ),
                      _MetricText(
                        icon: Icons.call_split_rounded,
                        text: '${repo.forks} forks',
                      ),
                      _MetricText(
                        icon: Icons.schedule_rounded,
                        text: repo.updatedLabel,
                      ),
                    ],
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

class ContactCard extends StatelessWidget {
  const ContactCard({super.key, required this.card});

  final ContactCardData card;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Link(
        uri: Uri.parse(card.url),
        target: LinkTarget.blank,
        builder: (context, followLink) {
          return _GlassSection(
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: followLink,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    ThreeDIconCube(
                      icon: card.icon,
                      colorA: card.colorA,
                      colorB: card.colorB,
                      size: 58,
                      rotation: .2,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            card.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MobileNavigationBar extends StatelessWidget {
  const _MobileNavigationBar({
    required this.sections,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_NavSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelect,
          destinations: sections
              .map(
                (section) => NavigationDestination(
                  icon: Icon(section.icon),
                  label: section.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

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
            letterSpacing: 1.5,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -.9,
            height: 1.06,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
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

class _GlassSection extends StatelessWidget {
  const _GlassSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF10211A).withValues(alpha: .86)
            : Colors.white.withValues(alpha: .72),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: .08)
              : Colors.white.withValues(alpha: .55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DelayedReveal extends StatelessWidget {
  const _DelayedReveal({required this.delay, required this.child});

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 650 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 26),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class ThreeDIconCube extends StatelessWidget {
  const ThreeDIconCube({
    super.key,
    required this.icon,
    required this.colorA,
    required this.colorB,
    required this.size,
    required this.rotation,
  });

  final IconData icon;
  final Color colorA;
  final Color colorB;
  final double size;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    final depth = size * .18;
    return SizedBox(
      width: size + depth,
      height: size + depth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: depth * .55,
            top: depth * .88,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .001)
                ..rotateX(.72)
                ..rotateZ(.06),
              child: Container(
                width: size,
                height: depth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_shade(colorA, -.16), _shade(colorA, -.30)],
                  ),
                  borderRadius: BorderRadius.circular(size * .22),
                ),
              ),
            ),
          ),
          Positioned(
            left: depth * .82,
            top: depth * .30,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .001)
                ..rotateY(-.76)
                ..rotateZ(-.02),
              child: Container(
                width: depth,
                height: size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_shade(colorA, -.12), _shade(colorA, -.28)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(size * .22),
                ),
              ),
            ),
          ),
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
                borderRadius: BorderRadius.circular(size * .28),
                boxShadow: [
                  BoxShadow(
                    color: colorA.withValues(alpha: .24),
                    blurRadius: size * .34,
                    offset: Offset(0, size * .20),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size * .28),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: .30),
                            Colors.white.withValues(alpha: 0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(icon, color: Colors.white, size: size * .42),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _shade(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

class AmbientBackdropPainter extends CustomPainter {
  AmbientBackdropPainter({
    required this.progress,
    required this.colors,
    required this.holiday,
    required this.brightness,
  });

  final double progress;
  final List<Color> colors;
  final HolidayTheme holiday;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final base = brightness == Brightness.dark ? 0.09 : 0.12;

    for (var index = 0; index < colors.length; index++) {
      final x =
          size.width * (.15 + index * .32) +
          math.sin((progress * math.pi * 2) + index) * 42;
      final y =
          size.height * (.12 + index * .24) +
          math.cos((progress * math.pi * 2) + (index * .8)) * 34;
      paint.shader = RadialGradient(colors: [colors[index], Colors.transparent])
          .createShader(
            Rect.fromCircle(center: Offset(x, y), radius: size.width * .26),
          );
      canvas.drawCircle(Offset(x, y), size.width * .26, paint);
    }

    final dotPaint = Paint()
      ..color = holiday.accent.withValues(alpha: base)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 42; i++) {
      final dx =
          (size.width / 42) * i + math.sin((progress * math.pi * 2) + i) * 12;
      final dy =
          (size.height / 7) * ((i % 7) + .5) +
          math.cos((progress * math.pi * 2) + (i * .2)) * 9;
      canvas.drawCircle(Offset(dx, dy), (i % 3) + 1.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AmbientBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.brightness != brightness ||
        oldDelegate.holiday != holiday;
  }
}

class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({super.key, required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(animatedValue.round().toString(), style: style);
      },
    );
  }
}

class _GreetingData {
  const _GreetingData(this.label, this.emoji);

  final String label;
  final String emoji;
}

_GreetingData _greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 6) return const _GreetingData('Still shipping late', '🌙');
  if (hour < 12) return const _GreetingData('Good morning', '☀️');
  if (hour < 18) return const _GreetingData('Good afternoon', '🌤️');
  return const _GreetingData('Good evening', '🌆');
}

IconData _deviceIcon(DeviceClass deviceClass) {
  switch (deviceClass) {
    case DeviceClass.mobile:
      return Icons.smartphone_rounded;
    case DeviceClass.tablet:
      return Icons.tablet_mac_rounded;
    case DeviceClass.desktop:
      return Icons.desktop_windows_rounded;
  }
}

enum DeviceClass {
  mobile('Mobile'),
  tablet('Tablet'),
  desktop('Desktop');

  const DeviceClass(this.label);

  final String label;

  static DeviceClass fromWidth(double width) {
    if (width < 700) return DeviceClass.mobile;
    if (width < 1100) return DeviceClass.tablet;
    return DeviceClass.desktop;
  }
}

class _NavSection {
  const _NavSection({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.city,
    required this.temperatureC,
    required this.weatherCode,
  });

  final String city;
  final double temperatureC;
  final int weatherCode;

  String get icon {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 2) return '🌤️';
    if (weatherCode <= 3) return '☁️';
    if (weatherCode >= 45 && weatherCode <= 48) return '🌫️';
    if (weatherCode >= 51 && weatherCode <= 67) return '🌧️';
    if (weatherCode >= 71 && weatherCode <= 77) return '🌨️';
    if (weatherCode >= 80 && weatherCode <= 82) return '🌦️';
    if (weatherCode >= 95) return '⛈️';
    return '⛅';
  }

  String get temperatureText => '${temperatureC.round()}°C';

  String get summary => '$icon $temperatureText in $city';
}

class HolidayTheme {
  const HolidayTheme({
    required this.name,
    required this.shortLabel,
    required this.emoji,
    required this.icon,
    required this.accent,
    required this.highlight,
  });

  final String name;
  final String shortLabel;
  final String emoji;
  final IconData icon;
  final Color accent;
  final Color highlight;

  static HolidayTheme forToday(DateTime now) {
    final month = now.month;
    final day = now.day;
    if (month == 12 && day >= 20) {
      return const HolidayTheme(
        name: 'Christmas Season',
        shortLabel: 'Holiday glow',
        emoji: '🎄',
        icon: Icons.ac_unit_rounded,
        accent: Color(0xFF0F7A65),
        highlight: Color(0xFF72E9C6),
      );
    }
    if (month == 10 && day >= 25) {
      return const HolidayTheme(
        name: 'Halloween Mood',
        shortLabel: 'Spooky mode',
        emoji: '🎃',
        icon: Icons.nightlight_round,
        accent: Color(0xFF8B2E0B),
        highlight: Color(0xFFFF9B61),
      );
    }
    if (month == 2 && day >= 10 && day <= 17) {
      return const HolidayTheme(
        name: 'Valentine Pulse',
        shortLabel: 'Heart sync',
        emoji: '💌',
        icon: Icons.favorite_rounded,
        accent: Color(0xFFB4255E),
        highlight: Color(0xFFFF8AB3),
      );
    }
    if (month == 1 || month == 2) {
      return const HolidayTheme(
        name: 'Spring Festival',
        shortLabel: 'Spring glow',
        emoji: '🧧',
        icon: Icons.auto_awesome_rounded,
        accent: Color(0xFFC3411A),
        highlight: Color(0xFFFFBF6C),
      );
    }
    if (month == 9) {
      return const HolidayTheme(
        name: 'Mid-Autumn Mode',
        shortLabel: 'Moonlight',
        emoji: '🥮',
        icon: Icons.brightness_2_rounded,
        accent: Color(0xFF7757D8),
        highlight: Color(0xFFE0C7FF),
      );
    }
    return const HolidayTheme(
      name: 'Spring Tone',
      shortLabel: 'Seasonal accent',
      emoji: '🌿',
      icon: Icons.eco_rounded,
      accent: Color(0xFF0F7A65),
      highlight: Color(0xFF72E9C6),
    );
  }
}

class GitHubSnapshot {
  const GitHubSnapshot({
    required this.publicRepos,
    required this.followers,
    required this.totalStars,
    required this.topRepos,
  });

  final int publicRepos;
  final int followers;
  final int totalStars;
  final List<RepoCardData> topRepos;

  factory GitHubSnapshot.fallback() {
    return GitHubSnapshot(
      publicRepos: 26,
      followers: 16,
      totalStars: 97,
      topRepos: const [
        RepoCardData(
          name: 'VeloGuard',
          description:
              'Cross-platform proxy client with Flutter UI and a high-performance Rust core.',
          url: 'https://github.com/blueokanna/VeloGuard',
          language: 'Rust',
          stars: 8,
          forks: 0,
          icon: Icons.shield_rounded,
          colorA: Color(0xFF8B2E0B),
          colorB: Color(0xFFFF875D),
          updatedLabel: 'Updated recently',
        ),
      ],
    );
  }
}

class RepoCardData {
  const RepoCardData({
    required this.name,
    required this.description,
    required this.url,
    required this.language,
    required this.stars,
    required this.forks,
    required this.icon,
    required this.colorA,
    required this.colorB,
    required this.updatedLabel,
  });

  final String name;
  final String description;
  final String url;
  final String language;
  final int stars;
  final int forks;
  final IconData icon;
  final Color colorA;
  final Color colorB;
  final String updatedLabel;

  factory RepoCardData.fromGitHub(Map<String, dynamic> repo) {
    final language = (repo['language'] as String?) ?? 'Code';
    final palette = _paletteForLanguage(language);
    final updatedAt = DateTime.tryParse(repo['updated_at'] as String? ?? '');
    return RepoCardData(
      name: repo['name'] as String? ?? 'Repository',
      description: repo['description'] as String? ?? 'No description provided.',
      url: repo['html_url'] as String? ?? 'https://github.com/blueokanna',
      language: language,
      stars: (repo['stargazers_count'] as num?)?.toInt() ?? 0,
      forks: (repo['forks_count'] as num?)?.toInt() ?? 0,
      icon: palette.icon,
      colorA: palette.colorA,
      colorB: palette.colorB,
      updatedLabel: updatedAt == null ? 'Fresh' : _updatedLabel(updatedAt),
    );
  }

  static _Palette _paletteForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'java':
        return const _Palette(
          Icons.coffee_rounded,
          Color(0xFFAA4B12),
          Color(0xFFFFB055),
        );
      case 'rust':
        return const _Palette(
          Icons.hive_rounded,
          Color(0xFF8B2E0B),
          Color(0xFFFF875D),
        );
      case 'dart':
        return const _Palette(
          Icons.flutter_dash_rounded,
          Color(0xFF1368B5),
          Color(0xFF79C6FF),
        );
      case 'kotlin':
        return const _Palette(
          Icons.auto_fix_high_rounded,
          Color(0xFF6C2DA8),
          Color(0xFFD89AFF),
        );
      case 'javascript':
        return const _Palette(
          Icons.bolt_rounded,
          Color(0xFF9B6A00),
          Color(0xFFFFD44D),
        );
      case 'c++':
      case 'c':
        return const _Palette(
          Icons.memory_rounded,
          Color(0xFF1547A8),
          Color(0xFF70A7FF),
        );
      case 'python':
        return const _Palette(
          Icons.data_object_rounded,
          Color(0xFF166C78),
          Color(0xFF74E4F7),
        );
      case 'css':
      case 'html':
        return const _Palette(
          Icons.web_asset_rounded,
          Color(0xFF0F7A65),
          Color(0xFF60E5C7),
        );
      default:
        return const _Palette(
          Icons.widgets_rounded,
          Color(0xFF0F7A65),
          Color(0xFF56E1C1),
        );
    }
  }

  static String _updatedLabel(DateTime updatedAt) {
    final diff = DateTime.now().difference(updatedAt).inDays;
    if (diff <= 1) return 'Updated today';
    if (diff < 7) return '$diff days ago';
    final weeks = (diff / 7).floor();
    if (weeks < 5) return '$weeks weeks ago';
    final months = (diff / 30).floor();
    return '$months months ago';
  }
}

class _Palette {
  const _Palette(this.icon, this.colorA, this.colorB);

  final IconData icon;
  final Color colorA;
  final Color colorB;
}

class CapabilityCardData {
  const CapabilityCardData({
    required this.title,
    required this.text,
    required this.icon,
    required this.colorA,
    required this.colorB,
    required this.points,
  });

  final String title;
  final String text;
  final IconData icon;
  final Color colorA;
  final Color colorB;
  final List<String> points;
}

class ContactCardData {
  const ContactCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.url,
    required this.colorA,
    required this.colorB,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String url;
  final Color colorA;
  final Color colorB;
}

class _MetricItem {
  const _MetricItem(
    this.label,
    this.value,
    this.icon,
    this.colorA,
    this.colorB,
  );

  final String label;
  final int value;
  final IconData icon;
  final Color colorA;
  final Color colorB;
}

class _FloatingCubeData {
  const _FloatingCubeData({
    required this.icon,
    required this.label,
    required this.colorA,
    required this.colorB,
    required this.alignment,
    required this.phase,
  });

  final IconData icon;
  final String label;
  final Color colorA;
  final Color colorB;
  final Alignment alignment;
  final double phase;
}
