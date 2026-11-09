# Compila ImportsCarsProtector.cs a ImportsCars.scr con el compilador de .NET Framework que trae Windows.
$dir = $PSScriptRoot
$fw  = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
$refs = @("$fw\WPF\PresentationFramework.dll","$fw\WPF\PresentationCore.dll","$fw\WPF\WindowsBase.dll","$fw\System.Xaml.dll","$fw\System.Windows.Forms.dll","$fw\System.Drawing.dll","$fw\System.Core.dll") | ForEach-Object { "/r:$_" }
$icono = Join-Path $dir "importscars.ico"
$args = @("/nologo","/target:winexe","/optimize+","/out:$dir\ImportsCars.scr") + $refs
if (Test-Path $icono) { $args += "/win32icon:$icono" }
$args += "$dir\ImportsCarsProtector.cs"
& "$fw\csc.exe" @args
if ($LASTEXITCODE -ne 0) { throw "Fallo la compilacion" }
"Compilado: $dir\ImportsCars.scr"
