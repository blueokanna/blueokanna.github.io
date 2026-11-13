import 'package:flutter/material.dart';

import '../companion.dart';

class CompanionScene extends StatelessWidget {
  const CompanionScene({
    super.key,
    required this.mood,
    this.onAction,
    this.compact = false,
  });
  final CompanionMood mood;
  final ValueChanged<String>? onAction;
  final bool compact;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '3D companion: ${mood.name}',
    child: const Center(child: Icon(Icons.view_in_ar_outlined, size: 48)),
  );
}
