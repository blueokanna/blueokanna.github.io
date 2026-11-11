import 'article.dart';

class ProjectEntry {
  ProjectEntry.fromJson(Map<String, dynamic> data)
    : id = data['id'] as String,
      name = data['name'] as String,
      repository = data['repository'] as String,
      stack = List<String>.from(data['stack'] as List),
      variant = data['variant'] as int,
      articleId = data['articleId'] as String?,
      descriptions = Map<String, String>.from(data['description'] as Map),
      sections = (data['sections'] as Map<String, dynamic>).map(
        (tag, entries) => MapEntry(
          tag,
          (entries as List)
              .map(
                (s) => BlogSection(s['heading'] as String, s['body'] as String),
              )
              .toList(),
        ),
      ),
      sources = (data['sources'] as List)
          .map((s) => SourceLink.fromJson(s as Map<String, dynamic>))
          .toList();
  final String id, name, repository;
  final String? articleId;
  final int variant;
  final List<String> stack;
  final Map<String, String> descriptions;
  final Map<String, List<BlogSection>> sections;
  final List<SourceLink> sources;
}
