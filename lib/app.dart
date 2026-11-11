import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'localization.dart';
import 'preferences.dart';
import 'motion.dart';
import 'page_metadata.dart';
import 'ui/shell.dart';
import 'ui/pages.dart';

class PulseLinkApp extends StatefulWidget {
  const PulseLinkApp({
    super.key,
    required this.catalog,
    required this.preferences,
    this.initialLocation,
  });
  final BlogCatalog catalog;
  final BlogPreferences preferences;
  final String? initialLocation;
  @override
  State<PulseLinkApp> createState() => _PulseLinkAppState();
}

class _PulseLinkAppState extends State<PulseLinkApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialLocation,
    redirect: (context, state) {
      final parts = state.uri.pathSegments;
      if (parts.isEmpty) return '/zh-CN';
      if (!languages.containsKey(parts.first)) return '/zh-CN';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => BlogShell(
          strings: widget.catalog.translations[state.uri.pathSegments.first]!,
          preferences: widget.preferences,
          child: child,
        ),
        routes: [
          for (final route in [
            '',
            '/posts',
            '/posts/:slug',
            '/projects',
            '/projects/segmeris',
            '/friends',
            '/about',
          ])
            GoRoute(
              path: '/:lang$route',
              pageBuilder: (context, state) {
                final strings =
                    widget.catalog.translations[state.pathParameters['lang']]!;
                return CustomTransitionPage<void>(
                  key: state.pageKey,
                  transitionDuration: widget.preferences.paused
                      ? Duration.zero
                      : Motion.of(context),
                  reverseTransitionDuration: widget.preferences.paused
                      ? Duration.zero
                      : Motion.of(context),
                  child: BlogPage(
                    key: ValueKey(
                      '${strings.tag}:$route:${state.pathParameters['slug']}',
                    ),
                    page: route,
                    slug: state.pathParameters['slug'],
                    strings: strings,
                  ),
                  transitionsBuilder: (context, animation, secondary, child) =>
                      FadeTransition(
                        opacity: animation.drive(
                          CurveTween(curve: Motion.curve),
                        ),
                        child: SlideTransition(
                          position: animation.drive(
                            Tween(
                              begin: const Offset(0, .025),
                              end: Offset.zero,
                            ).chain(CurveTween(curve: Motion.curve)),
                          ),
                          child: child,
                        ),
                      ),
                );
              },
            ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/zh-CN'),
          child: const Text('404 · PulseLink'),
        ),
      ),
    ),
  );
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.preferences,
      _router.routeInformationProvider,
    ]),
    builder: (context, _) {
      final parts = _router.routeInformationProvider.value.uri.pathSegments;
      final lang = parts.isNotEmpty && languages.containsKey(parts.first)
          ? parts.first
          : 'zh-CN';
      final seed = colorPresets[widget.preferences.palette].color;
      final posts = widget.catalog.translations[lang]!.posts;
      final matched = posts.where(
        (post) =>
            parts.length == 3 && parts[1] == 'posts' && parts[2] == post.id,
      );
      updatePageMetadata(
        lang,
        matched.isEmpty
            ? 'Blue · PulseLink'
            : '${matched.first.title} · PulseLink',
      );
      return MaterialApp.router(
        title: 'Blue · PulseLink',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        locale: localeFor(lang),
        supportedLocales: languages.keys.map(localeFor).toList(),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: blogTheme(Brightness.light, seed, lang),
        darkTheme: blogTheme(Brightness.dark, seed, lang),
        themeMode: widget.preferences.mode,
        themeAnimationDuration: widget.preferences.paused
            ? Duration.zero
            : Motion.duration,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                widget.preferences.paused ||
                MediaQuery.disableAnimationsOf(context),
          ),
          child: child!,
        ),
      );
    },
  );
}
