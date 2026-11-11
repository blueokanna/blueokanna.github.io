# PulseLink

Blue 的 Flutter Web 博客：独立文章、项目详情、友链和 GitHub Discussions 留言。部署在 GitHub Pages，正文随应用发布，不依赖在线内容生成。

## 开发与验证

固定 Flutter 3.47.9 / Dart 3.13.7。依赖使用提交的 pubspec.lock。

```sh
flutter pub get --enforce-lockfile
python -m pip install -r scripts/requirements-fonts.txt
python scripts/prepare_fonts.py
dart format lib test tool
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
node --test test/comments_test.mjs
flutter build web --release --base-href / --no-web-resources-cdn
```

Windows 可运行 `./scripts/publish_web.ps1`，依次检查字体、格式、分析、测试和构建。字体缓存位于 `.font-cache`，不参与部署。首次准备字体需要网络；下载内容有固定提交地址与 SHA-256 校验。

`flutter test tool/render_preview_test.dart` 可生成 `build/qa/desktop.png` 和 `mobile.png`，使用真实字体检查 Flutter 排版。它不是浏览器截图，也不测量浏览器帧率。

## 路由与语言

使用 Flutter hash URL，直接刷新不会要求 GitHub Pages 重写任意路径：

- `/#/zh-CN`：首页。
- `/#/zh-CN/posts`：文章列表与搜索。
- `/#/ja/posts/segmeris-guide`：日文文章。
- `/#/en/projects/segmeris`：英文项目详情。
- `/#/zh-TW/friends`：繁体中文友链。
- `/#/de/about`：德文介绍与留言板。

支持简中、繁中、日语、德语、英语、法语、西班牙语、俄语、葡萄牙语（巴西用语）和意大利语。切换语言时保留当前页面和文章 ID。UI 与两篇完整文章都有对应翻译；GitHub 实时仓库简介保持作者的原文。

Hash 路由适合 Pages 的纯静态部署，但不能等同于每篇文章有独立预渲染 HTML。链接分享与刷新有效，搜索引擎收录和社交预览仍受 Flutter 客户端渲染限制。

## 内容维护

`assets/i18n/<语言>.json` 保存文案和结构化文章。每篇文章包含稳定的 `id`、分类、标题、摘要与章节。新增文章时同步十种语言，保持 ID 相同；不要把发布时间、阅读量或个人经历当占位数据填写。

目前文章是依据 Segmeris 文档整理的上手指南和音视频处理分享，文章末尾保留原始资料入口。旧名称已更新为 Segmeris，精选项目始终随站点展示，即使 GitHub API 限流也不会留下空白项目区域。

`lib/content.dart` 维护 Lxns Network 与陶然友链。外链只接受 HTTPS。SVG 头像加载失败时使用本地图标。

## 评论

已配置仓库 `blueokanna/blueokanna.github.io`、Announcements 分类及其真实标识，配置文件为 `web/comments.json`。

- 文章使用 `pulselink/post/<文章ID>` 作为 giscus 的精确匹配关键词。第一次留言时由 giscus 创建对应 Discussion；改变语言不会拆分评论。
- 关于页留言板绑定现有 Discussion #1。
- 读者点击“加载评论”后才请求 giscus。通过 GitHub 登录留言，数据和管理权限留在 GitHub。
- `web/comments.html` 是 giscus 的隔离宿主页，主站 UI 仍由 Flutter 渲染。嵌入评论控件属于 giscus 自身，不冒称为原生 Material 组件。
- iframe 调整高度只接受来自对应窗口与预期来源的消息。第三方服务异常时仍保留 GitHub 讨论入口。

## 字体、颜色与动效

Google Sans 与 Noto Sans SC / TC / JP 来自 Google Fonts 官方仓库，OFL 随资产发布。保留可变字重，针对维护中的文本、拉丁/西里尔字母和假名生成子集；修改正文后构建脚本会自动更新字形。来自远程仓库的额外字形可能由 Flutter 字体回退处理。

16 套种子色生成 Material 3 语义色，支持系统、浅色、深色模式，并保存浏览器偏好。Mocha Mousse、Peach Fuzz、Very Peri 参考潘通年度色方向，屏幕色值不是认证潘通色样。

界面使用 Material 3 卡片、按钮、菜单、搜索框、底部面板与胶囊式导航。装饰形状来自 `material_ui` 的 MaterialShapes 目录，通过 MaterialShapeBorder 的缓存形变匹配过渡。

Aurora 是应用层调度器：一个持续动画时钟、直接监听的 CustomPainter 与独立 RepaintBoundary。后台、暂停及系统减少动画会停止持续绘制；导航、主题和交互反馈使用 Flutter 的按需动画。没有修改 Flutter 引擎，也不承诺未经测量的性能提升百分比。

## 模块

- `lib/app.dart`：路由、语言与根主题。
- `lib/ui/shell.dart`：导航、主题与语言控制。
- `lib/ui/pages.dart`：各页面与阅读交互。
- `lib/localization.dart`：语言与文章模型。
- `lib/preferences.dart`：语义主题和偏好持久化。
- `lib/motion.dart`：共享时钟和形状绘制。
- `lib/comments*`：评论平台桥接。
- `lib/services.dart`：GitHub 请求、缓存、超时与地址校验。

## 发布

仓库 Settings → Pages → Source 选择 GitHub Actions。推送 main 后工作流验证并上传 `build/web`；PR 只验证，不部署。CNAME 保持 `www.pulselink.top`。根目录历史构建文件不属于新工作流的发布输入。

站点不编译私密密钥。评论使用 giscus 的授权流程，项目读取 GitHub 公开 API。首次访问需要下载 Flutter 引擎及字体，网络条件和设备性能仍影响实际加载与帧率。
