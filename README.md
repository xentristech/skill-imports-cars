# Skill Imports Cars — fondo, tema y protector de pantalla para Windows

Skill de Claude Code que monta la marca **IMPORTS CARS** (compra · venta · permuta) en un PC Windows en un solo paso:

- Fondo de escritorio y pantalla de bloqueo con el logo oficial, foto de carro y el nombre del dueño.
- Tema oscuro con acento rojo `#E30613`.
- Protector de pantalla real (`.scr`) con 5 láminas que rotan con fundido y zoom lento.
- Acceso directo con icono en el escritorio.

## Instalar

1. Clona este repo y copia la carpeta `xentris-imports-cars` a `%USERPROFILE%\.claude\skills\`.
2. Corre el instalador (no necesita permisos de administrador ni instalar nada: usa Edge y el compilador de .NET que trae Windows):

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\xentris-imports-cars\scripts\instalar.ps1" -Nombre "Juan Carlos Ossa"
```

Opciones: `-Nombre "Otro Nombre"`, `-Minutos 10` (inactividad del protector), `-SoloPreparar` (renderiza y compila sin tocar Windows).

Con Claude Code basta decir: **"pon la marca de imports cars en el pc"**.

## Contenido

| Carpeta | Qué hay |
|---|---|
| `xentris-imports-cars/SKILL.md` | La receta completa, reglas de marca y los tropiezos resueltos. |
| `marca/` | Logo oficial transparente, icono, fotos de carro y pósters. |
| `plantillas/` | HTML/CSS del fondo (`{{NOMBRE}}`) y de las 5 láminas. |
| `protector/` | Código C# (WPF) del protector y su script de compilación. |
| `scripts/` | `instalar.ps1`, `renderizar.ps1`, `aplicar-fondo.ps1`, `make-ico.ps1`. |

## Volver atrás

Los fondos anteriores quedan en `Imágenes\Wallpapers\`. Tema: Configuración › Personalización › Temas. Protector: Configuración › Pantalla de bloqueo › Protector de pantalla › (Ninguno).

Hecho por Xentris Tech.
