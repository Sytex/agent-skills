---
name: discord-summary
description: Create a summary of recent changes and copy to clipboard for sharing on Discord
---

# Discord Summary

Create a concise summary of recent code changes for sharing with the team on Discord.

## Step 1: Analyze Recent Changes

Review what was changed in the current session. If unclear, run:

```bash
git diff --stat
git diff
```

## Step 2: Create Summary

Write a summary following this structure:

```
## {Tipo}: {Título corto del cambio}

**Problema:** {1-2 oraciones describiendo el bug o necesidad}

**Causa:** {Explicación breve de por qué ocurría, con código si ayuda}

**Solución:** {Qué se cambió para arreglarlo}

**Resultado:** {Comportamiento correcto ahora}
```

### Guidelines

- Keep it under 2000 characters (Discord limit)
- Use Spanish (team language)
- Be concise but clear
- Include small code snippets only if they help explain the issue
- Use markdown formatting (Discord supports it)
- Focus on the WHY, not just the WHAT

## Step 3: Copy to Clipboard

Copy the summary to clipboard using:

```bash
cat << 'EOF' | pbcopy
{summary content here}
EOF
```

Confirm to the user that it was copied.

## Example Output

```
## Bug: Permisos de WorkStructureTemplate ignoraban contexto de OU

**Problema:** Usuario con rol en 2 OUs (OU1 con `edit`, OU2 solo `view`) podía editar templates en OU2 donde no debería.

**Causa:** El `project_filter` tenía el permiso hardcodeado como `view`:
```python
allowed_ou = OperationalUnit.objects.with_perm(
    "projects.workstructuretemplate.view", ...  # Siempre VIEW
)
```

**Solución:** Pasar `accepted_ou` (OUs con el permiso correcto) al `project_filter`.

**Resultado:** Edit solo permite templates en OUs con permiso de edit.
```
