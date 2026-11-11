class FriendLink {
  const FriendLink(
      {required this.name,
      required this.url,
      required this.desc,
      required this.descEn,
      this.avatar});
  final String name, url, desc, descEn;
  final String? avatar;
}

const friends = [
  FriendLink(
      name: 'Lxns Network',
      url: 'https://lxns.org/',
      desc: 'Lxns Network · 来自中国的开发团队',
      descEn: 'A development team from China'),
  FriendLink(
      name: '陶然',
      url: 'https://taoran.weppp.cyou',
      desc: '一团温暖的粘土博客',
      descEn: 'A warm clay blog',
      avatar: 'https://taoran.weppp.cyou/favicon.svg'),
];

/// Repository notes, without invented publication dates or personal claims.
class JournalEntry {
  const JournalEntry(this.tag, this.title, this.titleEn, this.summary,
      this.summaryEn, this.body, this.bodyEn);
  final String tag, title, titleEn, summary, summaryEn, body, bodyEn;
}

const journal = [
  JournalEntry(
      'ENGINEERING',
      '让界面呼吸，\n让渲染保持克制。',
      'A living interface.\nA quieter render loop.',
      '本站动效实现笔记：共享时钟、局部重绘，以及恰到好处的留白。',
      'Shared animation clocks, isolated painting and space to breathe.',
      '动效的价值是帮助理解变化，而不是让每一块内容都不停移动。\n\n本站的 Aurora 组件使用一个 AnimationController 驱动背景和主视觉。CustomPainter 监听这个时钟并直接请求重绘，文字和内容列表不需要跟着每一帧重新构建。绘制区域由 RepaintBoundary 隔离。\n\n图形使用渐变与路径构成，没有全屏模糊滤镜。导航和展开阅读使用相同的时长与曲线，让不同交互保有一致的节奏。\n\n系统开启减少动画、用户暂停动效或应用进入后台时，持续动画停止。静态图形仍然保留，阅读和导航不依赖动画完成。\n\n这是一种应用层渲染组织方式，不是修改 Flutter 引擎。具体节省多少 CPU、GPU 和电量，需要在目标设备上使用性能工具测量。',
      'Motion should explain change.\n\nAurora uses one AnimationController for ambient and hero artwork. CustomPainter listens directly to that clock, requesting paint without rebuilding text or lists every frame. RepaintBoundary isolates painted regions.\n\nGradients and paths replace full-screen blur filters. Navigation and reading transitions share timing and curves.\n\nContinuous animation stops for reduced motion, pause, or background lifecycle states. Content remains readable.\n\nThis organizes rendering at the application layer; it does not modify the Flutter engine. CPU, GPU and energy savings require measurements on target devices.'),
  JournalEntry(
      'WEB / TRUST',
      '静态网站，\n也要认真对待信任。',
      'Static hosting.\nReal responsibilities.',
      '公开的构建产物里没有秘密；网络失败也不应该变成虚构的数据。',
      'Public bundles cannot keep secrets. Failed requests should never become invented facts.',
      'GitHub Pages 分发的是公开文件。无论把密钥写在源码还是通过 dart-define 注入，只要客户端使用它，访问者就有机会从构建产物或网络请求中取得它。\n\n本站不在浏览器内接入需要私密密钥的 AI 服务。未来如果需要此功能，应先建立有身份验证、配额与速率限制的服务端。\n\n项目列表来自 GitHub 公开 API，有超时、状态码检查和十分钟的会话内缓存。失败时显示重试入口与 GitHub 链接，不编造 Star 或关注者数量。\n\n友链独立维护，外链仅允许合法 HTTPS 地址。技术笔记随站点打包，因此外部 API 不可用时仍能阅读。',
      'GitHub Pages serves public files. Keys embedded in source or dart-define values can be extracted from client bundles or network requests.\n\nThis site does not connect to private-key AI services from the browser. Such a feature requires a server with authentication, quotas and rate limiting.\n\nRepositories come from the public GitHub API with timeouts, status checks and a ten-minute session cache. Failures show retry and GitHub links, never fabricated statistics.\n\nExternal links accept HTTPS only. Local notes ship with the site and remain readable if the API is unavailable.'),
  JournalEntry(
      'DESIGN NOTES',
      '形状有性格，\n阅读有秩序。',
      'Shapes with character.\nReading with rhythm.',
      '从一枚花瓣到一张卡片，用形状区分情绪，用排版组织内容。',
      'Expressive shapes set the mood. Typography gives content structure.',
      '主视觉的花瓣轮廓随共享时钟缓慢变形。它只承担装饰作用，不干扰文字，也不作为唯一的信息载体。\n\n卡片通过不同的圆角与配色建立分组；可点击区域使用 Material 的焦点、悬停与按压反馈。主要操作保留图标和文字，键盘用户也能顺序访问。\n\n窄屏将双栏内容重新排成单栏。字号和文本长度可以变化，内容容器不使用固定高度强行裁切。减少动画时，布局和功能保持完整。',
      'The petal silhouette slowly morphs with the shared clock. It is decorative, never the only way to convey information.\n\nCard shapes and colors distinguish groups. Interactive areas use Material focus, hover and press feedback, with labeled keyboard-accessible primary actions.\n\nNarrow screens rearrange columns into a single reading flow. Text containers grow rather than crop content into fixed heights. Reduced motion preserves the full layout and functionality.'),
];
