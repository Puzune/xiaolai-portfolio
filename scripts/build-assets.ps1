[CmdletBinding()]
param(
  [switch]$NoWatermark
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$outRoot = Join-Path $root "portfolio\assets"
$largeDir = Join-Path $outRoot "large"
$thumbDir = Join-Path $outRoot "thumbs"

New-Item -ItemType Directory -Force -Path $largeDir, $thumbDir | Out-Null
Add-Type -AssemblyName System.Drawing

$jpgCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
  Where-Object { $_.MimeType -eq "image/jpeg" }

function ConvertFrom-CodePoints([int[]]$codePoints) {
  return -join ($codePoints | ForEach-Object { [char]$_ })
}

function Save-Jpeg($bitmap, $path, $quality) {
  $encoder = New-Object System.Drawing.Imaging.EncoderParameters 1
  $encoder.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter `
    ([System.Drawing.Imaging.Encoder]::Quality), ([int64]$quality)
  $bitmap.Save($path, $jpgCodec, $encoder)
  $encoder.Dispose()
}

function Get-RegionLuminance($bitmap, $x, $y, $width, $height) {
  $x0 = [Math]::Max(0, [int]$x)
  $y0 = [Math]::Max(0, [int]$y)
  $x1 = [Math]::Min($bitmap.Width - 1, [int]($x + $width))
  $y1 = [Math]::Min($bitmap.Height - 1, [int]($y + $height))
  $sum = 0.0
  $count = 0
  for ($ix = 0; $ix -lt 6; $ix++) {
    for ($iy = 0; $iy -lt 4; $iy++) {
      $px = [int]($x0 + (($x1 - $x0) * ($ix + 0.5) / 6))
      $py = [int]($y0 + (($y1 - $y0) * ($iy + 0.5) / 4))
      $color = $bitmap.GetPixel($px, $py)
      $sum += 0.299 * $color.R + 0.587 * $color.G + 0.114 * $color.B
      $count++
    }
  }
  if ($count -eq 0) { return 255 }
  return $sum / $count
}

function Add-XiaolaiWatermark($bitmap, $graphics) {
  $shortSide = [Math]::Min($bitmap.Width, $bitmap.Height)
  if ($shortSide -lt 180) { return }

  $markHeight = [int][Math]::Round([Math]::Max(24, [Math]::Min(64, $shortSide * 0.055)))
  $iconSize = [int][Math]::Round($markHeight * 0.74)
  $gap = [int][Math]::Round($markHeight * 0.24)
  $margin = [int][Math]::Round([Math]::Max(12, [Math]::Min(38, $shortSide * 0.028)))
  $fontSize = [Math]::Max(11, $markHeight * 0.44)

  $font = New-Object System.Drawing.Font("Segoe UI", $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $format = New-Object System.Drawing.StringFormat
  try {
    $text = "XIAOLAI"
    $textSize = $graphics.MeasureString($text, $font)
    $textWidth = [int][Math]::Ceiling($textSize.Width)
    $textHeight = [int][Math]::Ceiling($textSize.Height)
    $totalWidth = $iconSize + $gap + $textWidth
    $totalHeight = [Math]::Max($iconSize, $textHeight)
    $x = [int]($bitmap.Width - $margin - $totalWidth)
    $y = [int]($bitmap.Height - $margin - $totalHeight)
    if ($x -lt $margin) { $x = $margin }
    if ($y -lt $margin) { $y = $margin }

    $luminance = Get-RegionLuminance $bitmap ($x - 8) ($y - 8) ($totalWidth + 16) ($totalHeight + 16)
    $useDarkMark = $luminance -gt 148

    if ($useDarkMark) {
      $main = [System.Drawing.Color]::FromArgb(158, 24, 23, 21)
      $accent = [System.Drawing.Color]::FromArgb(166, 184, 101, 69)
      $dot = [System.Drawing.Color]::FromArgb(168, 94, 134, 122)
      $shadow = [System.Drawing.Color]::FromArgb(58, 255, 255, 255)
    } else {
      $main = [System.Drawing.Color]::FromArgb(190, 255, 255, 255)
      $accent = [System.Drawing.Color]::FromArgb(190, 245, 191, 155)
      $dot = [System.Drawing.Color]::FromArgb(195, 166, 214, 196)
      $shadow = [System.Drawing.Color]::FromArgb(92, 0, 0, 0)
    }

    $shadowPen = New-Object System.Drawing.Pen($shadow, [Math]::Max(1.0, $iconSize * 0.09))
    $mainPen = New-Object System.Drawing.Pen($main, [Math]::Max(1.0, $iconSize * 0.09))
    $accentPen = New-Object System.Drawing.Pen($accent, [Math]::Max(1.0, $iconSize * 0.1))
    $textShadowBrush = New-Object System.Drawing.SolidBrush($shadow)
    $textBrush = New-Object System.Drawing.SolidBrush($main)
    $dotBrush = New-Object System.Drawing.SolidBrush($dot)
    try {
      $iconX = $x
      $iconY = [int]($y + (($totalHeight - $iconSize) / 2))
      $textX = $iconX + $iconSize + $gap
      $textY = [int]($y + (($totalHeight - $textHeight) / 2))
      $dotSize = [Math]::Max(4, [int]($iconSize * 0.23))

      $graphics.DrawEllipse($shadowPen, $iconX + 1, $iconY + 1, $iconSize, $iconSize)
      $graphics.DrawLine($shadowPen, $iconX + [int]($iconSize * 0.23) + 1, $iconY + [int]($iconSize * 0.77) + 1, $iconX + [int]($iconSize * 0.77) + 1, $iconY + [int]($iconSize * 0.23) + 1)
      $graphics.DrawString($text, $font, $textShadowBrush, $textX + 1, $textY + 1, $format)

      $graphics.DrawEllipse($mainPen, $iconX, $iconY, $iconSize, $iconSize)
      $graphics.DrawLine($accentPen, $iconX + [int]($iconSize * 0.23), $iconY + [int]($iconSize * 0.77), $iconX + [int]($iconSize * 0.77), $iconY + [int]($iconSize * 0.23))
      $graphics.FillEllipse($dotBrush, $iconX + [int]($iconSize * 0.6), $iconY + [int]($iconSize * 0.15), $dotSize, $dotSize)
      $graphics.DrawString($text, $font, $textBrush, $textX, $textY, $format)
    } finally {
      $shadowPen.Dispose()
      $mainPen.Dispose()
      $accentPen.Dispose()
      $textShadowBrush.Dispose()
      $textBrush.Dispose()
      $dotBrush.Dispose()
    }
  } finally {
    $font.Dispose()
    $format.Dispose()
  }
}

function Resize-Image($src, $dest, $maxSide, $quality) {
  $img = [System.Drawing.Image]::FromFile($src)
  try {
    $scale = [Math]::Min($maxSide / $img.Width, $maxSide / $img.Height)
    if ($scale -gt 1) { $scale = 1 }
    $width = [Math]::Max(1, [int]($img.Width * $scale))
    $height = [Math]::Max(1, [int]($img.Height * $scale))
    $bitmap = New-Object System.Drawing.Bitmap $width, $height
    try {
      $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
      try {
        $graphics.Clear([System.Drawing.Color]::White)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $graphics.DrawImage($img, 0, 0, $width, $height)
        if (-not $NoWatermark) {
          Add-XiaolaiWatermark $bitmap $graphics
        }
      } finally {
        $graphics.Dispose()
      }
      Save-Jpeg $bitmap $dest $quality
    } finally {
      $bitmap.Dispose()
    }
  } finally {
    $img.Dispose()
  }
}

$folderMap = @{
  (ConvertFrom-CodePoints @(20135,21697,25928,26524,35774,35745,20316,21697)) = "render"
  (ConvertFrom-CodePoints @(28023,25253,35774,35745,20316,21697)) = "poster"
  (ConvertFrom-CodePoints @(19977,32500,24314,27169,20316,21697)) = "model"
  (ConvertFrom-CodePoints @(25163,24037,21046,20316,20316,21697)) = "craft"
  (ConvertFrom-CodePoints @(25163,32472,20316,21697,38598)) = "sketch"
}

$manifest = @()

Get-ChildItem -LiteralPath $root -Directory |
  Where-Object { $folderMap.ContainsKey($_.Name) } |
  Sort-Object Name |
  ForEach-Object {
    $code = $folderMap[$_.Name]
    $index = 1

    Get-ChildItem -LiteralPath $_.FullName -File |
      Sort-Object Name |
      ForEach-Object {
        $id = "{0}-{1:D2}" -f $code, $index
        $large = Join-Path $largeDir ($id + ".jpg")
        $thumb = Join-Path $thumbDir ($id + ".jpg")

        Resize-Image $_.FullName $large 1800 86
        Resize-Image $_.FullName $thumb 720 82

        $manifest += [PSCustomObject]@{
          id = $id
          title = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
          folder = $_.Directory.Name
          large = "assets/large/$id.jpg"
          thumb = "assets/thumbs/$id.jpg"
          source = $_.FullName.Replace($root.Path + "\", "")
        }

        $index++
      }
  }

$manifest |
  ConvertTo-Json -Depth 4 |
  Set-Content -LiteralPath (Join-Path $outRoot "manifest.generated.json") -Encoding UTF8

Write-Host "Generated $($manifest.Count) portfolio images."
