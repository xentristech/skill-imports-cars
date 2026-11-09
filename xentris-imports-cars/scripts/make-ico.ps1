param([string]$Png, [string]$Out, [switch]$Round)
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Image]::FromFile($Png)
$sizes = 16,20,24,32,40,48,64,96,128,256
$entries = @()
foreach ($s in $sizes) {
  $bmp = New-Object System.Drawing.Bitmap($s,$s,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode='HighQualityBicubic'; $g.SmoothingMode='HighQuality'; $g.PixelOffsetMode='HighQuality'; $g.CompositingQuality='HighQuality'
  $g.Clear([System.Drawing.Color]::Transparent)
  if ($Round) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath; $r=[Math]::Max(1,[int]($s*0.18))
    $path.AddArc(0,0,$r*2,$r*2,180,90); $path.AddArc($s-$r*2,0,$r*2,$r*2,270,90); $path.AddArc($s-$r*2,$s-$r*2,$r*2,$r*2,0,90); $path.AddArc(0,$s-$r*2,$r*2,$r*2,90,90); $path.CloseFigure()
    $g.SetClip($path)
  }
  # ajustar manteniendo proporcion, centrado
  $scale = [Math]::Min($s / $src.Width, $s / $src.Height); $w = $src.Width*$scale; $h = $src.Height*$scale
  $g.DrawImage($src, [float](($s-$w)/2), [float](($s-$h)/2), [float]$w, [float]$h); $g.ResetClip(); $g.Dispose()
  if ($s -ge 256) {
    $ms = New-Object System.IO.MemoryStream; $bmp.Save($ms,[System.Drawing.Imaging.ImageFormat]::Png); $data = $ms.ToArray(); $ms.Dispose()
  } else {
    # DIB clasico: BITMAPINFOHEADER + pixeles BGRA de abajo hacia arriba + mascara AND
    $ms = New-Object System.IO.MemoryStream; $bw = New-Object System.IO.BinaryWriter($ms)
    $bw.Write([uint32]40); $bw.Write([int32]$s); $bw.Write([int32]($s*2)); $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]0); $bw.Write([uint32]($s*$s*4)); $bw.Write([int32]0); $bw.Write([int32]0); $bw.Write([uint32]0); $bw.Write([uint32]0)
    for ($y = $s-1; $y -ge 0; $y--) { for ($x = 0; $x -lt $s; $x++) { $c = $bmp.GetPixel($x,$y); $bw.Write([byte]$c.B); $bw.Write([byte]$c.G); $bw.Write([byte]$c.R); $bw.Write([byte]$c.A) } }
    $rowBytes = [int][Math]::Ceiling($s/32)*4
    for ($y = $s-1; $y -ge 0; $y--) { $row = New-Object byte[] $rowBytes; for ($x = 0; $x -lt $s; $x++) { if ($bmp.GetPixel($x,$y).A -lt 8) { $i = $x -shr 3; $row[$i] = $row[$i] -bor (0x80 -shr ($x % 8)) } }; $bw.Write($row) }
    $bw.Flush(); $data = $ms.ToArray(); $ms.Dispose()
  }
  $entries += ,@{size=$s; data=$data}; $bmp.Dispose()
}
$src.Dispose()
$o = New-Object System.IO.MemoryStream; $w = New-Object System.IO.BinaryWriter($o)
$w.Write([uint16]0); $w.Write([uint16]1); $w.Write([uint16]$entries.Count)
$offset = 6 + 16*$entries.Count
foreach ($e in $entries) { $sz = if ($e.size -ge 256) {0} else {$e.size}; $w.Write([byte]$sz); $w.Write([byte]$sz); $w.Write([byte]0); $w.Write([byte]0); $w.Write([uint16]1); $w.Write([uint16]32); $w.Write([uint32]$e.data.Length); $w.Write([uint32]$offset); $offset += $e.data.Length }
foreach ($e in $entries) { $w.Write($e.data) }
$w.Flush(); [IO.File]::WriteAllBytes($Out, $o.ToArray())
"ICO listo: $Out ($((Get-Item $Out).Length) bytes)"
