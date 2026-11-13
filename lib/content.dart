import 'dart:convert';

import 'services.dart';

class FriendLink {
  const FriendLink({
    required this.name,
    required this.url,
    required this.desc,
    required this.descEn,
    this.avatar,
  });
  final String name, url, desc, descEn;
  final String? avatar;
  Map<String, String> toJson() => {
    'name': name,
    'url': url,
    'desc': desc,
    'descEn': descEn,
    if (avatar != null) 'avatar': avatar!,
  };
  void validate() {
    if (name.trim().isEmpty ||
        name.length > 80 ||
        desc.length > 400 ||
        descEn.length > 400 ||
        url.length > 2048 ||
        safeWebUri(url) == null ||
        (avatar != null &&
            (avatar!.length > 2048 || safeWebUri(avatar!) == null))) {
      throw const FormatException('友链需要有效的 HTTPS 地址；名称上限 80 字，简介上限 400 字。');
    }
  }

  static String encode(List<FriendLink> links) {
    if (links.length > 100) throw const FormatException('友链最多 100 条。');
    final urls = <String>{};
    for (final link in links) {
      link.validate();
      if (!urls.add(Uri.parse(link.url).replace(fragment: '').toString())) {
        throw const FormatException('友链地址不能重复。');
      }
    }
    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'links': links.map((link) => link.toJson()).toList(),
    });
  }

  static List<FriendLink> decode(String text) {
    if (utf8.encode(text).length > 262144) {
      throw const FormatException('友链文件过大。');
    }
    final json = jsonDecode(text);
    if (json is! Map || json['version'] != 1 || json['links'] is! List) {
      throw const FormatException('友链格式无效。');
    }
    final links = (json['links'] as List)
        .map(
          (item) => FriendLink(
            name: item['name'] as String,
            url: item['url'] as String,
            desc: item['desc'] as String,
            descEn: item['descEn'] as String? ?? '',
            avatar: item['avatar'] as String?,
          ),
        )
        .toList();
    encode(links);
    return List.unmodifiable(links);
  }
}

const friends = [
  FriendLink(
    name: 'Lxns Network',
    url: 'https://lxns.org/',
    desc: 'Lxns Network · 来自中国的开发团队',
    descEn: 'A development team from China',
  ),
  FriendLink(
    name: '陶然',
    url: 'https://taoran.weppp.cyou',
    desc: '一团温暖的粘土博客',
    descEn: 'A warm clay blog',
    avatar: 'https://taoran.weppp.cyou/favicon.svg',
  ),
];
