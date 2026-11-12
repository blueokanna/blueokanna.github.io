# PulseLink

Blue 的 Flutter Web 博客：独立文章、项目详情、友链和 GitHub Discussions 留言。部署在 GitHub Pages，正文随应用发布，不依赖在线内容生成。

## 开发与验证

固定 Flutter 3.47.9 / Dart 3.13.7，构建图解使用 Node 22.13+。Dart 和 Node 依赖分别由 pubspec.lock、package-lock.json 固定。

```sh
flutter pub get --enforce-lockfile
python -m pip install -r scripts/requirements-fonts.txt
python scripts/build_posts.py
python -m unittest discover -s test -p "*_test.py"
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

`assets/i18n/<语言>.json` 保存文案和内置结构化文章。每篇文章包含稳定的 `id`、分类、标题、摘要、章节与 `sources`。章节 `body` 支持 Markdown 段落、粗体、列表、表格、代码块、引用与 HTTPS 链接；原始 HTML 不执行。图片使用 `![说明](resource:assets/images/name.png "图注")`，图片文件还需在 pubspec.yaml 声明。已翻译文章保持相同 ID；在线新文章可先发布一种语言，再逐步补充真实翻译。不要把发布时间、阅读量或个人经历当占位数据填写。

两篇文章分别分析 Segmeris 的任务阶段与验收条件，以及下载、HLS 组装、封装、编码的边界。简体中文版补充了任务排障记录、多音轨映射与逐项验收，其他语言保留原有七节版本。项目资料链接固定到核实过的提交，FFmpeg 与 RFC 链接指向原始文档。文中的对照实验是验证方法，不是虚构的性能成绩。

流程图源文件放在 `content/diagrams/<id>-<语言>.mmd`，在章节上设置 `diagram: "<id>"`。`npm run diagrams` 生成深浅两套 PNG 并复制 Mermaid 源码到 `assets/diagrams`。图注沿用章节标题，读者可以放大、缩放和查看源码。新增图解需提供对应的十种语言源文件。渲染启用 strict 安全级别，不启用图节点脚本。

`assets/projects.json` 保存 Segmeris、ArcadiaPlus、RecurseX、Corduit、Courierust、PulseLink 的十语言简介、技术标签、三节分析与固定来源。集合按等高双列展示，手机自动单列，每个项目有独立详情路由。内容随发布打包，首次阅读不等待 GitHub API，也不会因限流留下空白。仓库最新状态仍以源链接为准。

`lib/content.dart` 维护 Lxns Network 与陶然友链。外链只接受 HTTPS。SVG 头像加载失败时使用本地图标。

## 在线写作

导航中的账户按钮打开 `/#/zh-CN/studio`。编辑器支持 Markdown 阅读预览、本机草稿恢复、新建文章和读取远程版本后更新文章。当前编辑器说明使用中文；文章语言可独立选择。

1. 在 GitHub 创建 fine-grained personal access token，只授权 `blueokanna.github.io`，设置有效期并授予 `Contents: Read and write`。
2. 在编辑器中验证令牌。身份来自 GitHub `/user`，发布入口还核对仓库所有者的数值 ID 和 push 权限；只有 `blueokanna` 能使用发布操作。实际写入权限由 GitHub 执行。
3. 填写稳定的文章 ID、标题、摘要、分类和 Markdown。文章 ID 是 URL 的组成部分，发布后尽量保持不变。
4. 检查预览后发布。文章保存为 `content/posts/<语言>/<ID>.md`，提交到 `main`，随后由 Actions 构建和部署。提交成功与部署成功是两个状态，编辑器提供 Actions 链接。

这是令牌登录，不是 OAuth 跳转登录。纯静态站点不保存 OAuth client secret，也不将令牌写入 Cookie、浏览器存储、URL 或仓库。令牌只保留在应用内存，刷新或退出即清除；草稿会保存在当前浏览器，不能代替仓库备份。访客评论沿用 giscus 的 GitHub OAuth。

文章头部使用 `---` 包围的一行 JSON 元数据，这是 YAML 的合法子集；正文保留完整 Markdown。`scripts/build_posts.py` 校验路径、元数据和 128 KiB 正文上限，再生成 `assets/posts.json`。构建脚本必须在字体子集生成前执行。新文章只进入所选语言，不能为了凑齐翻译而复制正文。在线文章与内置文章 ID 相同时，在该语言下覆盖内置版本。

更新必须携带读取时的文件 SHA。GitHub 返回冲突时，编辑器不会自动覆盖：先复制未提交的正文，再读取远程版本并合并。网络超时后也先检查远程状态，避免把未收到响应误判为未提交。分支保护、令牌审批或仓库规则仍可能拒绝直接写入，需要遵循仓库的真实权限设置。

鉴权与发布协议测试使用隔离的 HTTP mock，覆盖非站主拒绝、所有者 ID 与权限核验、SHA 冲突、退出后的延迟响应和 UTF-8 编解码；它们不会向真实仓库写测试文章。

接口依据：[GitHub Contents API](https://docs.github.com/en/rest/repos/contents)、[OAuth 授权流程](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)。令牌创建和撤销始终在 GitHub 的账户设置中完成。

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

Aurora 是应用层调度器：一个持续动画时钟、直接监听的 CustomPainter 与独立 RepaintBoundary。后台、暂停及系统减少动画会停止持续绘制；导航、主题和交互反馈使用 Flutter 的按需动画。背景轮廓、六颗卫星和项目徽记共享 12 秒相位，各自进行连续形变。项目插画区分波形、轨道和路由，卡片提供圆角变化、按压弹簧和 Material 状态层。手机上的动效开关位于外观面板；桌面保留快捷按钮。没有修改 Flutter 引擎，也不承诺未经测量的性能提升百分比。

吉祥物名称是「蓝色大肥鱼」。`assets/mascot/` 中的透明 PNG 根据用户提供的 DeepSeek Q版正面图和三视图制作，保留长卷发、蓝色渐变、蕾丝头饰、鲸鱼围裙和金色裙摆纹样，替换了此前的几何矢量人物。默认、招手、阅读使用同一角色的独立素材；呼吸、视差和舞动只对整张素材施加轻微变换，不再重画脸和服装。姿态图按需加载，解码宽度限制为 640px，切换时保留上一张已加载图片，再用 Fade Through 过渡，避免加载空白和双重面孔。持续运动读取 Aurora；减少动画模式停止位移并直接切换。素材处理方式和提示词保存在 `assets/mascot/provenance.json`，不宣称生成结果是原图的逐像素复制。首页直接互动，阅读页面可通过按钮唤出；触屏和键盘都有操作入口。角色未连接聊天模型。

页面切换使用 Flutter 官方 `animations` 包的 Fade Through：320 毫秒内先退场、再入场，同时处理主动画与次级动画，避免透明页面的文字叠绘。导航栏和极光背景保留在公共外壳中；页面按 URL 路径区分身份，文章和语言切换也走同一转场。动画期间页面内容暂停点击和焦点访问，导航仍可连续切换。`test/navigation_test.dart` 逐帧检查正常切页、快速中断、返回、语言切换与减少动画设置。

启动页保留到文章目录与用户偏好加载完成、首个 Flutter 页面绘制后再退出，避免引擎启动完成和内容就绪之间闪出空白。HTML 启动页识别深浅偏好及减少动画设置。

## 模块

- `lib/app.dart`：路由、语言与根主题。
- `lib/ui/shell.dart`：导航、主题与语言控制。
- `lib/ui/pages.dart`：各页面与阅读交互。
- `lib/ui/project_views.dart`：项目集合与详情。
- `lib/ui/expressive.dart`：动态形状、卡片交互和间距约定。
- `lib/ui/mascot.dart`：蓝色大肥鱼的素材加载、动作状态与显示过渡。
- `lib/ui/studio.dart`：Markdown 编辑、草稿恢复与发布交互。
- `lib/publishing.dart`：GitHub 身份、权限和带 SHA 的内容提交。
- `scripts/build_posts.py`：仓库 Markdown 的构建期校验与打包。
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
