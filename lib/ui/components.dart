import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

import '../services.dart';

class ResponsiveColumns extends StatelessWidget {
  const ResponsiveColumns({
    super.key,
    required this.children,
    required this.minWidth,
  });
  final List<Widget> children;
  final double minWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final count = ((box.maxWidth + 20) / (minWidth + 20)).floor().clamp(1, 3);
      return Column(
        children: [
          for (var start = 0; start < children.length; start += count) ...[
            if (start > 0) const SizedBox(height: 24),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < count; column++) ...[
                    if (column > 0) const SizedBox(width: 24),
                    Expanded(
                      child: start + column < children.length
                          ? children[start + column]
                          : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
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
      builder: (context, follow) =>
          TextButton(onPressed: follow, child: Text(label)),
    );
  }
}
