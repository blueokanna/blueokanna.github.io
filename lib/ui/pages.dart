import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../comments.dart';
import '../companion.dart';
import '../content.dart';
import '../localization.dart';
import '../motion.dart';
import '../models/project.dart';
import 'expressive.dart';
import 'mascot.dart';
import 'project_views.dart';
import 'rich_content.dart';
import 'clock_scope.dart';
import 'components.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({
    super.key,
    required this.page,
    required this.strings,
    required this.projects,
    this.slug,
  });
  final List<ProjectEntry> projects;
  final String page;
  final String? slug;
  final BlogStrings strings;
  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _sectionKeys = <int, GlobalKey>{};
  bool _comments = false;
  bool _finishedReading = false;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_readingProgress);
  }

  void _readingProgress() {
    if (_finishedReading ||
        widget.page != '/posts/:slug' ||
        !_scroll.hasClients ||
        _scroll.position.maxScrollExtent <= 0) {
      return;
    }
    if (_scroll.offset / _scroll.position.maxScrollExtent >= .92) {
      _finishedReading = true;
      CompanionScope.read(context)?.react(CompanionMood.finished, priority: 2);
    }
  }

  BlogStrings get s => widget.strings;
  ColorScheme get c => Theme.of(context).colorScheme;
  TextTheme get t => Theme.of(context).textTheme;
  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void go(String suffix) => context.go('/${s.tag}$suffix');
  Future<void> _copy() async {
    final url = Uri.base
        .replace(fragment: '/${s.tag}/posts/${widget.slug}')
        .toString();
    String message = s.text('copied');
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) CompanionScope.read(context)?.react(CompanionMood.celebrate);
    } on PlatformException {
      message = s.text('copyFailed');
      if (mounted) {
        CompanionScope.read(context)?.react(CompanionMood.error, priority: 3);
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (widget.page == '/posts/:slug')
        AnimatedBuilder(
          animation: _scroll,
          builder: (context, _) {
            final value =
                !_scroll.hasClients || _scroll.position.maxScrollExtent <= 0
                ? 0.0
                : (_scroll.offset / _scroll.position.maxScrollExtent).clamp(
                    0.0,
                    1.0,
                  );
            return LinearProgressIndicator(
              value: value,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              semanticsLabel: s.text('readingProgress'),
            );
          },
        ),
      Expanded(child: _scrollingContent(context)),
    ],
  );

  Widget _scrollingContent(BuildContext context) => Scrollbar(
    controller: _scroll,
    child: SingleChildScrollView(
      controller: _scroll,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: LayoutSpace.gutter(MediaQuery.sizeOf(context).width),
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                switch (widget.page) {
                  '' => _home(),
                  '/posts' => _posts(),
                  '/posts/:slug' => _article(),
                  '/projects' => _projects(),
                  '/projects/:slug' => _projectDetail(),
                  '/friends' => _friends(),
                  _ => _about(),
                },
                const SizedBox(height: 72),
                const Divider(),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 20,
                  runSpacing: 12,
                  children: [
                    Text('© ${DateTime.now().year} Blue · PulseLink'),
                    Text(s.text('footer'), style: t.bodySmall),
                  ],
                ),
                SizedBox(
                  height:
                      widget.page.isEmpty ||
                          MediaQuery.sizeOf(context).width < 600
                      ? 16
                      : 120,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _title(String label, String title, String description) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: t.labelLarge?.copyWith(color: c.primary, letterSpacing: 2),
      ),
      const SizedBox(height: 18),
      Text(title, style: t.headlineLarge),
      const SizedBox(height: 16),
      Text(description, style: t.bodyLarge),
      const SizedBox(height: 32),
    ],
  );
  Widget _art({double height = 350, int variant = 0}) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: AuroraArt(
            MotionClock.of(context),
            dark: c.brightness == Brightness.dark,
            hero: true,
            seed: c.primary,
            variant: variant,
          ),
        ),
      ),
    ),
  );
  Widget _home() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(
        builder: (context, box) {
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.text('heroLabel'),
                style: t.labelLarge?.copyWith(
                  letterSpacing: 2,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                s.text('heroTitle'),
                style: t.displayLarge?.copyWith(
                  fontSize: box.maxWidth > 800 ? 58 : 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(s.text('heroBody'), style: t.bodyLarge),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => go('/posts'),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(s.text('allPosts')),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => go('/projects'),
                    icon: const Icon(Icons.code),
                    label: Text(s.text('projects')),
                  ),
                ],
              ),
            ],
          );
          return box.maxWidth > 800
              ? Row(
                  children: [
                    Expanded(flex: 6, child: heading),
                    Expanded(flex: 5, child: CompanionStage(language: s.tag)),
                  ],
                )
              : Column(
                  children: [
                    heading,
                    const SizedBox(height: 32),
                    CompanionStage(language: s.tag),
                  ],
                );
        },
      ),
      const SizedBox(height: 56),
      const Divider(),
      const SizedBox(height: 40),
      Row(
        children: [
          Expanded(child: Text(s.text('latest'), style: t.headlineLarge)),
          IconButton.filledTonal(
            tooltip: s.text('allPosts'),
            onPressed: () => go('/posts'),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
      const SizedBox(height: 24),
      _postCards(s.posts),
      const SizedBox(height: LayoutSpace.section),
      Row(
        children: [
          Expanded(child: Text(s.text('projects'), style: t.headlineLarge)),
          IconButton.filledTonal(
            tooltip: s.text('projects'),
            onPressed: () => go('/projects'),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(s.text('projectIntro'), style: t.bodyLarge),
      const SizedBox(height: 28),
      ProjectCollection(projects: widget.projects, strings: s, compact: true),
    ],
  );
  Widget _postCards(List<BlogPost> posts) => ResponsiveColumns(
    minWidth: 420,
    children: posts.asMap().entries.map((entry) {
      final post = entry.value;
      return ExpressiveCard(
        variant: entry.key,
        onTap: () => go('/posts/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShapeEmblem(
                    variant: entry.key + 1,
                    icon: entry.key.isEven
                        ? Icons.play_circle_outline
                        : Icons.layers_outlined,
                    size: 80,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      post.category.toUpperCase(),
                      style: t.labelLarge?.copyWith(color: c.primary),
                    ),
                  ),
                  const Icon(Icons.north_east),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                post.title,
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              Text(post.summary, style: t.bodyMedium),
              const SizedBox(height: 32),
              const Spacer(),
              Row(
                children: [
                  Text(
                    s.text('read'),
                    style: t.labelLarge?.copyWith(color: c.primary),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: c.primary),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
  Widget _posts() {
    final q = _search.text.trim().toLowerCase();
    final posts = s.posts
        .where(
          (p) =>
              '${p.title} ${p.summary} ${p.category}'.toLowerCase().contains(q),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('JOURNAL', s.text('posts'), s.text('postsIntro')),
        SearchBar(
          controller: _search,
          hintText: s.text('search'),
          leading: const Icon(Icons.search),
          onChanged: (value) {
            setState(() {});
            final query = value.trim().toLowerCase();
            if (query.isEmpty) {
              CompanionScope.read(context)?.reset();
              return;
            }
            final found = s.posts.any(
              (p) => '${p.title} ${p.summary} ${p.category}'
                  .toLowerCase()
                  .contains(query),
            );
            CompanionScope.read(context)?.react(
              found ? CompanionMood.search : CompanionMood.empty,
              duration: null,
            );
          },
        ),
        const SizedBox(height: 28),
        if (posts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(s.text('noResults')),
          )
        else
          _postCards(posts),
      ],
    );
  }

  Widget _article() {
    final matches = s.posts.where((p) => p.id == widget.slug);
    if (matches.isEmpty) return _title('404', s.text('notFound'), '');
    final post = matches.single;
    final article = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: () => go('/posts'),
          icon: const Icon(Icons.arrow_back),
          label: Text(s.text('back')),
        ),
        const SizedBox(height: 20),
        _title(post.category.toUpperCase(), post.title, post.summary),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            const Chip(
              avatar: Icon(Icons.person_outline, size: 18),
              label: Text('Blue'),
            ),
            ActionChip(
              avatar: const Icon(Icons.link, size: 18),
              label: Text(s.text('copyLink')),
              onPressed: _copy,
            ),
          ],
        ),
        const SizedBox(height: 30),
        Card.outlined(
          child: ExpansionTile(
            initiallyExpanded: MediaQuery.sizeOf(context).width >= 800,
            title: Text(s.text('contents'), style: t.titleMedium),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: [
              for (var i = 0; i < post.sections.length; i++)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      final ctx = _sectionKeys[i]?.currentContext;
                      if (ctx != null) {
                        Scrollable.ensureVisible(
                          ctx,
                          duration: Motion.of(context),
                          curve: Motion.curve,
                        );
                      }
                    },
                    child: Text('${i + 1}. ${post.sections[i].heading}'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < post.sections.length; i++) ...[
                Text(
                  post.sections[i].heading,
                  key: _sectionKeys.putIfAbsent(i, () => GlobalKey()),
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                RichContent(data: post.sections[i].body),
                if (post.sections[i].diagram case final String diagram)
                  DiagramFigure(
                    id: diagram,
                    language: s.tag,
                    caption: post.sections[i].heading,
                    expandLabel: s.text('expandDiagram'),
                  ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
        if (post.sources.isNotEmpty)
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.text('references'), style: t.titleMedium),
                  const SizedBox(height: 12),
                  Text(s.text('sourceNote')),
                  for (final source in post.sources)
                    ExternalLink(url: source.url, label: source.label),
                ],
              ),
            ),
          ),
        const SizedBox(height: 40),
        Text(s.text('discussion'), style: t.headlineMedium),
        const SizedBox(height: 12),
        Text(s.text('commentIntro')),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => setState(() => _comments = !_comments),
              icon: const Icon(Icons.forum_outlined),
              label: Text(_comments ? s.text('close') : s.text('loadComments')),
            ),
            ExternalLink(
              url: 'https://github.com/blueokanna/blueokanna.github.io/discussions',
              label: s.text('openDiscussion'),
            ),
          ],
        ),
        if (_comments)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: EmbeddedComments(
              postId: post.id,
              unavailableLabel: s.text('commentUnavailable'),
              linkLabel: s.text('openDiscussion'),
              language: s.tag,
              dark: c.brightness == Brightness.dark,
            ),
          ),
        const SizedBox(height: 40),
        Text(s.text('related'), style: t.titleLarge),
        const SizedBox(height: 16),
        for (final other in s.posts.where((p) => p.id != post.id))
          Card.outlined(
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              title: Text(other.title),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => go('/posts/${other.id}'),
            ),
          ),
      ],
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: article,
      ),
    );
  }

  Widget _projectDetail() {
    final matches = widget.projects.where(
      (project) => project.id == widget.slug,
    );
    if (matches.isEmpty) return _title('404', s.text('notFound'), '');
    return ProjectDetail(project: matches.single, strings: s);
  }

  Widget _projects() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title('OPEN SOURCE', s.text('projects'), s.text('projectIntro')),
      const SizedBox(height: 16),
      ProjectCollection(projects: widget.projects, strings: s),
      const SizedBox(height: 40),
      const Align(
        alignment: Alignment.centerLeft,
        child: ExternalLink(
          url: 'https://github.com/blueokanna?tab=repositories',
          label: 'GitHub ↗',
        ),
      ),
    ],
  );
  Widget _friends() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title('BLOGROLL', s.text('friends'), s.text('friendsIntro')),
      ResponsiveColumns(
        minWidth: 350,
        children: friends.asMap().entries.map((entry) {
          final friend = entry.value;
          return Card.filled(
            color: entry.key.isEven
                ? c.secondaryContainer
                : c.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: friend.avatar == null
                        ? const Icon(Icons.grain, size: 30)
                        : Padding(
                            padding: const EdgeInsets.all(10),
                            child: SvgPicture.network(
                              friend.avatar!,
                              placeholderBuilder: (_) => const Icon(Icons.spa),
                              errorBuilder: (_, error, stack) =>
                                  const Icon(Icons.spa),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    friend.name,
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(s.text(entry.key == 0 ? 'friendLxns' : 'friendTaoran')),
                  const SizedBox(height: 18),
                  ExternalLink(
                    url: friend.url,
                    label: '${Uri.parse(friend.url).host} ↗',
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
  Widget _about() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title('BLUE / PULSELINK', s.text('about'), s.text('aboutBody')),
      _art(height: 300),
      const SizedBox(height: 24),
      const ExternalLink(
        url: 'https://github.com/blueokanna',
        label: 'GitHub / blueokanna',
      ),
      const ExternalLink(
        url: 'https://github.com/blueokanna/blueokanna.github.io',
        label: 'PulseLink / GitHub',
      ),
      const SizedBox(height: 32),
      Text(s.text('discussion'), style: t.headlineMedium),
      const SizedBox(height: 12),
      Text(s.text('commentIntro')),
      const SizedBox(height: 16),
      FilledButton.tonalIcon(
        onPressed: () => setState(() => _comments = !_comments),
        icon: const Icon(Icons.forum_outlined),
        label: Text(_comments ? s.text('close') : s.text('loadComments')),
      ),
      if (_comments)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: EmbeddedComments(
            postId: 'guestbook',
            language: s.tag,
            dark: c.brightness == Brightness.dark,
            unavailableLabel: s.text('commentUnavailable'),
            linkLabel: s.text('openDiscussion'),
          ),
        ),
    ],
  );
}
