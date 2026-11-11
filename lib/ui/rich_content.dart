import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services.dart';

/// Only explicit HTTPS links and bundled images are rendered. Markdown HTML
/// is never executed; article content cannot select local files or data URLs.
class RichContent extends StatelessWidget {
  const RichContent({super.key, required this.data});
  final String data;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return SelectionArea(
      child: MarkdownBody(
        data: data,
        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: theme.textTheme.bodyLarge,
          pPadding: const EdgeInsets.only(bottom: 16),
          strong: const TextStyle(fontWeight: FontWeight.w700),
          a: TextStyle(color: c.primary, decoration: TextDecoration.underline),
          code: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.65,
            color: c.onSurface,
            backgroundColor: c.surfaceContainerHigh,
          ),
          codeblockPadding: const EdgeInsets.all(20),
          codeblockDecoration: BoxDecoration(
            color: c.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          blockquoteDecoration: BoxDecoration(
            color: c.secondaryContainer.withValues(alpha: .4),
            border: Border(left: BorderSide(color: c.primary, width: 3)),
          ),
          blockquotePadding: const EdgeInsets.all(20),
          tableColumnWidth: const IntrinsicColumnWidth(),
          tableCellsPadding: const EdgeInsets.all(14),
          tableBorder: TableBorder.all(color: c.outlineVariant),
          blockSpacing: 18,
        ),
        onTapLink: (text, href, title) async {
          final uri = safeWebUri(href ?? '');
          if (uri != null) {
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {
              /* The browser may block external navigation. */
            }
          }
        },
        imageBuilder: (uri, title, alt) {
          if (uri.scheme != 'resource' ||
              !RegExp(r'^assets/images/[a-zA-Z0-9_/-]+\.(png|jpg|jpeg|webp)$')
                  .hasMatch(uri.path) ||
              uri.path.split('/').contains('..')) {
            return Text(alt ?? title ?? '');
          }
          return Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  uri.path,
                  semanticLabel: alt,
                  fit: BoxFit.contain,
                ),
              ),
              if (title != null && title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(title, style: theme.textTheme.bodySmall),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Mermaid is rendered during publishing, not executed in the reader's page.
/// The original source remains available for inspection alongside the figure.
class DiagramFigure extends StatelessWidget {
  const DiagramFigure({
    super.key,
    required this.id,
    required this.language,
    required this.caption,
    required this.expandLabel,
  });
  final String id, language, caption, expandLabel;
  @override
  Widget build(BuildContext context) {
    if (!RegExp(r'^[a-z][a-z0-9-]{1,63}$').hasMatch(id)) {
      return const SizedBox();
    }
    final theme = Theme.of(context);
    final mode = theme.brightness.name;
    final asset = 'assets/diagrams/$id-$language-$mode.png';
    Widget picture() => Image.asset(
      asset,
      fit: BoxFit.contain,
      semanticLabel: caption,
      errorBuilder: (context, error, stack) =>
          Padding(padding: const EdgeInsets.all(24), child: Text(caption)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 620),
                child: picture(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(caption, style: theme.textTheme.bodySmall),
                  ),
                  IconButton(
                    tooltip: expandLabel,
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => Dialog.fullscreen(
                        child: SafeArea(
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: CloseButton(
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              Expanded(
                                child: InteractiveViewer(
                                  minScale: .5,
                                  maxScale: 5,
                                  child: Center(child: picture()),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(caption),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ExpansionTile(
              title: const Text('Mermaid'),
              childrenPadding: const EdgeInsets.all(20),
              children: [
                Builder(
                  builder: (context) => FutureBuilder<String>(
                    future: rootBundle.loadString(
                      'assets/diagrams/$id-$language.mmd',
                    ),
                    builder: (context, snapshot) => snapshot.hasData
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(
                              snapshot.data!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          )
                        : snapshot.hasError
                        ? Text(caption)
                        : const LinearProgressIndicator(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
