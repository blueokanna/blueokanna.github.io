# Blue's PulseLink Blog

A complete Flutter Web rebuild of the personal site for Blueokanna, designed as a production-grade Material Design 3 experience for GitHub Pages.

Live site: https://www.pulselink.top/

## Overview

This repository now uses Flutter Web as the primary rendering layer.

The site is built around these goals:
- Web-only Flutter architecture
- Full Material Design 3 visual system
- Responsive layouts for phone, tablet, and desktop
- Wise-inspired clarity, spacing, and visual confidence
- Rich 2D and pseudo-3D motion without jarring animation resets
- Holiday-aware and weather-aware UI details
- A personal portfolio/blog presentation instead of a generic landing page

## Experience Highlights

Current implementation includes:
- Material 3 theme system with light and dark modes
- Responsive hero, about, capability, project, and contact sections
- Animated ambient background painter
- Holiday-aware accent palette and festive visual treatment
- Weather badge fed by IP geolocation plus Open-Meteo
- GitHub profile and repository data fed by GitHub API
- 3D-style icon surfaces and layered cards inspired by financial product UI
- Mobile bottom navigation and desktop glass top bar
- Back-to-top affordance and section-aware navigation state
- Network avatar fallback so the UI and tests remain stable when external image loading fails

## Tech Stack

- Flutter 3.43 beta
- Dart 3.12 beta
- Material Design 3
- http
- url_launcher

## Project Structure

- [lib/main.dart](lib/main.dart): Flutter entry point
- [lib/app.dart](lib/app.dart): Main application UI, animations, sections, data loading, painters
- [web/index.html](web/index.html): Flutter Web shell and boot splash
- [test/widget_test.dart](test/widget_test.dart): Basic shell render test
- [assets](assets): Brand and decorative assets used by the app
- [build/web](build/web): Generated Flutter Web release output

## Local Development

Install dependencies:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Run locally in Chrome:

```bash
flutter run -d chrome
```

Build release web output:

```bash
flutter build web --release --base-href /
```

## Deployment Model

This repository is configured for GitHub Pages using the repository root as the published site source.

Source files remain in the normal Flutter structure:
- [lib](lib)
- [web](web)
- [assets](assets)

Deployable artifacts are copied from [build/web](build/web) into the repository root after each release build. That is why root-level files such as [index.html](index.html), [main.dart.js](main.dart.js), [flutter.js](flutter.js), [manifest.json](manifest.json), and [flutter_bootstrap.js](flutter_bootstrap.js) exist alongside the Flutter source tree.

Recommended release flow:

```bash
flutter pub get
flutter test
flutter build web --release --base-href /
Copy-Item -Path "build\web\*" -Destination "." -Recurse -Force
```

Custom domain is preserved through [CNAME](CNAME):
- `www.pulselink.top`

## Notes

- The build currently performs a WASM dry run successfully. A future deployment can evaluate `flutter build web --wasm` once the target browsers and hosting path are fully validated.
- Some content is loaded from live network endpoints. The app contains fallbacks for test and runtime resilience, but the experience is best when GitHub and weather endpoints are reachable.
- The repository may contain additional icon asset packs for future iteration of festive or product-style surfaces.

## Next Iteration Ideas

- Add article/content management for real blog posts
- Replace live GitHub calls with a cached build-time JSON layer for faster first paint
- Add locale switching for Chinese and English copy
- Add a WebAssembly-powered interactive visual or data module
- Add screenshot-based visual regression checks for responsive layouts
