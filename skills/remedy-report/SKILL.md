---
name: remedy-report
description: >-
  Generate Remedy automation reports for TMA (org 217). Use when user asks about
  Remedy errors, novedades CRQ, automation failures, or monthly Remedy reports.
  Triggers: "reporte remedy", "informe remedy", "errores remedy", "novedades CRQ",
  "automatizaciones TMA", "remedy report".
version: 1.0.0
argument-hint: "[monthly|errors|novedades] [--days N] [--date-from YYYY-MM-DD] [--date-to YYYY-MM-DD]"
allowed-tools:
  - Bash(~/.claude/skills/remedy-report/*:*)
  - Bash(~/.claude/skills/sytex/*:*)
  - Read
---

# Remedy Report Skill

Generate reports for Remedy automations in TMA (Telefonica Movil Argentina), org 217 on `app.sytex.io`.

## Usage

```bash
~/.claude/skills/remedy-report/remedy-report <command> [options]
```

## Commands

| Command | Description |
|---------|-------------|
| `errors` | Error report: all failed executions with task details |
| `novedades` | Novedades CRQ report: all CRQ status change transactions |
| `monthly` | Full monthly executive report (Word + Excel with all data) |
| `summary` | Quick text summary to stdout (no Excel) |

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--days N` | Look back N days from today | 7 |
| `--date-from YYYY-MM-DD` | Start date (overrides --days) | |
| `--date-to YYYY-MM-DD` | End date | today |
| `--automations UUID,...` | Filter by specific automation UUIDs | all 8 Remedy |
| `--templates ID,...` | Filter by task template IDs | 1334,1610 |
| `--output DIR` | Output directory for generated files | /tmp/remedy-reports |

## Examples

```bash
# Last 7 days error report
~/.claude/skills/remedy-report/remedy-report errors

# Novedades CRQ for specific dates
~/.claude/skills/remedy-report/remedy-report novedades --date-from 2026-03-25 --date-to 2026-03-26

# Full monthly report for March 2026
~/.claude/skills/remedy-report/remedy-report monthly --date-from 2026-03-01 --date-to 2026-03-31

# Quick summary, last 3 days
~/.claude/skills/remedy-report/remedy-report summary --days 3

# Only Novedades CRQ automation
~/.claude/skills/remedy-report/remedy-report errors --automations b39ed83d-210a-416f-a1f0-3e6f2947286c
```

## Known Automations (TMA org 217)

```
UUID                                  Name
37f15c5e-3f06-472f-8d3e-27b9bbb734b5 Autorizar con CRQ
bc5fecc5-855b-4491-b670-66a0068af4ed Autorizar con CRQ (2)
20ac46bc-748c-4b55-a9e8-7df2b269ba49 Autorizar sin CRQ
eecb4e75-b321-422c-b987-935e3dd9206f Inicio tarea Remedy
af16da40-97d3-4a97-895e-5bd9f2990897 Inicio tarea Remedy GE
fc68e2f0-ae5f-465d-9c05-49ed33693a2a Fin tarea Remedy
56ad9f1c-1a59-4e04-a103-c7a5c0ef20a8 Fin tarea Remedy GE
b39ed83d-210a-416f-a1f0-3e6f2947286c Novedades CRQ
```

## Output

The script outputs JSON to stdout with:
- `files`: list of generated file paths (Excel, Word)
- `summary`: text summary with counts
- `data`: raw data (when --format json)

## Post-generation: Upload to Discord

After the script runs, upload files to Discord:
```bash
source ~/.agent-skills/send-message/.env
curl -s -X POST "https://discord.com/api/v10/channels/${CHANNEL_ID}/messages" \
  -H "Authorization: Bot ${DISCORD_TOKEN}" \
  -F 'payload_json={"content":"...summary text..."}' \
  -F "files[0]=@/path/to/file.xlsx;filename=Report.xlsx"
```

## Step Name Resolution

The script auto-resolves step IDs to names using the Sytex API.
Status flow ID 2075 (OyM MP v2). Known mappings cached in script:

```
name_id  Name
5353     Pendiente de Planificar
6057     Planificada
6058     Pendiente de Autorizacion
6060     Programado
6064     Iniciada en campo
6065     Finalizado en campo
```

Fresh mappings fetched via: `sytex get '/statusstep/?status_flow=2075&limit=200'`
