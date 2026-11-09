param(
  [Parameter(Mandatory=$true)][string]$Imagen,
  [switch]$SoloEscritorio,
  [switch]$SoloBloqueo
)
# Aplica una imagen como fondo de escritorio y/o pantalla de bloqueo del usuario actual (no requiere administrador).
$Imagen = (Resolve-Path $Imagen).Path
if (-not $SoloBloqueo) {
  Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value 10   # 10 = Rellenar
  Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value 0
  if (-not ("WPApi" -as [type])) {
    Add-Type -TypeDefinition 'using System.Runtime.InteropServices; public class WPApi { [DllImport("user32.dll", SetLastError=true)] public static extern bool SystemParametersInfo(int a, int b, string c, int d); }'
  }
  $ok = [WPApi]::SystemParametersInfo(20, 0, $Imagen, 3)
  "Escritorio: $ok -> $Imagen"
}
if (-not $SoloEscritorio) {
  [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType=WindowsRuntime] | Out-Null
  [Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime] | Out-Null
  Add-Type -AssemblyName System.Runtime.WindowsRuntime
  $m = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 }
  $asOp = ($m | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
  $asAct = ($m | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' })[0]
  $t = $asOp.MakeGenericMethod([Windows.Storage.StorageFile]).Invoke($null, @([Windows.Storage.StorageFile]::GetFileFromPathAsync($Imagen))); $t.Wait(-1) | Out-Null
  $t2 = $asAct.Invoke($null, @([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($t.Result))); $t2.Wait(-1) | Out-Null
  "Bloqueo: " + [Windows.System.UserProfile.LockScreen]::OriginalImageFile
}
