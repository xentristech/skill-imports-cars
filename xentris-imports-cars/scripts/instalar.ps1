# Monta el escritorio Imports Cars en este PC: fondo + pantalla de bloqueo + tema oscuro con acento rojo
# + protector de pantalla (.scr) con 5 laminas + acceso directo con icono.
# Uso:  powershell -ExecutionPolicy Bypass -File instalar.ps1 -Nombre "Juan Carlos Ossa"
#       -SoloPreparar  -> renderiza y compila sin tocar la configuracion de Windows.
#       -Minutos 5     -> inactividad antes de arrancar el protector.
param(
  [string]$Nombre = "Juan Carlos Ossa",
  [int]$Minutos = 5,
  [switch]$SoloPreparar
)
$ErrorActionPreference = 'Stop'
$skill = Split-Path $PSScriptRoot -Parent
$W     = Join-Path $HOME "Pictures\Wallpapers"
$fuente = Join-Path $W "fuente-importscars"
$prot   = Join-Path $W "protector-importscars"
$iconos = Join-Path $W "iconos"
foreach ($d in $fuente, $prot, (Join-Path $prot "slides"), $iconos) { New-Item -ItemType Directory -Force $d | Out-Null }

Add-Type -AssemblyName System.Windows.Forms
$scr = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $ancho = $scr.Width; $alto = $scr.Height
"Pantalla: ${ancho}x${alto}  Nombre: $Nombre"

# 1. Recursos de marca y plantillas a las carpetas de trabajo
Copy-Item "$skill\marca\*" $fuente -Force
Copy-Item "$skill\marca\*" $prot -Force
Copy-Item "$skill\plantillas\*" $fuente -Force
Copy-Item "$skill\plantillas\*" $prot -Force
Copy-Item "$skill\protector\*" $prot -Force
Copy-Item "$skill\marca\importscars.ico" (Join-Path $iconos "importscars.ico") -Force
Copy-Item "$fuente\car-suv.jpg"  "$fuente\car.jpg" -Force   # fondo: SUV negra en sala roja
Copy-Item "$prot\car-coupe.jpg"  "$prot\car.jpg"   -Force   # lamina 5: coupe en tunel
(Get-Content "$fuente\fondo.html" -Raw -Encoding UTF8).Replace('{{NOMBRE}}', $Nombre) | Set-Content "$fuente\fondo.html" -Encoding UTF8
# El body de las plantillas mide 2560x1440; si la pantalla es otra, se ajusta el CSS base.
foreach ($css in "$fuente\base.css", "$prot\base.css") {
  (Get-Content $css -Raw -Encoding UTF8) -replace 'width:2560px;height:1440px', "width:${ancho}px;height:${alto}px" | Set-Content $css -Encoding UTF8
}

# 2. Renderizar fondo y laminas con Edge headless
$render = Join-Path $PSScriptRoot "renderizar.ps1"
& $render -Html "$fuente\fondo.html" -Out "$fuente\fondo.png" -Ancho $ancho -Alto $alto
foreach ($s in 's1-logo','s2-entregas','s3-sequoia','s4-explorer','s5-foto') {
  & $render -Html "$prot\$s.html" -Out "$prot\slides\$s.png" -Ancho $ancho -Alto $alto
}
$nombreArchivo = ($Nombre -replace '[^A-Za-z0-9]', '')
$fondo = Join-Path $W "ImportsCars-$nombreArchivo.png"
Copy-Item "$fuente\fondo.png" $fondo -Force

# 3. Compilar el protector
& "$prot\compilar.ps1"
$exe = Join-Path $prot "ImportsCars.scr"
if ($SoloPreparar) { "Preparado sin aplicar. Fondo: $fondo  Protector: $exe"; return }

# 4. Fondo de escritorio + pantalla de bloqueo
& (Join-Path $PSScriptRoot "aplicar-fondo.ps1") -Imagen $fondo

# 5. Tema: modo oscuro + acento rojo #E30613 (en Start, barra y bordes)
$P='HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
Set-ItemProperty $P AppsUseLightTheme 0 -Type DWord; Set-ItemProperty $P SystemUsesLightTheme 0 -Type DWord; Set-ItemProperty $P ColorPrevalence 1 -Type DWord
$D='HKCU:\Software\Microsoft\Windows\DWM'
Set-ItemProperty $D AccentColor 0xFF1306E3 -Type DWord; Set-ItemProperty $D ColorizationColor 0xC4E30613 -Type DWord; Set-ItemProperty $D ColorizationAfterglow 0xC4E30613 -Type DWord; Set-ItemProperty $D ColorPrevalence 1 -Type DWord
$A='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'; if (-not (Test-Path $A)) { New-Item $A -Force | Out-Null }
$pal=[byte[]](0xFB,0xC3,0xC6,0, 0xF5,0x7A,0x82,0, 0xEE,0x3B,0x47,0, 0xE3,0x06,0x13,0, 0xB8,0x05,0x10,0, 0x8E,0x04,0x0C,0, 0x5A,0x02,0x08,0, 0x15,0x17,0x19,0)
Set-ItemProperty $A AccentPalette $pal -Type Binary; Set-ItemProperty $A AccentColorMenu 0xFF1306E3 -Type DWord; Set-ItemProperty $A StartColorMenu 0xFF1005B8 -Type DWord
if (-not ("WMsg" -as [type])) { Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class WMsg { [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr h, uint m, UIntPtr w, string l, uint f, uint t, out UIntPtr r); }' }
$r=[UIntPtr]::Zero; [WMsg]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, "ImmersiveColorSet", 2, 5000, [ref]$r) | Out-Null
# Archivo .theme para re-aplicar desde Configuracion > Personalizacion > Temas
$themeDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Themes"
@"
[Theme]
DisplayName=Imports Cars
[Control Panel\Desktop]
Wallpaper=$fondo
TileWallpaper=0
WallpaperStyle=10
[VisualStyles]
Path=%SystemRoot%\resources\Themes\Aero\Aero.msstyles
ColorStyle=NormalColor
Size=NormalSize
AutoColorization=0
ColorizationColor=0XC4E30613
SystemMode=Dark
AppMode=Dark
[MasterThemeSelector]
MTSM=RJSPBS
"@ | Set-Content (Join-Path $themeDir "ImportsCars.theme") -Encoding Unicode

# 6. Protector de pantalla registrado en Windows
$K='HKCU:\Control Panel\Desktop'
Set-ItemProperty $K 'SCRNSAVE.EXE' $exe; Set-ItemProperty $K ScreenSaveActive '1'; Set-ItemProperty $K ScreenSaveTimeOut ([string]($Minutos*60)); Set-ItemProperty $K ScreenSaverIsSecure '0'
if (-not ("SPInfo" -as [type])) { Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class SPInfo { [DllImport("user32.dll", SetLastError=true)] public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint f); }' }
[SPInfo]::SystemParametersInfo(15, $Minutos*60, [IntPtr]::Zero, 3) | Out-Null; [SPInfo]::SystemParametersInfo(17, 1, [IntPtr]::Zero, 3) | Out-Null

# 7. Acceso directo en el escritorio
$ws = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) "Protector Imports Cars.lnk"))
$lnk.TargetPath = $exe; $lnk.Arguments = '/s'; $lnk.WorkingDirectory = $prot
$lnk.IconLocation = (Join-Path $iconos "importscars.ico") + ",0"; $lnk.Description = 'Ver el protector de pantalla Imports Cars'; $lnk.Save()

"LISTO. Fondo y bloqueo: $fondo"
"Protector: $exe  (arranca a los $Minutos min; prueba con el acceso del escritorio)"
"Tema: modo oscuro + acento rojo. Volver atras: Configuracion > Personalizacion > Temas."
