import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'localization.dart';
import 'preferences.dart';
import 'startup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  // Preserve the incoming URL while assets load. The loading shell below
  // deliberately has no Navigator to overwrite the browser's route.
  final String _initialLocation = Uri.base.fragment.startsWith('/')
      ? Uri.base.fragment
      : WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  late Future<(BlogCatalog, BlogPreferences)> _pending = _load();
  BlogPreferences? _preferences;
  bool _readyScheduled = false;
  Future<(BlogCatalog, BlogPreferences)> _load() async {
    final catalog = await BlogCatalog.load();
    SharedPreferences? storage;
    try {
      storage = await SharedPreferences.getInstance();
    } catch (_) {
      /* Session preferences. */
    }
    final preferences = BlogPreferences(storage: storage);
    if (!mounted) {
      preferences.dispose();
    } else {
      _preferences = preferences;
    }
    return (catalog, preferences);
  }

  @override
  void dispose() {
    _preferences?.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<(BlogCatalog, BlogPreferences)>(
    future: _pending,
    builder: (context, snapshot) {
      if ((snapshot.hasData || snapshot.hasError) && !_readyScheduled) {
        _readyScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) markAppReady();
        });
      }
      if (snapshot.hasData) {
        return PulseLinkApp(
          initialLocation: _initialLocation,
          catalog: snapshot.data!.$1,
          preferences: snapshot.data!.$2,
        );
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: blogTheme(Brightness.light, colorPresets.first.color, 'zh-CN'),
        darkTheme: blogTheme(
          Brightness.dark,
          colorPresets.first.color,
          'zh-CN',
        ),
        builder: (context, child) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Blue · PulseLink',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 24),
                  if (snapshot.hasError) ...[
                    const Text('内容加载失败 / Content could not be loaded'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => setState(() => _pending = _load()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试 / Retry'),
                    ),
                  ] else
                    const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
