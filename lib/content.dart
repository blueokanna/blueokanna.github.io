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
