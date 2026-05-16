$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$errors = New-Object System.Collections.Generic.List[string]

function Add-Error($message) {
  $errors.Add($message) | Out-Null
}

function Test-File($relativePath) {
  $path = Join-Path $root $relativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Error "Missing file: $relativePath"
  }
}

Test-File "index.html"
Test-File "styles.css"
Test-File "data.js"
Test-File "app.js"
Test-File "favicon.svg"
Test-File ".nojekyll"
Test-File "404.html"
Test-File "robots.txt"

$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
  & $node.Source --check (Join-Path $root "data.js") | Out-Null
  & $node.Source --check (Join-Path $root "app.js") | Out-Null
} else {
  Write-Warning "Node.js was not found; skipped JavaScript syntax checks."
}

$data = Get-Content -LiteralPath (Join-Path $root "data.js") -Raw -Encoding UTF8
$assetRefs = [regex]::Matches($data, "assets/(?:large|thumbs)/[^""']+\.jpg") |
  ForEach-Object { $_.Value } |
  Sort-Object -Unique

foreach ($asset in $assetRefs) {
  $path = Join-Path $root ($asset -replace "/", "\")
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Error "Missing asset referenced in data.js: $asset"
  }
}

$projectCount = ([regex]::Matches($data, "id:\s*""[a-z0-9-]+"",\s*\r?\n\s*title:")).Count
$archiveCount = ([regex]::Matches($data, "thumb:\s*""assets/thumbs/")).Count

if ($archiveCount -lt 1) {
  Add-Error "No archive assets found in data.js."
}

if ($assetRefs.Count -lt ($archiveCount * 2)) {
  Add-Error "Some archive entries may be missing thumb or large image references."
}

$html = Get-Content -LiteralPath (Join-Path $root "index.html") -Raw -Encoding UTF8
$localRefs = [regex]::Matches($html, "(?:href|src)=""([^""]+)""") |
  ForEach-Object { $_.Groups[1].Value } |
  Where-Object {
    $_ -and
    $_ -notmatch "^(#|https?:|mailto:)" -and
    $_ -ne ""
  }

foreach ($ref in $localRefs) {
  $cleanRef = $ref.Split("?")[0]
  $path = Join-Path $root ($cleanRef -replace "/", "\")
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Error "Missing local reference in index.html: $ref"
  }
}

if ($errors.Count -gt 0) {
  Write-Host "Portfolio validation failed:" -ForegroundColor Red
  $errors | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
  exit 1
}

Write-Host "Portfolio validation passed." -ForegroundColor Green
Write-Host "Archive entries: $archiveCount"
Write-Host "Referenced image files: $($assetRefs.Count)"
