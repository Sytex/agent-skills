---
name: video-to-doc
description: Genera documentación de procesos Sytex a partir de grabaciones de pantalla, con recorte de screenshots, salida Markdown y exportación DOCX usando template corporativo.
---

# Skill: Sytex Video Docs (Markdown + DOCX)

Este skill está preparado para:
- analizar un video local,
- generar documentación en Markdown,
- optimizar screenshots (zona útil, in-place),
- y **siempre** exportar versión DOCX usando template.

## Ubicación de assets y scripts

- Template DOCX:
  - `./Encabezado_membrete Hoja Sytex - 2025.docx`
- Recorte híbrido de screenshots:
  - `./crop_useful_zone.py`
- Exportación Markdown -> DOCX con template:
  - `./export_docx_from_template.py`

## Salidas obligatorias (SIEMPRE)

Para un `<base>`:

- `docs/<base>.md`
- `docs/<base>.quickstart.md`
- `docs/<base>.docx`
- `docs/<base>.quickstart.docx`
- `artifacts/<base>/screenshots/` (imágenes válidas reemplazadas in-place)
- `artifacts/<base>/steps.json`
- `artifacts/<base>/analysis-notes.md`

## Flujo mínimo obligatorio

1. Generar/actualizar Markdown principal y quickstart.
2. Recortar screenshots a zona útil (in-place, sin carpeta extra):
```bash
python3 ./crop_useful_zone.py \
  --input-dir "artifacts/<base>/screenshots" \
  --in-place \
  --pattern "*.png"
```
3. Exportar ambos DOCX con template:
```bash
python3 ./export_docx_from_template.py \
  --template "./Encabezado_membrete Hoja Sytex - 2025.docx" \
  --markdown "docs/<base>.md" "docs/<base>.quickstart.md" \
  --resource-path ".:docs:artifacts"
```

## Reglas de calidad

- No dejar screenshots con paneles de videollamada o franjas negras cuando no aportan a la tarea.
- Mantener enlaces markdown apuntando a `screenshots/` (las imágenes válidas se reemplazan in-place).
- No cerrar una ejecución si falta cualquier `.docx` obligatorio.
- Si falla `pandoc`, reportar el error y no marcar la tarea como completa.
