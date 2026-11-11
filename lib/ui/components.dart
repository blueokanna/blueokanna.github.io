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
      final width = (box.maxWidth - 20 * (count - 1)) / count;
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
      builder: (context, follow) =>
          TextButton(onPressed: follow, child: Text(label)),
    );
  }
}
