# PulseLink

Blue 的个人博客，使用 Flutter Web，发布到 GitHub Pages。

## 本地运行

项目使用 Flutter **3.47.9 stable**。CI 固定相同版本，并提交 pubspec.lock。

```sh
flutter pub get --enforce-lockfile
flutter run -d chrome
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release --base-href / --no-web-resources-cdn
```

产物位于 `build/web`。CanvasKit 随站点分发，不依赖公共渲染器 CDN。首次加载仍需下载 Flutter 引擎与字体；这不是轻量 HTML 博客，不能承诺任何网络条件下都秒开。

## 内容与结构

- `lib/app.dart`：响应式页面、主题、语言切换和阅读面板。
- `lib/content.dart`：技术笔记和友链；笔记描述本站实现，不伪造发布日期。
- `lib/motion.dart`：Aurora 动效时钟、绘制路径与统一过渡参数。
- `lib/services.dart`：GitHub 数据读取、会话缓存、外链校验。
- `web/`：启动页面、失败重试和资源清单。
- `test/site_test.dart`：链接校验、缓存与错误处理、三种宽度交互、减少动画。

添加友链时，在 `friends` 中追加 `FriendLink`，填写名称、HTTPS 地址、中英文简介和可选头像。已加入 Lxns Network 和陶然；陶然使用提供的 SVG 头像地址。头像不可用时显示本地图标。

技术笔记直接随应用打包，点击卡片打开阅读面板。项目列表读取 blueokanna 的公开 GitHub 仓库，筛除 fork 和 archived，展示最近更新的六个项目。请求超时或限流时明确显示重试入口；没有假统计或虚构项目兜底。M3U8 Downloader 的原有源码入口保留。

## 动效与渲染

Aurora 是应用层的绘制调度组件，不是修改过的 Flutter 引擎。一个 AnimationController 驱动背景与花瓣路径；CustomPainter 直接监听重绘，RepaintBoundary 隔离画布。没有全屏 BackdropFilter 或逐帧页面 setState。

系统减少动画、手动暂停和后台生命周期都会停止持续动画。导航与阅读过渡共用时长及曲线。Material 控件仍使用框架自身的焦点、悬停和按压反馈，不宣称全应用只有一个 Ticker。

尚未进行真实设备的 CPU/GPU、功耗或帧时间基准测试，因此不提供降低负载的百分比或稳定帧率承诺。可使用 Flutter DevTools 的 Performance 视图记录目标设备上的滚动与过渡帧时间。

## 发布

仓库 Settings → Pages → Source 选择 **GitHub Actions**。推送 `main` 后运行格式检查、静态分析、测试及 Release 构建，再通过官方 Pages artifact 工作流发布。PR 只构建验证，不发布。

自定义域名继续读取 `CNAME` 中的 `www.pulselink.top`，DNS 需要保持指向 GitHub Pages。`scripts/publish_web.ps1` 只验证和生成产物，不覆盖仓库根目录。历史根目录构建文件不作为新工作流的发布输入。

## 数据与安全边界

GitHub Pages 没有私密服务端。任何编译进浏览器代码的密钥都不能视为秘密。当前构建不接收 AI 密钥，并移除未使用、没有鉴权的代理示例与不可用的 AI 占位功能。如曾将真实密钥发布到静态产物，应在提供商处撤销并轮换。

外部导航仅接受无 userinfo 的 HTTPS URL。GitHub 数据与远程头像仍受第三方服务可用性影响。这里不进行 IP 定位，也不在失败时捏造天气。没有发布到线上的操作会由本地构建自动完成。
