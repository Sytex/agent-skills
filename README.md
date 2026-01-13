# Agent Skills

Skills para agentes de IA (Claude Code, Codex, Cursor, etc.) del equipo de Sytex.

## Skills disponibles

| Skill | Descripción |
|-------|-------------|
| [slite](./skills/slite) | Conecta con la knowledge base de Slite |

## Instalación

### Opción 1: Decirle al agente

> "Instalá la skill de Slite que está en este repo"

### Opción 2: Manual

```bash
cd skills/<skill-name>
./install.sh
```

## Estructura

```
agent-skills/
├── README.md
└── skills/
    └── slite/
        ├── install.sh
        ├── README.md
        ├── SKILL.md        # Para Claude Code
        └── scripts/
            ├── api.sh
            └── config.sh
```

## Agregar una nueva skill

1. Crear carpeta en `skills/<nombre>/`
2. Incluir `install.sh` para instalación
3. Incluir `README.md` con documentación
4. Opcional: `SKILL.md` para Claude Code
