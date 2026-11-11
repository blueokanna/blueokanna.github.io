import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization.dart';
import '../preferences.dart';
import '../motion.dart';
import 'clock_scope.dart';

class BlogShell extends StatelessWidget {
  const BlogShell({
    super.key,
    required this.strings,
    required this.preferences,
    required this.child,
  });
  final BlogStrings strings;
  final BlogPreferences preferences;
  final Widget child;
  void _appearance(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => ListenableBuilder(
      listenable: preferences,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.text('appearance'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ThemeMode.values
                  .map(
                    (mode) => ChoiceChip(
                      label: Text(strings.text(mode.name)),
                      selected: preferences.mode == mode,
                      onSelected: (_) => preferences.update(theme: mode),
                    ),
                  )
                  .toList(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.text('motion')),
              value: !preferences.paused,
              onChanged: (v) => preferences.update(pause: !v),
            ),
            Text(
              strings.text('palette'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                colorPresets.length,
                (i) => ChoiceChip(
                  avatar: CircleAvatar(
                    backgroundColor: colorPresets[i].color,
                    radius: 10,
                  ),
                  label: Text(colorPresets[i].name),
                  selected: preferences.palette == i,
                  onSelected: (_) => preferences.update(color: i),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings.text('pantoneNote'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final path = GoRouterState.of(context).uri.path;
    return Aurora(
      paused: preferences.paused,
      builder: (context, clock) => Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: AuroraArt(
                        clock,
                        dark: color.brightness == Brightness.dark,
                        seed: color.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final wide = box.maxWidth > 1000;
                          final nav = Material(
                            color: color.surfaceContainerHigh,
                            shape: const StadiumBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children:
                                      [
                                        'home',
                                        'posts',
                                        'projects',
                                        'friends',
                                        'about',
                                      ].map((name) {
                                        final suffix = name == 'home'
                                            ? ''
                                            : '/$name';
                                        final target = '/${strings.tag}$suffix';
                                        final selected = name == 'home'
                                            ? path == target
                                            : path.startsWith(target);
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              backgroundColor: selected
                                                  ? color.primary
                                                  : Colors.transparent,
                                              foregroundColor: selected
                                                  ? color.onPrimary
                                                  : color.onSurface,
                                            ),
                                            onPressed: () => context.go(target),
                                            child: Text(
                                              strings.text(name),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          );
                          return Column(
                            children: [
                              Row(
                                children: [
                                  IconButton.filledTonal(
                                    tooltip: 'PulseLink',
                                    onPressed: () =>
                                        context.go('/${strings.tag}'),
                                    icon: const Icon(Icons.blur_on),
                                  ),
                                  const SizedBox(width: 8),
                                  const Flexible(
                                    child: Text(
                                      'PulseLink',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (wide) nav,
                                  if (wide) const Spacer(),
                                  MenuAnchor(
                                    builder: (context, controller, child) =>
                                        IconButton(
                                          tooltip: strings.text('language'),
                                          icon: const Icon(Icons.translate),
                                          onPressed: () => controller.isOpen
                                              ? controller.close()
                                              : controller.open(),
                                        ),
                                    menuChildren: languages.entries
                                        .map(
                                          (lang) => MenuItemButton(
                                            onPressed: () {
                                              final segments = GoRouterState.of(
                                                context,
                                              ).uri.pathSegments.toList();
                                              segments[0] = lang.key;
                                              context.go(
                                                '/${segments.join('/')}',
                                              );
                                            },
                                            leadingIcon: lang.key == strings.tag
                                                ? const Icon(Icons.check)
                                                : const SizedBox(width: 24),
                                            child: Text(lang.value),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  IconButton.filledTonal(
                                    tooltip: strings.text('appearance'),
                                    onPressed: () => _appearance(context),
                                    icon: const Icon(Icons.palette_outlined),
                                  ),
                                ],
                              ),
                              if (!wide)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: nav,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: MotionClock(clock: clock, child: child),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
