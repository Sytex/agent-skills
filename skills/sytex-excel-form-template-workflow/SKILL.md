---
name: sytex-excel-form-template-workflow
description: "Guía para trabajar con plantillas Excel (.xlsx) de formularios: análisis, diseño, mapeo de referencias, validación contra JSON real, expresiones soportadas, manejo de imágenes y mantenimiento sin romper estructura."
---

# Excel Form Template Workflow

## Cuándo usar este skill
Úsalo para cualquier trabajo con templates Excel de formularios, por ejemplo:
- crear o ajustar una plantilla nueva
- mapear celdas e imágenes a respuestas del formulario
- validar referencias y expresiones contra un JSON real
- corregir placeholders rotos o ambiguos
- simplificar imágenes de evidencia
- preservar logos y branding
- corregir referencias puntuales sin romper otras

## Objetivos
1. Entender la plantilla y su estructura OpenXML.
2. Mapear correctamente referencias de texto e imagen.
3. Mantener consistencia con el formulario real y con el motor actual de exportación.
4. Hacer cambios de forma segura y trazable.

## Entradas esperadas
- Uno o más `.xlsx` (base y/o versión objetivo).
- JSON de formulario real.
- Opcionalmente, JSON de template o una estructura equivalente que exponga `items`.
- Opcionalmente, contenido real del form con `entryanswer_set`; esto sirve para inspeccionar respuestas existentes, pero por sí solo no alcanza para derivar un catálogo completo de claves válidas si no viene acompañado de metadata de template.
- Opcional: reglas de negocio para mapeos ambiguos.
- Opcional: archivo base para restaurar logos o comparar no-regresiones.

## Modelo mental del `.xlsx` (OpenXML)
`.xlsx` es un ZIP con XML internos.

Rutas clave:
- `xl/sharedStrings.xml`: textos y placeholders de celdas.
- `xl/worksheets/sheet*.xml`: layout de celdas, hyperlinks visibles.
- `xl/worksheets/_rels/sheet*.xml.rels`: targets de hyperlinks de hoja.
- `xl/drawings/drawing*.xml`: posición de imágenes (anchors).
- `xl/drawings/_rels/drawing*.xml.rels`: hyperlinks de imágenes y links a media.
- `xl/media/*`: archivos de imagen embebidos.

## Modelo mental del exportador actual
El exportador no resuelve solo strings literales. Hoy soporta:
- propiedades `form.*`
- propiedades `answers.*`
- funciones `contains(...)`, `isEqual(...)`, `left(...)`, `right(...)`, `date_format(...)`
- expresiones tipo `a or b`
- expresiones tipo `"A" if condicion else "B"`

Además:
- normaliza comillas raras (`“ ”`) a comillas rectas
- decodifica entidades HTML como `&quot;`
- preserva valores tipados para evaluar condiciones y funciones
- recién al render final convierte a string cuando corresponde

## Tipos de etiquetado y cómo interpretarlos

### 1) Etiquetas de valor o expresión (texto)
Patrón general:
- `{{ <expresion> }}`

Patrones válidos frecuentes:
- `{{ answers.<key>.value }}`
- `{{ answers.<key>.remarks }}`
- `{{ answers.<key>.entry.label }}`
- `{{ form.code }}`
- `{{ form.project.name }}`
- `{{ form.sites.0.code }}`
- `{{ "Si" if answers.<key>.value else "No" }}`
- `{{ form.name or form.code }}`
- `{{ isEqual(form.status, "approved") }}`
- `{{ contains(answers.<key>.value, "EPP") }}`
- `{{ left(form.code, 3) }}`
- `{{ right(form.code, 4) }}`
- `{{ date_format(answers.<key>.value, "%d/%m/%Y") }}`
- `{{ date_format(form.approvalDate, "%Y-%m-%d %H:%M") }}`

Errores comunes:
- espacios internos que rompen paths (`answers. 2_1.value`)
- `.value` faltante cuando el placeholder apunta a una respuesta escalar
- función no soportada
- usar una clave inexistente
- asumir que todas las comparaciones son string sin considerar tipos

### 2) Claves válidas de `answers`
El exportador actual puede resolver una respuesta por más de una clave:

- índice normalizado:
  - `answers.2_1A_3_2G_8.value`
- `template_entry_id` completo:
  - `answers.abc12345-6789-0000-0000-000000000000.value`
- clave humana:
  - `answers.abc1234-mi-campo.value`

Regla de clave humana:
- `template_entry_id[:7] + "-" + slugify(label)[:15]`

Cómo leer esa regla:
- no es un UUIDv7
- `template_entry_id[:7]` significa solo "primeros 7 caracteres del template_entry_id"
- luego se concatena `-`
- luego va el label normalizado con `slugify(...)` y truncado a 15 caracteres

Ejemplo:
- `template_entry_id = abc12345-6789-0000-0000-000000000000`
- `label = "Protección Caídas"`
- clave humana resultante: `abc1234-proteccion-cai`

Recomendación práctica:
- preferir esta clave humana siempre que esté disponible
- usar índices normalizados solo como compatibilidad o cuando no exista metadata suficiente

Motivo:
- los índices del formulario pueden cambiar mucho cuando el usuario reordena, inserta o elimina entradas/categorías
- `template_entry_id` y label suelen ser mucho más estables para mantenimiento de templates
- esto reduce roturas silenciosas cuando cambia la estructura del formulario pero la entry sigue siendo la misma

Al validar, aceptar las tres variantes, pero al diseñar o corregir templates nuevos preferir la clave humana.

### 3) Etiquetas de imagen (photos)
Patrón canónico:
- `answers.<key>.photos.<n>`
- `<n>` es base 0: `photos.0`, `photos.1`, `photos.2`, ...

Dónde aparecen:
- `drawing*.xml.rels` (más común)
- `sheet*.xml.rels`
- a veces URL-encoded dentro de XML

Notas:
- el exportador resuelve `photos` como lista
- cada item expone al menos `data`, `filename` y `file_id`
- `data` puede venir serializado como `url|filename|file_id`

## Cómo derivar claves válidas desde JSON

### Variante A: índice lógico
1. Tomar `items` con `kind == "entry"` o equivalentes renderizables.
2. Usar `index` como clave lógica.
3. Excluir auxiliares como `*-repeat-end`.
4. Normalizar `index`: reemplazar `.` por `_`.

Ejemplo:
- `2.1A.2.1.3.1` -> `2_1A_2_1_3_1`

### Variante B: `template_entry_id`
Si la fuente de metadata de entries expone `template_entry_id`, esa referencia también es válida:
- `answers.<template_entry_id>.value`

Fuentes válidas para esa metadata:
- JSON de template con `items`
- `entryanswer_set` enriquecido con su `entry` resuelta contra metadata del template

No asumir que `template_entry_id` aparece en cualquier JSON de form. Si solo hay `entryanswer_set` con respuestas crudas y sin metadata asociada, no se puede derivar esta variante de forma confiable.

### Variante C: clave humana
Si además existe `label`, se genera otra clave válida:
- `answers.<template_entry_id[:7]>-<slugify(label)[:15]>.value`

Esta variante solo existe cuando ambas cosas están disponibles:
- `template_entry_id`
- `label`

No asumir que una plantilla usa solo índices ni que siempre podrá usar claves humanas.
Si la metadata está disponible, usar claves humanas como opción preferida para desacoplar la plantilla de cambios de índice inducidos por edición del formulario.

## Cómo construir el catálogo válido según la fuente disponible

### Caso A: tenés JSON de template con `items`
1. Tomar `items` renderizables (`kind == "entry"` o equivalente).
2. Derivar clave por índice normalizado.
3. Si cada item trae `template_entry_id`, agregar esa clave.
4. Si además trae `label`, agregar la clave humana.

### Caso B: tenés form real con `entryanswer_set` y metadata resolvible de entry
1. Para cada answer, ubicar su entry real.
2. Tomar de esa entry:
- `index` para la clave normalizada
- `template_entry_id` si existe
- `label` si existe
3. Construir el mismo catálogo que en el caso A.

### Caso C: solo tenés `entryanswer_set` sin metadata de template
1. Podés inspeccionar respuestas existentes y detectar referencias usadas.
2. No podés derivar de forma confiable el catálogo completo de claves válidas.
3. En ese escenario:
- no declarar `invalid_key` por ausencia de `template_entry_id`
- no inventar claves humanas
- pedir metadata adicional si la tarea requiere validar exhaustivamente el template

## Semántica actual de valores

### Escalares
- `False` y `0` se preservan como tales en evaluación interna.
- Al render de texto salen como `"False"` y `"0"`.
- En `isEqual(...)` se normalizan para comparar contra strings como `"false"` o `"1"`.

### Multiselect
- El valor renderizado suele ser una lista legible separada por coma.
- El valor crudo se preserva como lista, útil para `contains(...)`.

Ejemplo práctico:
- render: `"Protecion de caidas, EPP"`
- raw: `["Protecion de caidas", "EPP"]`

### Multientry / JSON dict
- Si una respuesta viene como JSON object, se parsea a `dict`.
- `{{ answers.<key>.value }}` devuelve valores unidos por coma.
- `{{ answers.<key>.value.0 }}` y `{{ answers.<key>.value.1 }}` están soportados por la implementación actual como acceso posicional sobre `dict.values()`.
- Ese acceso depende del orden de inserción preservado en el dict parseado y debe tratarse como compatibilidad de implementación, no como contrato semántico fuerte del negocio.
- Usarlo solo cuando el origen del JSON preserve orden de forma estable y el mapping esté controlado.
- Si necesitás semántica estable entre subcampos, preferí exponer claves explícitas en vez de depender de posiciones.

### Location
- sigue exponiendo `latitude` y `longitude` además del valor base.

### Object selection
Cuando una respuesta es de tipo object selection (`entry_type == 14`), el adaptador expone metadata adicional del objeto seleccionado:

Paths disponibles:
- `answers.<key>.value` — devuelve `code` del objeto si existe, si no `name`, si no `display` (backward-compatible)
- `answers.<key>.id` — ID del objeto seleccionado
- `answers.<key>.name` — nombre del objeto
- `answers.<key>.code` — código del objeto (string vacío si no tiene)
- `answers.<key>.type` — modelo del tipo de objeto (e.g., `"site"`, `"networkelement"`, `"material"`, `"supplier"`)

Semántica:
- el adaptador resuelve el objeto real contra `ContentType` usando `object_type` y el `answer` (ID del objeto)
- si la resolución falla (objeto eliminado, tipo inválido), hace fallback a `content_object` del JSON como display/name
- `value` en render (texto) usa la prioridad `code > name > display`; en acceso raw devuelve el ID crudo del objeto
- los paths `id`, `name`, `code`, `type` están disponibles tanto por índice normalizado, `template_entry_id`, como por clave humana

Ejemplo práctico:
- entry con `object_type_model: "site"`, objeto con `code: "0003"`, `name: "Test Site"`
- `{{ answers.1_6.value }}` → `"0003"`
- `{{ answers.1_6.name }}` → `"Test Site"`
- `{{ answers.1_6.code }}` → `"0003"`
- `{{ answers.1_6.type }}` → `"site"`
- `{{ answers.1_6.id }}` → `"site-001"` (ID del objeto)

Display por tipo de objeto:
- `material`: `"{code} {name}"`
- `site`, `networkelement`: `"{code} - {name}"`
- otros: solo `name`

## Funciones soportadas

### `isEqual(left, right)`
Uso:
- `{{ isEqual(form.status, "approved") }}`
- `{{ isEqual(answers.1_6_1.value, "1") }}`

Semántica:
- compara valores normalizados
- `None -> ""`
- `bool -> "true"/"false"`
- números -> string numérico

### `contains(left, right)`
Uso:
- `{{ contains(answers.1_4.value, "EPP") }}`
- `{{ contains(form.code, "FORM") }}`

Semántica:
- si `left` es lista: busca membresía
- si `left` es dict: busca sobre `dict.values()`
- si `left` es string: busca substring
- si `left` está vacío o `right` está vacío: devuelve `false`

### `left(value, n)`
Uso:
- `{{ left(form.code, 3) }}`
- `{{ left(form.code, -2) }}`

### `right(value, n)`
Uso:
- `{{ right(form.code, 4) }}`
- `{{ right(form.code, -2) }}`

### `date_format(property, format)`
Uso:
- `{{ date_format(answers.<key>.value, "%d/%m/%Y") }}`
- `{{ date_format(form.approvalDate, "%Y-%m-%d %H:%M") }}`
- `{{ date_format(form.planDate, "%d de %B de %Y") }}`

Semántica:
- acepta `date`, `datetime`, strings ISO 8601, y formatos comunes (`YYYY-MM-DD`, `YYYY-MM-DD HH:MM:SS`, `YYYY-MM-DD HH:MM`)
- normaliza sufijo `Z` como `+00:00` para parsear UTC
- el segundo argumento es un format string de Python `strftime` (e.g., `%d/%m/%Y`, `%H:%M`, `%B`)
- si el valor no puede interpretarse como fecha, devuelve string vacío
- si el valor ya es un objeto `date` o `datetime` nativo, lo formatea directamente

## Workflow recomendado
1. Inventario:
- extraer placeholders `{{ ... }}` y referencias `answers.*.photos.*` del `.xlsx`
- listar por archivo interno (`sharedStrings`, `drawings`, `rels`)

2. Clasificación sintáctica:
- distinguir `property`, `function`, `if_else`, `or_clause`, `photo_ref`
- detectar placeholders que el motor actual no soporta

3. Validación de claves:
- comparar claves de `answers` contra el catálogo válido derivado del JSON
- aceptar índice normalizado, `template_entry_id` y clave humana cuando existan

4. Validación semántica:
- revisar si un `contains(...)` apunta a un valor que en runtime será lista/string/dict
- revisar si `isEqual(...)` depende de comparar booleanos o numéricos
- revisar accesos posicionales como `.value.0` cuando la respuesta sea multientry
- marcar como riesgo cualquier acceso posicional a `dict.values()` si no está claro que el orden sea estable

5. Interpretación visual:
- mapear imágenes por anchor `(row,col)` en `drawing*.xml`
- resolver `rId -> Target` en `.rels`
- cruzar con títulos de sección en `sheet*.xml` / `sharedStrings.xml`

6. Modificación segura:
- cambiar solo lo necesario (`sharedStrings`, `Target`, o placeholder puntual)
- preferir correcciones por `rId` cuando un bloque comparte patrones con otro
- nunca sobrescribir original; generar archivo nuevo versionado

7. Verificación de no-regresión:
- referencias inválidas de `answers`: `0`
- expresiones no soportadas: `0`
- bases inválidas de `photos`: `0`
- revisión de bloques críticos por posición `(row,col)`
- confirmar que no hubo cambios accidentales en XML no relacionado

## Validación generalizable de placeholders
Usar este pipeline como estándar en cualquier template:

1. Construir catálogo del Excel:
- `placeholders`: contenido de `{{ ... }}`
- `photos`: `answers.<key>.photos.<n>` en `xml` y `rels`
- incluir contexto: `file`, `sheet/drawing`, `rId`, `row/col`

2. Construir catálogo válido desde JSON / form content:
- claves por índice normalizado cuando exista metadata de entry
- claves por `template_entry_id` solo si la metadata fuente realmente lo expone
- claves humanas solo si la metadata fuente expone `template_entry_id` y `label`
- excluir auxiliares no renderizables
- si solo hay `entryanswer_set` sin metadata, declarar explícitamente que el catálogo será parcial

3. Normalizar antes de comparar:
- trim de espacios
- decode HTML (`&quot;`)
- normalizar comillas no estándar
- decode URL cuando haga falta inspeccionar un hyperlink

4. Clasificar hallazgos:
- `valid`
- `format_error`
- `invalid_key`
- `unsupported_expression`
- `ambiguous`
- `context_conflict`

5. Corregir con política segura:
- primero `format_error`
- luego `unsupported_expression` migrando a sintaxis soportada
- luego `invalid_key` solo con mapping explícito y justificable
- `ambiguous` => pedir confirmación
- en imágenes, preferir fix por `rId` / anchor

6. Revalidar:
- recalcular clasificación post-cambio
- exigir `invalid_key == 0`
- exigir `unsupported_expression == 0`
- confirmar que archivos no objetivo no cambiaron

## Reglas específicas de índices de fotos
- `answers.<key>.photos.<n>` usa índice base 0
- no asumir continuidad (`0,1,3` puede ser válido)
- validar la base `<key>` contra el catálogo de answers
- el índice `<n>` depende de disponibilidad real de fotos en runtime

## Imágenes: evidencias vs logos
Regla práctica:
- Evidencias: normalmente con `hlinkClick` y mapeadas a `answers.*.photos.*`
- Logos/branding: normalmente cabecera, sin hyperlink de respuesta

Si se simplifican fotos para bajar tamaño:
- reemplazar solo evidencias
- preservar logos
- si hubo reemplazo global, restaurar logos desde archivo base

## Estrategias de cambio

### A) Mantenimiento/ajuste de plantilla
- actualizar placeholders de nuevas preguntas
- retirar placeholders obsoletos
- migrar placeholders viejos a sintaxis soportada por el motor actual
- mantener naming coherente con JSON real

### B) Corrección puntual sin romper bloques vecinos
- localizar anchors por `(row,col)` del bloque afectado
- editar solo `rId`, `Target` o placeholder específico
- revalidar bloque hermano para confirmar que no se movió

### C) Mejora de legibilidad
- cuando conviene, usar clave humana `prefijo7-slug`
- esta debería ser la opción por defecto cuando exista `template_entry_id` y `label`
- evita depender de índices que pueden cambiar por input del usuario en el editor del formulario

### D) Simplificación visual controlada
- reemplazar media de evidencia por placeholder
- mantener hyperlinks intactos
- restaurar media de logos

## Salida mínima recomendada de validación
Generar un resumen compacto con:
- total de placeholders `{{ ... }}` y referencias `photos`
- conteo por estado (`valid`, `format_error`, `invalid_key`, `unsupported_expression`, `ambiguous`, `context_conflict`)
- lista de cambios aplicados (`old -> new`) con ubicación (`file`, `rId`, `cell` o `anchor`)
- riesgos abiertos si quedó algo sin resolver

## Cuándo preguntar al usuario
Preguntar antes de aplicar si:
- hay más de un candidato semántico plausible para una referencia rota
- la estructura del JSON no permite inferencia confiable
- hay conflicto entre layout visual y mapping lógico
- una expresión requiere una función no soportada por el motor actual
- una migración de índices a claves humanas puede romper consistencia con otros bloques

## Comandos útiles
```bash
# Listar contenido interno del xlsx
unzip -l archivo.xlsx

# Extraer placeholders de texto/expresiones
rg -o -N "\{\{[^}]+\}\}" /tmp/xlsx/xl -g '*.xml'

# Extraer referencias photos
rg -o -N "answers\.[A-Za-z0-9_-]+\.photos\.[0-9]+" /tmp/xlsx/xl -g '*.xml' -g '*.rels'

# Detectar uso de funciones soportadas
rg -o -N "contains\([^)]*\)|isEqual\([^)]*\)|left\([^)]*\)|right\([^)]*\)|date_format\([^)]*\)" /tmp/xlsx/xl -g '*.xml'

# Detectar cláusulas if/else u or
rg -o -N "\"[^\"]+\" if [^}]+ else \"[^\"]+\"|[A-Za-z0-9_.-]+ or [A-Za-z0-9_.-]+" /tmp/xlsx/xl -g '*.xml'
```
