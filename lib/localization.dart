import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/project.dart';
import 'models/article.dart';
export 'models/article.dart';

const languages = <String, String>{
  'zh-CN': '简体中文',
  'zh-TW': '繁體中文',
  'en': 'English',
  'ja': '日本語',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
  'ru': 'Русский',
  'pt': 'Português',
  'it': 'Italiano',
};
Locale localeFor(String tag) => switch (tag) {
  'zh-CN' => const Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode: 'Hans',
    countryCode: 'CN',
  ),
  'zh-TW' => const Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode: 'Hant',
    countryCode: 'TW',
  ),
  _ => Locale(tag),
};

class BlogStrings {
  BlogStrings(this.tag, this.data)
    : posts = (data['articles'] as List)
          .map((p) => BlogPost(p as Map<String, dynamic>))
          .toList();
  final String tag;
  final Map<String, dynamic> data;
  final List<BlogPost> posts;
  String text(String key) => data[key] as String;
}

class BlogCatalog {
  BlogCatalog(this.translations, this.projects);
  final Map<String, BlogStrings> translations;
  final List<ProjectEntry> projects;
  static Future<BlogCatalog> load() async {
    final entries = await Future.wait(
      languages.keys.map((tag) async {
        final data = jsonDecode(
          await rootBundle.loadString('assets/i18n/$tag.json'),
        ) as Map<String, dynamic>;
        return MapEntry(tag, BlogStrings(tag, data));
      }),
    );
    final projects =
        jsonDecode(await rootBundle.loadString('assets/projects.json')) as List;
    return BlogCatalog(
      Map.fromEntries(entries),
      projects
          .map((p) => ProjectEntry.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
