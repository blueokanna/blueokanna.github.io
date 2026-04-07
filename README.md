# Blue的PulseLink博客

基于 **Flutter Web** 和 **Material Design 3 Expressive** 完全重建的个人博客，部署在 GitHub Pages。

在线访问：[https://www.pulselink.top/](https://www.pulselink.top/)

## 概述

本仓库使用 Flutter Web 作为唯一渲染层，设计风格深度参考 Wise 平台的产品级美学。

核心目标：

- **纯 Flutter Web 架构** — 不依赖 HTML/CSS/JS 手写页面
- **Material Design 3 Expressive** — 全面使用 M3 设计系统，包括 squircle 形状、弹性动画、自适应色彩
- **中英双语** — 一键切换中文与英文
- **实时博客/快讯聚合** — 多源拉取最新技术内容（DEV/HN/GitHub Release/GitHub Activity），含缓存与兜底
- **AI 对话助手** — 内嵌 AI 聊天面板，支持实时问答
- **响应式布局** — 手机、平板、桌面完美适配，参考 Wise 的断点设计
- **丝滑动画** — 弹性曲线（easeOutBack）、MD3 图标轨道浮动、渐入动效
- **天气感知** — 基于 IP 定位自动获取当前城市天气
- **节日主题** — 自动识别春节、圣诞、中秋等节日并调整色调
- **MD3 图标系统** — 统一 Material Design 3 图标语言与表达性动效

## 功能亮点

| 功能 | 描述 |
| --- | --- |
| 🌐 双语切换 | 顶栏一键切换中/英文，所有文案同步更新 |
| 📰 实时博客快讯 | 自动聚合多源最新技术内容，支持刷新与异常兜底 |
| 💬 AI 助手 | 侧边 AI 对话面板，支持多轮对话 |
| 🎨 M3 Expressive | squircle 卡片、弹性动画、自适应色彩 |
| 📱 完美响应式 | 手机/平板/桌面三档适配 |
| 🌤️ 天气感知 | 自动获取地理位置和实时天气 |
| 🎄 节日主题 | 自动识别节日并切换色调和图标 |
| 🧩 MD3 图标 | 统一 Material Design 3 图标系统 |
| ⭐ GitHub 数据 | 实时拉取仓库和 Star 数据 |
| 🔐 API 安全 | API 密钥通过构建参数注入，不存储在代码中 |

## 技术栈

- **Flutter** 3.43 beta (Dart 3.12)
- **Material Design 3** (Expressive)
- **智谱清言 GLM-4-Flash** — AI 内容生成与对话
- **http** — 网络请求
- **url_launcher** — 外部链接
- **Open-Meteo API** — 天气数据
- **GitHub API** — 仓库数据
- **ipapi.co** — IP 地理位置

## 项目结构

```text
├── lib/
│   ├── main.dart         # 入口
│   ├── app.dart          # 主应用 UI、动画、布局
│   ├── l10n.dart         # 中英双语本地化
│   └── services.dart     # 服务层（天气/GitHub/实时博客聚合）+ 数据模型
├── web/
│   └── index.html        # Flutter Web 宿主页（M3 Expressive 加载动画）
├── test/
│   └── widget_test.dart  # 基础渲染测试
├── assets/
│   └── icon.png          # 应用图标唯一源文件（自动生成 web/icons 与 favicon）
├── CNAME                 # 自定义域名 (www.pulselink.top)
└── pubspec.yaml          # 包配置
```

## 智谱 AI 配置

API 密钥 **不存储在代码中**，而是通过构建参数注入：

```bash
# 本地开发
flutter run -d chrome --dart-define=ZHIPU_API_KEY=你的密钥

# 发布构建
flutter build web --release --base-href / --dart-define=ZHIPU_API_KEY=你的密钥
```

### GitHub Actions 配置

1. 在仓库 Settings → Secrets → Actions 中添加 `ZHIPU_API_KEY`
2. 在工作流中使用：

```yaml
- run: flutter build web --release --base-href / --dart-define=ZHIPU_API_KEY=${{ secrets.ZHIPU_API_KEY }}
```

## 本地开发

```bash
# 安装依赖
flutter pub get

# 静态分析
flutter analyze

# 运行测试
flutter test

# 本地调试（Chrome）
flutter run -d chrome

# 发布构建
flutter build web --release --base-href /
```

## 部署模型

本仓库使用 GitHub Pages 从仓库根目录提供站点服务。

源码保持标准 Flutter 结构（`lib/`、`web/`、`assets/`），构建产物从 `build/web` 复制到仓库根目录。

推荐发布流程：

```bash
flutter pub get
flutter test
flutter build web --release --base-href / --dart-define=ZHIPU_API_KEY=${{ secrets.ZHIPU_API_KEY }}
Copy-Item -Path "build\web\*" -Destination "." -Recurse -Force
```

生产环境推荐一键发布（防止遗漏字体/资产拷贝）：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/publish_web.ps1
```

自定义域名通过 `CNAME` 文件保持：`www.pulselink.top`

## 设计理念

- **Wise 风格** — 干净、自信、大量留白、清晰的视觉层次
- **M3 Expressive** — 有机形状（squircle）、弹性运动、表达性色彩
- **心理学优先** — 节奏感、信任信号、渐进式信息呈现
- **零黑点** — 移除背景画布中的点阵网格，保持纯净的渐变氛围
