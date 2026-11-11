import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../comments.dart';
import '../content.dart';
import '../localization.dart';
import '../motion.dart';
import '../services.dart';
import 'clock_scope.dart';
import 'components.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({
    super.key,
    required this.page,
    required this.strings,
    this.slug,
  });
  final String page;
  final String? slug;
  final BlogStrings strings;
  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _service = RepositoryService();
  Future<List<Repository>>? _repos;
  final _sectionKeys = <int, GlobalKey>{};
  bool _comments = false;
  BlogStrings get s => widget.strings;
  ColorScheme get c => Theme.of(context).colorScheme;
  TextTheme get t => Theme.of(context).textTheme;
  @override
  void initState() {
    super.initState();
    if (widget.page == '/projects') _repos = _service.load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    _service.dispose();
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
    } on PlatformException {
      message = s.text('copyFailed');
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _scroll,
    child: SingleChildScrollView(
      controller: _scroll,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width < 600 ? 20 : 48,
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
                  '/projects/segmeris' => _projectDetail(),
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
                const SizedBox(height: 16),
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
                    Expanded(flex: 5, child: _art(height: 430)),
                  ],
                )
              : Column(children: [heading, _art(height: 300)]);
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
      const SizedBox(height: 36),
      _featured(),
    ],
  );
  Widget _postCards(List<BlogPost> posts) => ResponsiveColumns(
    minWidth: 380,
    children: posts.asMap().entries.map((entry) {
      final post = entry.value;
      return Card.filled(
        color: entry.key.isEven ? c.primaryContainer : c.tertiaryContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => go('/posts/${post.id}'),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.category.toUpperCase(),
                        style: t.labelLarge,
                      ),
                    ),
                    const Icon(Icons.north_east),
                  ],
                ),
                SizedBox(
                  height: 110,
                  child: _art(height: 110, variant: entry.key + 1),
                ),
                const SizedBox(height: 20),
                Text(post.title, style: t.titleLarge),
                const SizedBox(height: 16),
                Text(post.summary),
                const SizedBox(height: 26),
                Text(s.text('read'), style: t.labelLarge),
              ],
            ),
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
          onChanged: (_) => setState(() {}),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: ColoredBox(
            color: c.primaryContainer,
            child: _art(
              height: 240,
              variant: post.id == 'segmeris-guide' ? 1 : 2,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.text('contents'), style: t.titleMedium),
                const SizedBox(height: 8),
                for (var i = 0; i < post.sections.length; i++)
                  TextButton(
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
              ],
            ),
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
                Text(post.sections[i].body, style: t.bodyLarge),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
        Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.text('sourceNote')),
                ExternalLink(
                  url: 'https://github.com/blueokanna/Segmeris#readme',
                  label: 'Segmeris / ${s.text('source')} ↗',
                ),
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

  Widget _featured() => Card.filled(
    color: c.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FLUTTER × RUST', style: t.labelLarge),
          const SizedBox(height: 16),
          Text('Segmeris', style: t.headlineLarge),
          const SizedBox(height: 12),
          Text(s.text('projectSummary'), style: t.bodyLarge),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: () => go('/projects/segmeris'),
            icon: const Icon(Icons.arrow_forward),
            label: Text(s.text('projects')),
          ),
        ],
      ),
    ),
  );
  Widget _projectDetail() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(
        'OPEN SOURCE / FLUTTER × RUST',
        'Segmeris',
        s.text('projectSummary'),
      ),
      _art(height: 280, variant: 2),
      const SizedBox(height: 24),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: SelectionArea(
            child: Text(s.text('projectDetails'), style: t.bodyLarge),
          ),
        ),
      ),
      const SizedBox(height: 28),
      Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          ExternalLink(
            url: 'https://github.com/blueokanna/Segmeris',
            label: s.text('source'),
          ),
          ExternalLink(
            url: 'https://github.com/blueokanna/Segmeris/releases',
            label: s.text('releases'),
          ),
          FilledButton.tonal(
            onPressed: () => go('/posts/segmeris-guide'),
            child: Text(s.text('read')),
          ),
        ],
      ),
    ],
  );
  Widget _projects() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title('OPEN SOURCE', s.text('projects'), s.text('projectIntro')),
      _featured(),
      const SizedBox(height: 36),
      Text(s.text('otherProjects'), style: t.titleLarge),
      const SizedBox(height: 20),
      FutureBuilder<List<Repository>>(
        future: _repos,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return LinearProgressIndicator(semanticsLabel: s.text('loading'));
          }
          if (snapshot.hasError) {
            return Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.text('offlineProjects')),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _repos = _service.load(refresh: true)),
                      icon: const Icon(Icons.refresh),
                      label: Text(s.text('retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          final repos = snapshot.data ?? [];
          return ResponsiveColumns(
            minWidth: 300,
            children: repos
                .where((p) => p.name != 'Segmeris')
                .map(
                  (repo) => Card.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(repo.name, style: t.titleLarge),
                          const SizedBox(height: 12),
                          if (repo.description.isNotEmpty)
                            Text(repo.description),
                          const SizedBox(height: 20),
                          Text('${repo.language} · ☆ ${repo.stars}'),
                          ExternalLink(url: repo.url, label: s.text('source')),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
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
        EmbeddedComments(
          postId: 'guestbook',
          language: s.tag,
          dark: c.brightness == Brightness.dark,
          unavailableLabel: s.text('commentUnavailable'),
          linkLabel: s.text('openDiscussion'),
        ),
    ],
  );
}
