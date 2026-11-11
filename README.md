# PulseLink

Blue 的 Flutter Web 博客：独立文章、项目详情、友链和 GitHub Discussions 留言。部署在 GitHub Pages，正文随应用发布，不依赖在线内容生成。

## 开发与验证

固定 Flutter 3.47.9 / Dart 3.13.7，构建图解使用 Node 22.13+。Dart 和 Node 依赖分别由 pubspec.lock、package-lock.json 固定。

```sh
flutter pub get --enforce-lockfile
python -m pip install -r scripts/requirements-fonts.txt
python scripts/prepare_fonts.py
npm ci --ignore-scripts
npm run diagrams
flutter test tool/export_comment_themes_test.dart
dart format lib test tool
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
node --test test/comments_test.mjs
flutter build web --release --base-href / --no-web-resources-cdn
```

Windows 可运行 `./scripts/publish_web.ps1`，依次检查字体、格式、分析、测试和构建。字体缓存位于 `.font-cache`，不参与部署。首次准备字体需要网络；下载内容有固定提交地址与 SHA-256 校验。

`npm run diagrams` 使用官方 Mermaid CLI 和无头 Chrome；本机可设置 `PUPPETEER_EXECUTABLE_PATH`，没有 Chrome 时先运行 `npx puppeteer browsers install chrome`。渲染器只用于构建，读者无需下载 Mermaid 或启动额外服务。

`flutter test tool/render_preview_test.dart` 可生成 `build/qa/desktop.png`、`mobile.png` 及深色桌面、浅色手机的转场中间帧，使用真实字体检查 Flutter 排版。它不是浏览器截图，也不测量浏览器帧率。发布构建后运行 `npm run test:browser`，可用隔离的无头浏览器检查启动交接、可见动画和桌面/手机/平板直接链接刷新，截图保存在 `build/qa/browser`，CI 也执行此检查。

设置环境变量 `CHECK_GISCUS=1` 可额外检查真实 giscus 服务的深浅主题与手机布局。这项检查将本次站点构建映射到预期 HTTPS 地址，仅在隔离浏览器中生效；不会发布文件或发送评论，也不依赖已登录的 GitHub 账户。

浏览器检查分别等待 HTML 文档解析（30 秒上限）与 Flutter 的 `pulselink-ready` 首帧信号、启动遮罩退出（90 秒上限），不使用全局网络静默作为就绪条件。`npm run test:browser-readiness` 验证请求挂起时仍能识别就绪，以及启动失败、刷新和 404 不会被误判为成功。检查失败会在 `build/qa/browser` 保存 `failure.json`、HTML 和截图，记录检查阶段、未完成请求、HTTP 错误及控制台消息；CI 会上传这份诊断资料。

## 路由与语言

使用 Flutter hash URL，直接刷新不会要求 GitHub Pages 重写任意路径：

- `/#/zh-CN`：首页。
- `/#/zh-CN/posts`：文章列表与搜索。
- `/#/ja/posts/segmeris-guide`：日文文章。
- `/#/en/projects/segmeris`：英文项目详情。
- `/#/zh-TW/friends`：繁体中文友链。
- `/#/de/about`：德文介绍与留言板。

支持简中、繁中、日语、德语、英语、法语、西班牙语、俄语、葡萄牙语（巴西用语）和意大利语。切换语言时保留当前页面和文章 ID。UI、两篇完整文章与六个项目详情都有对应翻译。

Hash 路由适合 Pages 的纯静态部署，但不能等同于每篇文章有独立预渲染 HTML。链接分享与刷新有效，搜索引擎收录和社交预览仍受 Flutter 客户端渲染限制。

## 内容维护

`assets/i18n/<语言>.json` 保存文案和结构化文章。每篇文章包含稳定的 `id`、分类、标题、摘要、章节与 `sources`。章节 `body` 支持 Markdown 段落、粗体、列表、表格、代码块、引用与 HTTPS 链接；原始 HTML 不执行。图片使用 `![说明](resource:assets/images/name.png "图注")`，图片文件还需在 pubspec.yaml 声明。新增文章时同步十种语言，保持 ID 相同；不要把发布时间、阅读量或个人经历当占位数据填写。

两篇文章分别分析 Segmeris 的任务阶段与验收条件，以及下载、HLS 组装、封装、编码的边界。每篇七节，提供独立验证命令与来源；项目资料链接固定到核实过的提交，FFmpeg 与 RFC 链接指向原始文档。文中的对照实验是验证方法，不是虚构的性能成绩。

流程图源文件放在 `content/diagrams/<id>-<语言>.mmd`，在章节上设置 `diagram: "<id>"`。`npm run diagrams` 生成深浅两套 PNG 并复制 Mermaid 源码到 `assets/diagrams`。图注沿用章节标题，读者可以放大、缩放和查看源码。新增图解需提供对应的十种语言源文件。渲染启用 strict 安全级别，不启用图节点脚本。

`assets/projects.json` 保存 Segmeris、ArcadiaPlus、RecurseX、Corduit、Courierust、PulseLink 的十语言简介、技术标签、三节分析与固定来源。集合按等高双列展示，手机自动单列，每个项目有独立详情路由。内容随发布打包，首次阅读不等待 GitHub API，也不会因限流留下空白。仓库最新状态仍以源链接为准。

`lib/content.dart` 维护 Lxns Network 与陶然友链。外链只接受 HTTPS。SVG 头像加载失败时使用本地图标。

## 评论

已配置仓库 `blueokanna/blueokanna.github.io`、Announcements 分类及其真实标识，配置文件为 `web/comments.json`。

- 文章使用 `pulselink/post/<文章ID>` 作为 giscus 的精确匹配关键词。第一次留言时由 giscus 创建对应 Discussion；改变语言不会拆分评论。
- 关于页留言板绑定现有 Discussion #1。
- 读者点击“加载评论”后才请求 giscus。通过 GitHub 登录留言，数据和管理权限留在 GitHub。
- `web/comments.html` 是 giscus 的隔离宿主页，主站 UI 仍由 Flutter 渲染。嵌入评论控件属于 giscus 自身，不冒称为原生 Material 组件。
- 外层 iframe 与 giscus 主题都保持透明。`tool/export_comment_themes_test.dart` 从实际 Flutter ColorScheme 导出 16 套配色的深浅 CSS，统一字体、按钮、输入框、边框和圆角。主题更新通过 giscus 的 setConfig 消息完成，不重新加载 iframe 或清空输入。
- 自定义 CSS 需要部署到 HTTPS 地址；HTTP 本地预览使用 giscus 内置主题。主题 CSS 随构建放在 `web/giscus`，发布前不能用旧线上资源验证新配色。
- iframe 调整高度与配置更新只接受来自对应窗口与预期来源的消息；拒绝任意外部主题地址。第三方服务异常时仍保留 GitHub 讨论入口。

## 字体、颜色与动效

Google Sans 与 Noto Sans SC / TC / JP 来自 Google Fonts 官方仓库，OFL 随资产发布。保留可变字重，针对维护中的文本、拉丁/西里尔字母和假名生成子集；修改正文后构建脚本会自动更新字形。来自远程仓库的额外字形可能由 Flutter 字体回退处理。

16 套种子色生成 Material 3 语义色，支持系统、浅色、深色模式，并保存浏览器偏好。Mocha Mousse、Peach Fuzz、Very Peri 参考潘通年度色方向，屏幕色值不是认证潘通色样。

界面使用 Material 3 卡片、按钮、菜单、搜索框、底部面板与胶囊式导航。装饰形状来自 `material_ui` 的 MaterialShapes 目录，通过 MaterialShapeBorder 的缓存形变匹配过渡。

Aurora 是应用层调度器：一个持续动画时钟、直接监听的 CustomPainter 与独立 RepaintBoundary。后台、暂停及系统减少动画会停止持续绘制；导航、主题和交互反馈使用 Flutter 的按需动画。首页形状和轨道使用 12 秒循环，项目徽记在同一时钟上形变；卡片的悬停和键盘焦点使用 Material 状态层与层级变化。顶部提供动效开关。没有修改 Flutter 引擎，也不承诺未经测量的性能提升百分比。

页面切换使用 Flutter 官方 `animations` 包的 Fade Through：320 毫秒内先退场、再入场，同时处理主动画与次级动画，避免透明页面的文字叠绘。导航栏和极光背景保留在公共外壳中；页面按 URL 路径区分身份，文章和语言切换也走同一转场。动画期间页面内容暂停点击和焦点访问，导航仍可连续切换。`test/navigation_test.dart` 逐帧检查正常切页、快速中断、返回、语言切换与减少动画设置。

启动页保留到文章目录与用户偏好加载完成、首个 Flutter 页面绘制后再退出，避免引擎启动完成和内容就绪之间闪出空白。HTML 启动页识别深浅偏好及减少动画设置。

## 模块

- `lib/app.dart`：路由、语言与根主题。
- `lib/ui/shell.dart`：导航、主题与语言控制。
- `lib/ui/pages.dart`：各页面与阅读交互。
- `lib/ui/project_views.dart`：项目集合与详情。
- `lib/ui/expressive.dart`：动态形状、卡片交互和间距约定。
- `lib/ui/rich_content.dart`：Markdown、图片与 Mermaid 图解阅读。
- `lib/ui/page_transition.dart`：页面进退场和过渡期间的交互边界。
- `lib/localization.dart`：语言与文章模型。
- `lib/preferences.dart`：语义主题和偏好持久化。
- `lib/motion.dart`：共享时钟和形状绘制。
- `lib/comments*`：评论平台桥接。
- `lib/services.dart`：GitHub 请求、缓存、超时与地址校验。

## 发布

仓库 Settings → Pages → Source 选择 GitHub Actions。推送 main 后工作流验证并上传 `build/web`；PR 只验证，不部署。CNAME 保持 `www.pulselink.top`。根目录历史构建文件不属于新工作流的发布输入。

站点不编译私密密钥。评论使用 giscus 的授权流程，项目介绍直接读取随站点发布的内容。首次访问需要下载 Flutter 引擎及字体，网络条件和设备性能仍影响实际加载与帧率。
