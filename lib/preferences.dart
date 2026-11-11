import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorPreset {
  const ColorPreset(this.name, this.color);
  final String name;
  final Color color;
}

const colorPresets = [
  ColorPreset('Botanical', Color(0xFF52734D)),
  ColorPreset('Lagoon', Color(0xFF007F87)),
  ColorPreset('Cobalt', Color(0xFF4263C7)),
  ColorPreset('Iris', Color(0xFF7556A5)),
  ColorPreset('Rose', Color(0xFFA94C73)),
  ColorPreset('Terracotta', Color(0xFFAC593D)),
  ColorPreset('Amber', Color(0xFF916D13)),
  ColorPreset('Slate', Color(0xFF526778)),
  ColorPreset('Mocha Mousse · 2025', Color(0xFFA47864)),
  ColorPreset('Peach Fuzz · 2024', Color(0xFFFFBE98)),
  ColorPreset('Very Peri · 2022', Color(0xFF6667AB)),
  ColorPreset('Cherry', Color(0xFFAD3450)),
  ColorPreset('Ocean', Color(0xFF226785)),
  ColorPreset('Olive', Color(0xFF707843)),
  ColorPreset('Orchid', Color(0xFFA454A0)),
  ColorPreset('Mint', Color(0xFF3B8F73)),
];

class BlogPreferences extends ChangeNotifier {
  BlogPreferences({SharedPreferences? storage}) : _storage = storage {
    final color = storage?.getInt('color') ?? 0;
    palette = color >= 0 && color < colorPresets.length ? color : 0;
    mode = ThemeMode.values.firstWhere(
      (m) => m.name == storage?.getString('mode'),
      orElse: () => ThemeMode.system,
    );
    paused = storage?.getBool('paused') ?? false;
  }
  final SharedPreferences? _storage;
  int palette = 0;
  ThemeMode mode = ThemeMode.system;
  bool paused = false;
  Future<void> update({int? color, ThemeMode? theme, bool? pause}) async {
    if (color != null && color >= 0 && color < colorPresets.length) {
      palette = color;
    }
    if (theme != null) mode = theme;
    if (pause != null) paused = pause;
    notifyListeners();
    // Browser storage can be disabled. Preferences remain effective in memory.
    try {
      await _storage?.setInt('color', palette);
      await _storage?.setString('mode', mode.name);
      await _storage?.setBool('paused', paused);
    } catch (_) {
      /* Session-only settings remain usable. */
    }
  }
}

ThemeData blogTheme(Brightness brightness, Color seed, String language) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.expressive,
  );
  // Keep the selected swatch recognizable while retaining expressive accent tones.
  final primary = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  final resolved = scheme.copyWith(
    primary: primary.primary,
    onPrimary: primary.onPrimary,
    primaryContainer: primary.primaryContainer,
    onPrimaryContainer: primary.onPrimaryContainer,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: resolved,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Google Sans',
    fontFamilyFallback: language == 'ja'
        ? const ['Noto Sans JP', 'Noto Sans SC', 'Noto Sans TC']
        : language == 'zh-TW'
        ? const ['Noto Sans TC', 'Noto Sans SC', 'Noto Sans JP']
        : const ['Noto Sans SC', 'Noto Sans JP', 'Noto Sans TC'],
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.8,
        height: 1.16,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.9),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        height: 1.8,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder()),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
      side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: .55),
      space: 1,
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 400),
    ),
  );
}
