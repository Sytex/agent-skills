# Slite CLI

CLI para conectar cualquier AI agent (Claude, Codex, Cursor, etc.) con tu knowledge base de Slite.

## Instalación

Decile a tu agente:

> "Instalá la skill de Slite que está en este zip"

O manualmente:

```bash
unzip slite-skill.zip
cd slite
./install.sh
```

## Configuración

Después de instalar, configurá tu API key:

```bash
~/.slite/config.sh setup
```

O decile a tu agente:
> "Corré el setup de Slite, te voy a dar mi API key"

### Obtener API Key

1. Entrá a tu workspace de Slite
2. Hacé click en tu avatar (esquina inferior izquierda)
3. Andá a **Settings → API**
4. Click en **Generate new token**
5. Copiá la key (solo se muestra una vez)

## Uso

### Con cualquier AI agent

Pedile a tu agente cosas como:

- "Buscá en Slite documentación sobre onboarding"
- "Mostrame la estructura de la sección de Engineering"
- "Preguntale a Slite cómo hacemos deployments"
- "Creá una nota en Slite con el resumen de esta reunión"

### Comandos directos

```bash
~/.slite/slite search "onboarding"
~/.slite/slite search "deploy" --parent abc123 --depth 2
~/.slite/slite tree abc123
~/.slite/slite ask "How do we deploy?" --parent abc123
~/.slite/slite get <noteId>
```

## Comandos disponibles

### Lectura

| Comando | Descripción |
|---------|-------------|
| `me` | Info del usuario |
| `search <query> [flags]` | Buscar notas |
| `ask <question> [--parent id]` | Preguntar a la IA |
| `list [parentId]` | Listar notas |
| `get <noteId> [md\|html]` | Obtener nota |
| `children <noteId>` | Notas hijas directas |
| `tree <noteId> [depth]` | Árbol de jerarquía |
| `search-users <query>` | Buscar usuarios |

### Flags de búsqueda

| Flag | Descripción |
|------|-------------|
| `--parent <id>` | Buscar dentro de una nota padre |
| `--depth <n>` | Profundidad (1-3) |
| `--include-archived` | Incluir archivadas |
| `--after <date>` | Editadas después de (ISO) |
| `--limit <n>` | Resultados por página |

### Escritura

| Comando | Descripción |
|---------|-------------|
| `create <title> [md] [parent]` | Crear nota |
| `update <noteId> [title] [md]` | Actualizar nota |
| `delete <noteId>` | Borrar nota |
| `archive <noteId> [bool]` | Archivar |
| `verify <noteId> [until]` | Verificar |
| `outdated <noteId> <reason>` | Marcar obsoleto |

## Best Practices

### Explorar la knowledge base
1. Usá `list` para ver las notas de nivel superior
2. Usá `tree <noteId>` para ver la estructura de una sección
3. Usá `get <noteId>` para leer el contenido

### Encontrar información
| Necesidad | Comando |
|-----------|---------|
| Buscar keyword | `search "keyword"` |
| Buscar en sección | `search "keyword" --parent <id>` |
| Respuesta IA | `ask "pregunta"` |
| Respuesta IA acotada | `ask "pregunta" --parent <id>` |
| Ver estructura | `tree <id>` |

### Flujo recomendado
```
list → tree → search/ask → get
```

1. **list**: Ver qué secciones hay
2. **tree**: Explorar estructura de una sección
3. **search/ask**: Buscar información específica
4. **get**: Leer el contenido completo

## Estructura

```
~/.slite/
├── slite        # CLI principal
├── config.sh    # Configuración de API key
└── .env         # API key (no compartir!)
```

Para usuarios de Claude Code, también se instala en `~/.claude/skills/slite/`.
