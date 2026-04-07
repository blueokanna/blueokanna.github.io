param(
    [switch]$SkipPubGet,
    [switch]$SkipTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $projectRoot

$iconSource = Join-Path $projectRoot 'assets\icon.png'
if (-not (Test-Path $iconSource)) {
    throw "Missing source icon: $iconSource"
}

Add-Type -AssemblyName System.Drawing

function New-ResizedPng {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][int]$Size
    )

    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path $parent)) {
        New-Item -Path $parent -ItemType Directory -Force | Out-Null
    }

    $img = [System.Drawing.Image]::FromFile($Source)
    try {
        $bmp = New-Object System.Drawing.Bitmap $Size, $Size
        try {
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            try {
                $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $g.Clear([System.Drawing.Color]::Transparent)
                $g.DrawImage($img, 0, 0, $Size, $Size)
                $bmp.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
            }
            finally {
                $g.Dispose()
            }
        }
        finally {
            $bmp.Dispose()
        }
    }
    finally {
        $img.Dispose()
    }
}

Write-Host '[1/5] Generate icon derivatives from assets/icon.png'
$targets = @(
    @{ Path = 'web/icons/Icon-192.png'; Size = 192 },
    @{ Path = 'web/icons/Icon-512.png'; Size = 512 },
    @{ Path = 'web/icons/Icon-maskable-192.png'; Size = 192 },
    @{ Path = 'web/icons/Icon-maskable-512.png'; Size = 512 },
    @{ Path = 'web/favicon.png'; Size = 64 },
    @{ Path = 'icons/Icon-192.png'; Size = 192 },
    @{ Path = 'icons/Icon-512.png'; Size = 512 },
    @{ Path = 'icons/Icon-maskable-192.png'; Size = 192 },
    @{ Path = 'icons/Icon-maskable-512.png'; Size = 512 },
    @{ Path = 'favicon.png'; Size = 64 }
)

foreach ($t in $targets) {
    $dest = Join-Path $projectRoot $t.Path
    New-ResizedPng -Source $iconSource -Destination $dest -Size $t.Size
}

if (-not $SkipPubGet) {
    Write-Host '[2/5] flutter pub get'
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
}

if (-not $SkipTests) {
    Write-Host '[3/5] flutter test'
    flutter test
    if ($LASTEXITCODE -ne 0) { throw 'flutter test failed' }
}

Write-Host '[4/5] flutter build web --release --base-href /'
if (Test-Path 'build/web') {
    Remove-Item 'build/web' -Recurse -Force
}
flutter build web --release --base-href /
if ($LASTEXITCODE -ne 0) { throw 'flutter build web failed' }

Write-Host '[5/5] Publish build/web to repository root'
robocopy 'build/web' '.' /E /R:2 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
$robocopyExit = $LASTEXITCODE
if ($robocopyExit -ge 8) {
    throw "robocopy failed with exit code $robocopyExit"
}

if (-not (Test-Path $iconSource)) {
    throw "Source icon missing after publish: $iconSource"
}

Write-Host 'Publish completed successfully.'
