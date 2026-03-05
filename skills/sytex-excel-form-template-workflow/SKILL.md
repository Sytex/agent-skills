---
name: sytex-excel-form-template-workflow
description: Guía para trabajar con plantillas Excel (.xlsx) de formularios: análisis, diseño, mapeo de referencias, validación contra JSON real, manejo de imágenes y mantenimiento sin romper estructura.
---

# Excel Form Template Workflow

## Cuándo usar este skill
Úsalo para cualquier trabajo con templates Excel de formularios, por ejemplo:
- crear o ajustar una plantilla nueva
- mapear celdas e imágenes a respuestas del formulario
- validar referencias contra un JSON real
- simplificar imágenes de evidencia
- preservar logos y branding
- corregir referencias puntuales sin romper otras

## Objetivos
1. Entender la plantilla y su estructura OpenXML.
2. Mapear correctamente referencias de texto e imagen.
3. Mantener consistencia con el formulario real (JSON).
4. Hacer cambios de forma segura y trazable.

## Entradas esperadas
- Uno o más `.xlsx` (base y/o versión objetivo).
- JSON de formulario real (normalmente con `items` y `kind == "entry"`).
- Opcional: reglas de negocio para mapeos ambiguos.

## Modelo mental del `.xlsx` (OpenXML)
`.xlsx` es un ZIP con XML internos.

Rutas clave:
- `xl/sharedStrings.xml`: textos y placeholders de celdas.
- `xl/worksheets/sheet*.xml`: layout de celdas, hyperlinks visibles.
- `xl/worksheets/_rels/sheet*.xml.rels`: targets de hyperlinks de hoja.
- `xl/drawings/drawing*.xml`: posición de imágenes (anchors).
- `xl/drawings/_rels/drawing*.xml.rels`: hyperlinks de imágenes y links a media.
- `xl/media/*`: archivos de imagen embebidos.

## Tipos de etiquetado y cómo interpretarlos

### 1) Etiquetas de valor (texto)
Patrón canónico:
- `{{ answers.<key>.value }}`

Ejemplo:
- `{{ answers.2_1A_3_2G_8.value }}`

Errores comunes:
- espacios internos (`{{answers. 2_... .value}}`)
- `.value` faltante o mal escrito
- claves inexistentes en el formulario

### 2) Etiquetas de imagen (photos)
Patrón canónico:
- `answers.<key>.photos.<n>`
- `<n>` es **base 0** (cero): `photos.0`, `photos.1`, `photos.2`, ...

Dónde aparecen:
- `drawing*.xml.rels` (más común)
- `sheet*.xml.rels` y/o `sheet*.xml`

Nota:
- Pueden venir URL-encoded (`%7B%7B ... %7D%7D`).

## Cómo derivar claves válidas desde JSON
1. Tomar `items` con `kind == "entry"`.
2. Usar `index` como clave lógica.
3. Excluir auxiliares (ej. `*-repeat-end`).
4. Normalizar `index`: reemplazar `.` por `_`.

Ejemplo:
- `2.1A.2.1.3.1` -> `2_1A_2_1_3_1`

## Workflow recomendado
1. Inventario:
- extraer referencias `value` y `photos` del `.xlsx`.
- listar por archivo interno (`sharedStrings`, `drawings`, `rels`).

2. Validación:
- comparar con set válido derivado del JSON.
- clasificar: válida, formato inválido, clave inválida.

3. Interpretación visual:
- mapear imágenes por anchor `(row,col)` en `drawing*.xml`.
- resolver `rId -> Target` en `.rels`.
- cruzar con títulos de sección en `sheet*.xml`/`sharedStrings.xml`.

4. Modificación segura:
- cambiar solo lo necesario (texto objetivo o `Target`).
- preferir correcciones por `rId` cuando un bloque comparte patrones con otro.
- nunca sobrescribir original; generar archivo nuevo versionado.

5. Verificación de no-regresión:
- referencias inválidas de `value`: `0`
- bases inválidas de `photos`: `0`
- revisión de bloques críticos por posición `(row,col)`
- validar que cambios no intencionales no ocurran en XML no relacionado.

## Validación generalizable de referencias
Usar este pipeline como estándar en cualquier template:

1. Construir catálogo de referencias del Excel:
- `value`: placeholders `{{ ... }}` en XML.
- `photos`: `answers.<key>.photos.<n>` en `xml` y `rels`.
- incluir contexto por referencia: `file`, `sheet/drawing`, `rId` (si aplica), `row/col` (si aplica).

2. Construir catálogo válido desde JSON:
- tomar `items` con `kind == "entry"`.
- `valid_key = index.replace(".", "_")`.
- excluir auxiliares (`repeat-end` y equivalentes no renderizables).

3. Normalizar antes de comparar:
- trim de espacios internos en placeholders.
- unificar formato `{{ answers.<key>.value }}`.
- decode de URL cuando sea necesario para inspección (sin perder formato original de escritura).

4. Clasificar hallazgos:
- `valid`: referencia correcta.
- `format_error`: clave válida pero sintaxis incorrecta.
- `invalid_key`: clave no existe en catálogo JSON.
- `ambiguous`: hay varios candidatos plausibles.
- `context_conflict`: referencia válida pero incompatible con layout esperado por bloque.

5. Corregir con política segura:
- primero `format_error` (sin cambiar semántica).
- luego `invalid_key` solo con mapping explícito y justificable.
- `ambiguous` => pedir confirmación al usuario.
- en imágenes, preferir fix por `rId`/anchor para evitar colisiones entre bloques.

6. Revalidar:
- recalcular clasificación post-cambio.
- exigir `invalid_key == 0` para `value` y `photos` salvo excepción acordada.
- confirmar que archivos no objetivo no cambiaron.

## Reglas específicas de índices de fotos
- `answers.<key>.photos.<n>` usa índice base 0.
- no asumir continuidad de índices (`0,1,3` puede ser válido).
- validar la **base** (`<key>`) contra JSON; el índice `<n>` depende de disponibilidad real de archivos en runtime.

## Salida mínima recomendada de validación
Generar un resumen compacto con:
- total de referencias `value` y `photos`.
- conteo por estado (`valid`, `format_error`, `invalid_key`, `ambiguous`, `context_conflict`).
- lista de cambios aplicados (`old -> new`) con ubicación (`file`, `rId` o `cell/anchor`).
- riesgos abiertos (si quedó algo sin resolver por ambigüedad).

## Imágenes: evidencias vs logos
Regla práctica:
- Evidencias: normalmente con `hlinkClick` y mapeadas a `answers.*.photos.*`.
- Logos/branding: normalmente cabecera, sin hyperlink de respuesta.

Si se simplifican fotos para bajar tamaño:
- reemplazar solo evidencias.
- preservar logos.
- si hubo reemplazo global, restaurar logos desde archivo base.

## Estrategias de cambio

### A) Mantenimiento/ajuste de plantilla
- actualizar placeholders de nuevas preguntas
- retirar placeholders obsoletos
- mantener naming coherente con JSON real

### B) Corrección puntual sin romper bloques vecinos
- localizar anchors por `(row,col)` del bloque afectado
- editar solo `rId` o targets específicos
- revalidar bloque hermano (que no se haya movido)

### C) Simplificación visual controlada
- reemplazar media de evidencia por placeholder
- mantener hiperlinks intactos
- restaurar media de logos

## Nomenclatura sugerida de salida
- `*_template_actualizado.xlsx`
- `*_template_validado.xlsx`
- `*_template_simplificado.xlsx`
- `*_template_simplificado_validado.xlsx`

## Cuándo preguntar al usuario
Preguntar antes de aplicar si:
- hay más de un candidato semántico plausible para una referencia rota.
- la estructura del JSON no permite inferencia confiable.
- hay conflicto entre layout visual y mapping lógico.

## Comandos útiles
```bash
# Listar contenido interno del xlsx
unzip -l archivo.xlsx

# Extraer placeholders de texto
rg -o -N "\{\{[^}]+\}\}" /tmp/xlsx/xl -g '*.xml'

# Extraer referencias photos
rg -o -N "answers\.[A-Za-z0-9_]+\.photos\.[0-9]+" /tmp/xlsx/xl -g '*.xml' -g '*.rels'
```
