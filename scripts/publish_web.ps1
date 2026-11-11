Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location -LiteralPath $projectRoot
flutter pub get --enforce-lockfile
if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed' }
dart format --output=none --set-exit-if-changed lib test
if ($LASTEXITCODE -ne 0) { throw 'Formatting check failed. Run dart format lib test, then retry.' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'Analysis failed' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
flutter build web --release --base-href / --no-web-resources-cdn
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
Copy-Item -LiteralPath (Join-Path $projectRoot 'CNAME') -Destination (Join-Path $projectRoot 'build/web/CNAME') -Force
Write-Host 'Verified output: build/web. Push main to deploy using GitHub Actions.'
