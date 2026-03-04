---
name: intercom-support
description: Analyze Intercom support conversations and generate structured notes with internal diagnosis and user-facing response suggestions. Use when analyzing a support conversation, generating a suggested response, or investigating a user issue from Intercom.
---

# Intercom Support Analysis

Workflow for analyzing support conversations and generating structured notes.

**IMPORTANT:** Everything you write MUST be in Spanish (both the internal analysis and the suggested response). Even if the user writes in Portuguese or any other language, ALWAYS respond in Spanish. The support team uses a live translator — we write in Spanish and the user reads in their language automatically.

---

## Output Format (MANDATORY)

Every analysis MUST produce a note with exactly these two sections:

### Section 1: Internal Analysis (for the support team)

```
🔍 ANÁLISIS INTERNO

Tipo: [configuración | bug | permisos | operativo | capacitación | solicitud de cambio]
Organización: [nombre de la org si se identifica]
Contacto: [nombre del contacto]

Contexto:
[Qué encontraste en la conversación, en Sytex, en el historial. Datos técnicos relevantes.]

Causa probable:
[Detalle técnico de lo que está pasando. Acá sí podés ser específico sobre errores, limitaciones o bugs.]

Casos similares:
[Si encontraste conversaciones anteriores relacionadas, mencionarlas con ID.]

Acción recomendada:
- [ ] Responder al usuario con la sugerencia de abajo
- [ ] Escalar a desarrollo (crear Linear)
- [ ] Fix manual en Sytex (detallar qué hacer)
- [ ] Requiere cambio de permisos/rol (detallar cuál)
```

### Section 2: Suggested Response (ready to copy and send to the user)

```
💬 RESPUESTA SUGERIDA

[Texto listo para copiar y enviar al usuario.
Este texto es lo que el agente de soporte va a mandar directamente.]
```

---

## Communication Rules (CRITICAL)

The suggested response MUST follow these rules strictly:

### NEVER expose internal issues

| Situation | NEVER say | SAY instead |
|---|---|---|
| System bug | "Hay un error en el sistema que ya conocemos" | "Entiendo el inconveniente. Vamos a resolverlo de nuestra parte y te avisamos cuando esté listo." |
| UI bug | "Hay un tema de interfaz que hace que no se muestre" | Give the user a workaround or steps, or confirm you'll handle it |
| Known limitation | "Es una limitación del sistema actualmente" | Provide the workaround directly |
| Internal error | "Estamos al tanto del problema" | "Vamos a revisar esto y te contactamos con una solución." |
| Missing config | "Falta configurar X en el sistema" | "Necesitamos ajustar una configuración. Lo resolvemos de nuestra parte." |

**Rule:** If it's a system error, bug, or internal limitation, the user doesn't need to know. The internal analysis section is where you document it. The suggested response focuses on the solution or next step for the user.

### Phrases BANNED from suggested responses

- "estamos al tanto"
- "hay un tema de..."
- "es un problema conocido"
- "hay un bug"
- "hay un error en el sistema"
- "es una limitación"
- "internamente vamos a..."
- Any reference to internal tools, databases, code, or technical infrastructure

### Communication profile

- **Amable**: tono respetuoso y humano
- **Cercano**: lenguaje claro, sin tecnicismos innecesarios
- **Explicativo**: siempre da contexto, no solo instrucciones mecánicas
- Prioriza **enseñar el paso a paso** al usuario
- Solo ofrece hacerlo por el usuario cuando hay limitación técnica real, pedido explícito, o caso crítico

### DO

- Divide instrucciones en pasos simples y numerados
- Confirma comprensión cuando el proceso es complejo
- Mantiene foco en la solución sin sobreextenderse
- Usa lenguaje natural y cercano

### DON'T

- No se ofrece a "lo hago por vos" automáticamente
- No agrega sugerencias adicionales no solicitadas
- No sobrecarga con información irrelevante
- No responde de forma fría o excesivamente técnica
- No expone errores o limitaciones internas del sistema

---

## Analysis Workflow

### Step 1: Read the conversation

```bash
intercom conversation <id>
```

Read ALL messages to understand:
- What the user is asking
- What has already been tried
- The user's tone and urgency
- The organization and contact info

### Step 2: Search for similar cases

```bash
intercom conversations-search "<keywords from the user's issue>"
intercom conversations --email <user_email> --limit 5
```

Check if:
- This user has reported this before
- Other users from the same org had similar issues
- There's a pattern worth noting

### Step 3: Cross-reference with Sytex (when relevant)

Use the `sytex` skill to:
- Verify user permissions and role
- Check task/form/project status related to the issue
- Look up organization configuration
- Identify if it's a permissions issue (suggest the correct role)

### Step 4: Generate the structured note

Produce the note following the exact output format above.

**Key decisions for the internal analysis:**
- If it's a bug → recommend creating a Linear issue in the action items
- If it's permissions → specify exactly which role/permission is needed
- If it's a recurring issue → flag it and link previous conversations
- If it requires manual fix → detail the exact steps for the support agent

**Key decisions for the suggested response:**
- If the user can solve it themselves → give step-by-step instructions
- If we need to fix it internally → tell them we'll handle it and follow up
- If it's a config/permissions change → tell them we're making the adjustment
- NEVER expose the technical root cause to the user

---

## Examples

### Example: User can't see a form

**Internal Analysis:**
```
🔍 ANÁLISIS INTERNO

Tipo: permisos
Organización: Claro AR
Contacto: Juan Pérez (juan.perez@claro.com)

Contexto:
El usuario no puede ver el formulario "Inspección de torre" en la app.
Verificado en Sytex: el usuario tiene rol "Técnico básico" que no incluye
acceso a formularios de inspección.

Causa probable:
Rol insuficiente. Necesita rol "Técnico inspector" o superior para acceder
al formulario de inspección.

Casos similares:
Conversación #45231 - mismo problema con otro técnico de Claro AR hace 2 semanas.

Acción recomendada:
- [ ] Responder al usuario con la sugerencia de abajo
- [x] Requiere cambio de permisos/rol: asignar rol "Técnico inspector"
```

**Suggested Response:**
```
💬 RESPUESTA SUGERIDA

Hola Juan! 👋

Revisamos tu caso y vemos que tu perfil necesita un ajuste para poder acceder al formulario de Inspección de torre.

Estamos haciendo el cambio ahora. En unos minutos deberías poder verlo correctamente.

¿Podrías cerrar la app y volver a abrirla cuando te avisemos? Así se actualizan los permisos.
```

### Example: System error (bug)

**Internal Analysis:**
```
🔍 ANÁLISIS INTERNO

Tipo: bug
Organización: Ufinet CO
Contacto: María López (maria.lopez@ufinet.com)

Contexto:
La usuaria reporta que al intentar enviar un formulario completado, la app
muestra pantalla en blanco y pierde los datos.
Verificado: el formulario tiene un campo condicional que cuando se activa
con más de 3 opciones, causa un error de rendering en la app.

Causa probable:
Bug en el frontend de la app mobile. El componente de selección múltiple
no maneja correctamente más de 3 opciones en campos condicionales.

Casos similares:
No se encontraron casos anteriores.

Acción recomendada:
- [x] Responder al usuario con la sugerencia de abajo
- [x] Escalar a desarrollo (crear Linear)
```

**Suggested Response:**
```
💬 RESPUESTA SUGERIDA

Hola María! 👋

Lamentamos el inconveniente. Ya identificamos qué está pasando con el formulario y lo estamos resolviendo.

Mientras tanto, te comparto una alternativa para que no pierdas el trabajo:

1. Completá el formulario hasta el campo donde se produce el problema
2. Guardá como borrador antes de llegar a ese punto
3. Nuestro equipo va a aplicar la corrección y te avisamos cuando esté lista

Cualquier duda, escribinos.
```
