$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$outRoot = Join-Path $root "portfolio\assets"
$largeDir = Join-Path $outRoot "large"
$thumbDir = Join-Path $outRoot "thumbs"

New-Item -ItemType Directory -Force -Path $largeDir, $thumbDir | Out-Null
Add-Type -AssemblyName System.Drawing

$jpgCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
  Where-Object { $_.MimeType -eq "image/jpeg" }

function Save-Jpeg($bitmap, $path, $quality) {
  $encoder = New-Object System.Drawing.Imaging.EncoderParameters 1
  $encoder.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter `
    ([System.Drawing.Imaging.Encoder]::Quality), ([int64]$quality)
  $bitmap.Save($path, $jpgCodec, $encoder)
  $encoder.Dispose()
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
        $graphics.DrawImage($img, 0, 0, $width, $height)
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
  "产品效果设计作品" = "render"
  "海报设计作品" = "poster"
  "三维建模作品" = "model"
  "手工制作作品" = "craft"
  "手绘作品集" = "sketch"
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
