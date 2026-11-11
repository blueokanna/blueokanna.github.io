class BlogSection {
  const BlogSection(this.heading, this.body, {this.diagram});
  final String heading, body;
  final String? diagram;
}

class SourceLink {
  const SourceLink(this.label, this.url);
  factory SourceLink.fromJson(Map<String, dynamic> data) =>
      SourceLink(data['label'] as String, data['url'] as String);
  final String label, url;
}

class BlogPost {
  BlogPost(Map<String, dynamic> data)
    : id = data['id'] as String,
      category = data['category'] as String,
      title = data['title'] as String,
      summary = data['summary'] as String,
      sections = (data['sections'] as List)
          .map(
            (s) => BlogSection(
              s['heading'] as String,
              s['body'] as String,
              diagram: s['diagram'] as String?,
            ),
          )
          .toList(),
      sources = (data['sources'] as List? ?? [])
          .map((s) => SourceLink.fromJson(s as Map<String, dynamic>))
          .toList();
  final String id, category, title, summary;
  final List<BlogSection> sections;
  final List<SourceLink> sources;
}
