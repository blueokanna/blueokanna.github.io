import 'package:flutter/material.dart';

class EmbeddedComments extends StatelessWidget {
  const EmbeddedComments({
    super.key,
    required this.postId,
    required this.language,
    required this.dark,
    required this.unavailableLabel,
    required this.linkLabel,
  });
  final String postId, language, unavailableLabel, linkLabel;
  final bool dark;
  @override
  Widget build(BuildContext context) => const SizedBox(height: 240);
}
