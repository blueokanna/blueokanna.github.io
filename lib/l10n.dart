/// Bilingual localization for PulseLink Blog (中文 / English).
enum AppLanguage { zh, en }

class S {
  S._(this._lang);
  final AppLanguage _lang;
  bool get isZh => _lang == AppLanguage.zh;
  static S of(AppLanguage l) => S._(l);
  String _p(String zh, String en) => isZh ? zh : en;

  // ── App ──
  String get appTitle => _p('Blue的PulseLink博客', "Blue's PulseLink Blog");
  String get brandSubtitle => 'Material 3 × Flutter Web';

  // ── Navigation ──
  String get navHome => _p('首页', 'Home');
  String get navAbout => _p('关于', 'About');
  String get navSkills => _p('技能', 'Skills');
  String get navBlog => _p('博客', 'Blog');
  String get navProjects => _p('项目', 'Projects');
  String get navContact => _p('联系', 'Contact');

  // ── Hero ──
  String get heroTitle => _p(
        'Blue — 构建快速、优雅且富有表现力的Web产品。',
        'Blue builds fast, calm and expressive products for the web.',
      );
  String get heroSubtitle => _p(
        '基于Flutter Web与Material Design 3重建的个人博客，采用自适应布局、MD3图标语言与流畅动态，以及像Wise一样干净自信的设计语言。',
        "A Flutter Web rewrite for Blue's personal blog, grounded in Material Design 3, adaptive layouts, expressive MD3 icon language, and the clean confidence that makes Wise feel effortless.",
      );
  String get exploreProjects => _p('探索项目', 'Explore Projects');
  String get letsConnect => _p('联系我', "Let's Connect");
  String get flutterWebOnly => _p('纯Flutter Web', 'Flutter Web only');
  String get materialDesign3 => _p('全面Material 3', 'Material 3 all the way');
  String get weatherSyncing => _p('天气同步中', 'Weather syncing');

  // ── Greetings ──
  String get goodMorning => _p('早上好', 'Good morning');
  String get goodAfternoon => _p('下午好', 'Good afternoon');
  String get goodEvening => _p('晚上好', 'Good evening');
  String get lateNight => _p('深夜仍在编码', 'Still shipping late');

  // ── Device ──
  String deviceDetected(String d) => _p('检测到$d', '$d detected');
  String get mobile => _p('手机', 'Mobile');
  String get tablet => _p('平板', 'Tablet');
  String get desktop => _p('桌面', 'Desktop');

  // ── About ──
  String get aboutEyebrow => _p('关于', 'About');
  String get aboutTitle => _p(
        '一个专注于系统架构、流畅动效与技术深度的个人工作室。',
        'A personal studio for systems, calm motion and technical depth.',
      );
  String get aboutSubtitle => _p(
        '网站设计理念：感知天气、适应节日、识别设备，在任何屏幕上都保持可靠与优雅。',
        'The site is designed to feel alive without feeling noisy: weather-aware, holiday-aware, device-aware and still reliable on mobile, tablet and desktop.',
      );
  String get storyHeading => _p(
        '心理学优先的UI设计：自信、节奏感与清晰的层次。',
        'Psychology-first UI: confidence, rhythm, clear hierarchy.',
      );
  String get aboutP1 => _p(
        'Blue专注于后端工程、开源工具与产品思维，尊重延迟、信任和清晰度。新站点将个人博客视为精打细磨的产品界面，而非普通的演示页面。',
        "Blue focuses on backend engineering, open-source tooling and product thinking that respects latency, trust and clarity. The new site treats a personal blog like a polished product surface rather than a demo page.",
      );
  String get aboutP2 => _p(
        '这意味着可组合的区块、稳定的动画、Material 3语义、针对真实浏览器宽度调优的响应式行为，以及既有技术感又有人文温度的表达。',
        'That means composable sections, stable animations, Material 3 semantics, responsive behavior tuned for real browser widths, and a tone that feels both technical and human.',
      );
  String get repositories => _p('仓库', 'Repositories');
  String get totalStars => _p('总Star数', 'Total Stars');
  String get followers => _p('关注者', 'Followers');
  String get yearsBuilding => _p('编程年数', 'Years Building');

  // ── Skills ──
  String get skillsEyebrow => _p('技能栈', 'Skills');
  String get skillsTitle => _p(
        '全栈技术能力，配以MD3图标语言呈现。',
        'Full-stack capabilities with an MD3 icon language.',
      );
  String get skillsSubtitle => _p(
        '界面使用深度来传达分组、优先级和愉悦感，同时在小屏设备上保持可用性。',
        'The interface uses depth to signal grouping, priority and delight while remaining usable on smaller devices.',
      );
  String get backendSystems => _p('后端系统', 'Backend Systems');
  String get backendDesc => _p(
        'Java、Rust、API设计、并发处理与精细性能调优。',
        'Java, Rust, API design, concurrency and careful performance tuning.',
      );
  String get aiLlm => _p('AI与大模型', 'AI & LLM');
  String get aiLlmDesc => _p(
        '基于ChatGLM/智谱AI的大模型集成、嵌入式AI应用与智能化服务。',
        'ChatGLM / Zhipu AI integration, embedded AI applications and intelligent services.',
      );
  String get webCraft => _p('Web工艺', 'Web Craft');
  String get webCraftDesc => _p(
        'Flutter Web界面，具备稳定的断点、丝滑的动效与清晰的层次结构。',
        'Flutter Web interfaces with stable breakpoints, silky motion and strong hierarchy.',
      );
  String get iotEmbedded => _p('IoT与嵌入式', 'IoT & Embedded');
  String get iotEmbeddedDesc => _p(
        'ESP32、Arduino平台上的嵌入式开发与物联网应用。',
        'ESP32 and Arduino embedded development and IoT applications.',
      );
  String get cryptoSecurity => _p('密码学与安全', 'Cryptography');
  String get cryptoSecurityDesc => _p(
        'JWT认证、加密算法设计与安全架构方案。',
        'JWT authentication, encryption algorithm design and security architecture.',
      );
  String get systemArch => _p('系统架构', 'System Architecture');
  String get systemArchDesc => _p(
        '云计算、高性能代理、网络协议与跨平台架构。',
        'Cloud computing, high-performance proxies, network protocols and cross-platform architecture.',
      );

  // ── Blog ──
  String get blogEyebrow => _p('博客', 'Blog');
  String get blogTitle =>
      _p('精选技术洞察与工程实践。', 'Curated technical insights and engineering notes.');
  String get blogSubtitle => _p(
        '采用纯前端静态内容分发，保证在 GitHub Pages 上稳定可访问。',
        'Served as static front-end content for stable access on GitHub Pages.',
      );
  String get generateArticle => _p('生成新文章', 'Generate Article');
  String get generating => _p('AI正在创作中…', 'AI is writing…');
  String get aiChatTitle => _p('AI助手', 'AI Assistant');
  String get aiChatHint => _p('输入你的问题…', 'Ask a question…');
  String get aiNotConfigured => _p(
        'AI功能需要配置智谱清言API密钥。\n请在GitHub Actions中设置 ZHIPU_API_KEY 环境变量，构建时通过 --dart-define 注入。',
        'AI features require a Zhipu API key.\nSet ZHIPU_API_KEY in GitHub Actions secrets and inject via --dart-define at build time.',
      );
  String get send => _p('发送', 'Send');
  String get aiWelcome => _p(
        '你好！我是Blue的AI助手，基于智谱清言GLM-4-Flash。有什么我可以帮你的吗？',
        "Hi! I'm Blue's AI assistant, powered by Zhipu GLM-4-Flash. How can I help you?",
      );
  String get askAi => _p('问AI', 'Ask AI');
  String get close => _p('关闭', 'Close');
  String get readMore => _p('阅读全文', 'Read More');
  String get collapse => _p('收起', 'Collapse');
  String get articleGenerated => _p('AI原创文章', 'AI Original Article');
  String get noArticlesYet => _p(
        '点击下方按钮让AI生成一篇原创科技分析文章。',
        'Click the button below to let AI generate an original tech analysis article.',
      );

  // ── Tools ──
  String get navTools => _p('工具', 'Tools');
  String get toolsEyebrow => _p('工具箱', 'Toolbox');
  String get toolsTitle => _p('实用工具，基于WASM与现代Web技术。',
      'Practical tools powered by WASM and modern web tech.');
  String get toolsSubtitle => _p(
        '浏览器端运行的高性能工具集，无需安装即可使用。',
        'High-performance tools running in your browser — no install needed.',
      );
  String get m3u8DownloaderTitle => _p('M3U8视频下载器', 'M3U8 Video Downloader');
  String get m3u8DownloaderDesc => _p(
        '基于Rust编译为WebAssembly的浏览器端M3U8视频流下载工具，支持HLS协议，高效下载与合并视频分片。',
        'A Rust-compiled WebAssembly tool for downloading M3U8/HLS video streams in the browser — efficient segment download and merge.',
      );
  String get openTool => _p('打开工具', 'Open Tool');
  String get viewSource => _p('查看源码', 'View Source');

  // ── Projects ──
  String get projectsEyebrow => _p('项目', 'Projects');
  String get projectsTitle =>
      _p('开源作品，以产品级界面呈现。', 'Open-source work, surfaced like products.');
  String get projectsSubtitle => _p(
        'GitHub数据实时拉取，以卡片形式展示，在窄屏上依然清晰可读。',
        'GitHub data is pulled live and presented in cards that remain clear even on narrow screens.',
      );
  String get viewGitHub => _p('查看完整GitHub主页', 'View full GitHub profile');
  String get loadingRepos =>
      _p('正在从GitHub加载仓库…', 'Loading repositories from GitHub…');
  String stars(int n) => '$n ★';
  String forks(int n) => '$n ⑂';

  // ── Contact ──
  String get contactEyebrow => _p('联系', 'Contact');
  String get contactTitle => _p(
        '打造完整的个人产品体验，期待与你连接。',
        'Built as a complete personal product. Ready to connect.',
      );
  String get contactSubtitle => _p(
        '落幕区块以强号召力结尾，在每种屏幕尺寸上留足呼吸空间。',
        'The final section keeps the energy up with strong calls-to-action and enough breathing room to end the page cleanly on every screen size.',
      );
  String get madeWith =>
      _p('使用 Flutter Web + MD3 构建', 'Made with Flutter Web + MD3');
  String get copyright => '© 2023–2026 Blue';

  // ── Weather ──
  String get weatherLoading => _p('天气加载中', 'Weather loading');
  String weatherIn(String city, String temp) =>
      _p('$city $temp', '$temp in $city');

  // ── Time labels ──
  String updatedToday() => _p('今天更新', 'Updated today');
  String daysAgo(int d) => _p('$d 天前', '$d days ago');
  String weeksAgo(int w) => _p('$w 周前', '$w weeks ago');
  String monthsAgo(int m) => _p('$m 个月前', '$m months ago');

  // ── Skill card chip labels ──
  List<String> get backendChips => _p(
        'Spring Boot,Rust服务,API契约',
        'Spring Boot,Rust services,Clean contracts',
      ).split(',');
  List<String> get aiChips => _p(
        'ChatGLM,LLM集成,智能API',
        'ChatGLM,LLM integration,Smart APIs',
      ).split(',');
  List<String> get webChips => _p(
        'Material 3,自适应布局,丝滑动效',
        'Material 3,Adaptive layout,Silky motion',
      ).split(',');
  List<String> get iotChips =>
      _p('ESP32,Arduino,传感器集成', 'ESP32,Arduino,Sensor integration').split(',');
  List<String> get cryptoChips =>
      _p('JWT,加密算法,安全架构', 'JWT,Encryption,Security arch').split(',');
  List<String> get archChips =>
      _p('云计算,高性能代理,微服务', 'Cloud,High-perf proxy,Microservices').split(',');

  // ── Holiday names ──
  String get christmasSeason => _p('圣诞季', 'Christmas Season');
  String get holidayGlow => _p('节日光芒', 'Holiday glow');
  String get halloweenMood => _p('万圣夜', 'Halloween Mood');
  String get spookyMode => _p('幽灵模式', 'Spooky mode');
  String get valentinePulse => _p('情人节', "Valentine's");
  String get heartSync => _p('心动同步', 'Heart sync');
  String get springFestival => _p('春节', 'Spring Festival');
  String get springGlow => _p('新春光辉', 'Spring glow');
  String get midAutumn => _p('中秋节', 'Mid-Autumn');
  String get moonlight => _p('月光', 'Moonlight');
  String get springTone => _p('春日色调', 'Spring Tone');
  String get seasonalAccent => _p('时令色彩', 'Seasonal accent');
  String get switchLang => _p('EN', '中文');
}
