---
name: xentris-imports-cars
description: Buena práctica de agente Xentris Tech. Monta el escritorio de marca IMPORTS CARS (compra · venta · permuta) en un PC Windows en un solo paso — fondo de escritorio y pantalla de bloqueo con el logo oficial, foto de carro y el nombre del dueño, tema oscuro con acento rojo #E30613, y un protector de pantalla real (.scr compilado con csc.exe) con 5 láminas que rotan con fundido. Úsala cuando el usuario diga "fondo de imports cars", "protector de pantalla imports cars", "tema imports cars", "pon la marca de imports cars en el pc", "cambia el nombre del fondo", o al preparar el PC de un vendedor de Imports Cars. Caso de referencia: PC de Duvan (DESKTOP-S447PIE), 2026-11-09, nombre Juan Carlos Ossa. Solo Windows.
---

# Escritorio y protector Imports Cars

Receta cerrada: el manual de marca (`IMPORTCARS_Manual.pdf`) ya está destilado aquí en recursos listos. No hace falta volver a leer el PDF ni generar nada con IA: todo está en esta carpeta.
Implementación de referencia: `C:\Users\Duvan\Pictures\Wallpapers\fuente-importscars\` y `...\protector-importscars\` — copiar de ahí, no reinventar.

## Un solo paso (lo normal)

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\xentris-imports-cars\scripts\instalar.ps1" -Nombre "Juan Carlos Ossa"
```
Hace todo en ~1 minuto: copia recursos a `Pictures\Wallpapers\`, renderiza fondo y 5 láminas a la resolución del monitor, compila `ImportsCars.scr`, aplica fondo + bloqueo, modo oscuro + acento rojo, registra el protector (5 min) y deja el acceso "Protector Imports Cars" en el escritorio.

- `-Nombre "Otro Nombre"` cambia la persona del fondo (el nombre va en Segoe UI Black, 92px, bajo "IMPORTACIÓN DE ALTA GAMA").
- `-Minutos 10` cambia la inactividad del protector.
- `-SoloPreparar` renderiza y compila sin tocar Windows (para revisar los PNG antes).

Después: abrir `Pictures\Wallpapers\ImportsCars-<Nombre>.png` con Read y revisar; Win+L para ver el bloqueo; doble clic al acceso del escritorio para ver el protector.

## Qué hay en la carpeta

| Carpeta | Contenido |
|---|---|
| `marca\` | `logo-importscars.png` (logo oficial, transparente, 7541x1077, extraído del PDF vectorial), `importscars.ico`, `car-suv.jpg` (SUV negra en sala roja, fondo), `car-coupe.jpg` (coupé en túnel, lámina 5), `poster-sequoia.png`, `poster-explorer.png` (piezas del manual). |
| `plantillas\` | `base.css` (paleta, grano, tipografías), `fondo.html` (con `{{NOMBRE}}`), `s1-logo` … `s5-foto.html` (láminas), `icono.html`. |
| `protector\` | `ImportsCarsProtector.cs` (WPF: fundido 1.6 s, 9 s por lámina, zoom lento, sale con mouse/tecla, log en `%TEMP%\ImportsCars-protector.log`) y `compilar.ps1`. |
| `scripts\` | `instalar.ps1` (todo en uno), `renderizar.ps1` (HTML→PNG con Edge headless), `aplicar-fondo.ps1` (escritorio + bloqueo sin admin), `make-ico.ps1`. |

## Marca (del manual, para cualquier pieza nueva)

- Colores: rojo `#E30613`, negro `#151719`, blanco `#F2F4F3`. Sobre oscuro: "IMPORTS" blanco, "CARS" rojo. Nunca todo el nombre en rojo ni en contorno.
- El wordmark NUNCA se escribe con texto: siempre el PNG `logo-importscars.png`. Área de reserva libre alrededor.
- Tipografía original: PP Neue Corp Extended (títulos) y Neue Haas Grotesk (texto). No están en Windows: se imitan con `Segoe UI Black` + `transform:scaleX(1.1)` (clase `.ext`) y `Bahnschrift` con `letter-spacing:.32em` para rótulos (clase `.lbl`).
- Look: fondo casi negro, resplandores rojos (`radial-gradient`) con grano (`feTurbulence` en `.grain`), esquinas rojas tipo mira (`.corner`), rótulo superior "IMPORTS CARS · 2026 · COMPRA · VENTA · PERMUTA" (`.meta`).
- Frases aprobadas: "Compra · Venta · Permuta", "Importación de alta gama", "Entregas inmediatas y confiables", "Respaldo · Confianza · Elegancia", "Potencia, tecnología & confort", "Cada vehículo que entregamos es más que una venta".

## Cambiar una lámina o el fondo a mano

1. Editar el HTML en `Pictures\Wallpapers\protector-importscars\` (o `fuente-importscars\fondo.html`).
2. Renderizar: `scripts\renderizar.ps1 -Html .\s3-sequoia.html -Out .\slides\s3-sequoia.png`.
3. El protector lee los PNG de `slides\` al arrancar: no hay que recompilar. Para el fondo, volver a correr `aplicar-fondo.ps1 -Imagen <png>`.
4. Para agregar un carro nuevo: copiar `s3-sequoia.html`, cambiar imagen y textos, renderizar a `slides\s6-<carro>.png` (se ordenan por nombre).

## Gotchas (lo que costó tiempo)

- ⚠️ El logo del PDF es vectorial: no tiene imágenes que extraer. Se renderizó la página a 144 dpi con PyMuPDF y se convirtió el negro en transparencia (`alpha = max(R,G,B)/255`, color des-premultiplicado). La página trae líneas de 1 px en los bordes: ignorar las 4 primeras/últimas filas y columnas al recortar.
- ⚠️ `csc.exe` de .NET Framework (`C:\Windows\Microsoft.NET\Framework64\v4.0.30319`) compila WPF sin instalar nada, pero hay que pasar las DLL de `...\WPF\` con ruta completa. Con `System.Windows.Forms` cargado, `Panel`, `Application`, `Cursors`, `Image`, `MessageBox` son ambiguos: alias `using X = System.Windows...`.
- ⚠️ Al probar el `.scr` con `Start-Process ... /s` y esperar 5 s, si el usuario mueve el mouse o escribe, el protector sale y parece que "se cayó". Mirar `%TEMP%\ImportsCars-protector.log`: dice `cierre por mouse/tecla` o `ERROR`.
- ⚠️ Abrir un `.theme` con `Start-Process` NO aplica el tema de forma fiable (deja Settings abierto y el tema anterior). El modo oscuro y el acento se aplican por registro (`Personalize`, `DWM`, `Explorer\Accent` con `AccentPalette`) y se avisan con `WM_SETTINGCHANGE "ImmersiveColorSet"`. El `.theme` se escribe solo para poder re-aplicarlo desde Configuración.
- ⚠️ `AccentColor` del DWM va en ABGR (`0xFF1306E3` para #E30613); `ColorizationColor` va en ARGB (`0xC4E30613`).
- ⚠️ Si en el PC había otro protector por script (Colcars: `vigilante.ps1` en la carpeta Inicio), apagarlo: mover su `.lnk` de Inicio a `protector\desactivado\` y matar el proceso. Dos protectores a la vez se pisan.
- ⚠️ La esquina inferior izquierda del fondo debe quedar vacía: ahí Windows pone el reloj del bloqueo.
- ⚠️ Rutas Git-Bash (`/c/Users/...`) no sirven para Python ni PIL: usar `C:\...`.

## Volver atrás
Fondos anteriores siguen en `Pictures\Wallpapers\`. Tema: Configuración › Personalización › Temas › "Custom". Protector: Configuración › Pantalla de bloqueo › Protector de pantalla › (Ninguno).

## Relacionado
[[cambiar-escritorio]] (skill personal de Duvan: Colcars y Grupo Meléndez), [[xentris-escritorio]] (orden de carpetas), [[xentris-manual-marca]], memoria [[importscars-marca]].
