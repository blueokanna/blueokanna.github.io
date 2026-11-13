Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location -LiteralPath $projectRoot
flutter pub get --enforce-lockfile
if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed' }
python -m pip install --upgrade --target .font-tools -r scripts/requirements-fonts.txt
if ($LASTEXITCODE -ne 0) { throw 'Font tooling installation failed' }
python scripts/build_posts.py
if ($LASTEXITCODE -ne 0) { throw 'Article compilation failed' }
python -m unittest discover -s test -p '*_test.py'
if ($LASTEXITCODE -ne 0) { throw 'Article tests failed' }
python scripts/prepare_fonts.py
if ($LASTEXITCODE -ne 0) { throw 'Font preparation failed' }
npm ci --ignore-scripts
if ($LASTEXITCODE -ne 0) { throw 'Diagram dependencies failed' }
npm run companion:build
if ($LASTEXITCODE -ne 0) { throw '3D build failed' }
npm run diagrams
if ($LASTEXITCODE -ne 0) { throw 'Diagram preparation failed' }
flutter test tool/export_comment_themes_test.dart
if ($LASTEXITCODE -ne 0) { throw 'Comment theme export failed' }
dart format --output=none --set-exit-if-changed lib test tool
if ($LASTEXITCODE -ne 0) { throw 'Formatting check failed. Run dart format lib test tool, then retry.' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'Analysis failed' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
npm test
if ($LASTEXITCODE -ne 0) { throw 'Comment integration tests failed' }
flutter build web --release --base-href / --no-web-resources-cdn
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
python scripts/finalize_web.py
if ($LASTEXITCODE -ne 0) { throw 'Release finalization failed' }
npm run test:browser
if ($LASTEXITCODE -ne 0) { throw 'Browser checks failed' }
npm run test:browser-readiness
if ($LASTEXITCODE -ne 0) { throw 'Browser readiness regression checks failed' }
Copy-Item -LiteralPath (Join-Path $projectRoot 'CNAME') -Destination (Join-Path $projectRoot 'build/web/CNAME') -Force
npm run test:companion
if ($LASTEXITCODE -ne 0) { throw "3D browser verification failed" }
Write-Host 'Verified output: build/web. Push main to deploy using GitHub Actions.'
