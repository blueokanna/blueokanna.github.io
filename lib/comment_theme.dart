import 'package:flutter/material.dart';

String cssColor(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

String commentThemeId(ColorScheme colors) =>
    '${colors.brightness.name}-${cssColor(colors.primary).substring(1)}';
