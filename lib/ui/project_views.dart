import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization.dart';
import '../models/project.dart';
import 'components.dart';
import 'expressive.dart';
import 'rich_content.dart';

IconData projectIcon(String id) => switch (id) {
  'segmeris' => Icons.movie_filter_outlined,
  'arcadiaplus' => Icons.public,
  'recursex' => Icons.account_tree_outlined,
  'corduit' => Icons.alt_route,
  'courierust' => Icons.swap_horiz,
  _ => Icons.auto_awesome_outlined,
};

class ProjectCollection extends StatelessWidget {
  const ProjectCollection({
    super.key,
    required this.projects,
    required this.strings,
    this.compact = false,
  });
  final List<ProjectEntry> projects;
  final BlogStrings strings;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return ResponsiveColumns(
      minWidth: 420,
      children: (compact ? projects.take(4) : projects)
          .map(
            (project) => ExpressiveCard(
              variant: project.variant,
              onTap: () => context.go('/${strings.tag}/projects/${project.id}'),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ShapeEmblem(
                          variant: project.variant,
                          icon: projectIcon(project.id),
                        ),
                        const Spacer(),
                        Icon(Icons.north_east, color: colors.primary),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      project.name,
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      project.descriptions[strings.tag]!,
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    const Spacer(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: project.stack
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                              backgroundColor: colors.surfaceContainerHigh,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class ProjectDetail extends StatelessWidget {
  const ProjectDetail({
    super.key,
    required this.project,
    required this.strings,
  });
  final ProjectEntry project;
  final BlogStrings strings;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/${strings.tag}/projects'),
                icon: const Icon(Icons.arrow_back),
                label: Text(strings.text('projects')),
              ),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: ShapeEmblem(
                variant: project.variant,
                icon: projectIcon(project.id),
                size: 140,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              project.name,
              style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Text(project.descriptions[strings.tag]!, style: text.bodyLarge),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: project.stack
                  .map((tag) => Chip(label: Text(tag)))
                  .toList(),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: ExternalLink(
                url: project.repository,
                label: '${strings.text('source')} ↗',
              ),
            ),
            if (project.articleId case final String article)
              TextButton.icon(
                onPressed: () => context.go('/${strings.tag}/posts/$article'),
                icon: const Icon(Icons.article_outlined),
                label: Text(strings.text('read')),
              ),
            const SizedBox(height: 48),
            for (final section in project.sections[strings.tag]!) ...[
              Text(
                section.heading,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              RichContent(data: section.body),
              const SizedBox(height: 48),
            ],
            const Divider(),
            const SizedBox(height: 24),
            Text(strings.text('references'), style: text.titleMedium),
            const SizedBox(height: 12),
            for (final source in project.sources)
              Align(
                alignment: Alignment.centerLeft,
                child: ExternalLink(url: source.url, label: source.label),
              ),
          ],
        ),
      ),
    );
  }
}
