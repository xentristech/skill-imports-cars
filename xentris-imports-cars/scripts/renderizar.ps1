param(
  [Parameter(Mandatory=$true)][string]$Html,
  [Parameter(Mandatory=$true)][string]$Out,
  [int]$Ancho = 0,
  [int]$Alto = 0
)
# Renderiza un HTML a PNG con Microsoft Edge en modo headless, al tamano de la pantalla principal.
Add-Type -AssemblyName System.Windows.Forms
if ($Ancho -eq 0 -or $Alto -eq 0) {
  $scr = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $Ancho = $scr.Width; $Alto = $scr.Height
}
$edge = @("C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe","C:\Program Files\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { throw "No se encontro Microsoft Edge" }
$profile = Join-Path $env:TEMP "edge-render-profile"
if (Test-Path $Out) { Remove-Item $Out -Force }
$uri = "file:///" + ((Resolve-Path $Html).Path -replace '\\','/')
$p = Start-Process -FilePath $edge -ArgumentList @("--headless=new","--disable-gpu","--hide-scrollbars","--force-device-scale-factor=1","--window-size=$Ancho,$Alto","--virtual-time-budget=5000","--allow-file-access-from-files","--user-data-dir=$profile","--screenshot=$Out",$uri) -PassThru -Wait
if (-not (Test-Path $Out)) { throw "Edge no genero la imagen (exit $($p.ExitCode))" }
"Renderizado: $Out (${Ancho}x${Alto})"
