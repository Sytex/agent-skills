---
name: confirm-dialog
description: Implement confirmation dialogs using ConfirmDialogService. Use when asked to add confirmation for destructive actions, delete operations, or any user confirmation flow.
---

# Confirm Dialog Implementation

You are implementing a confirmation dialog using `ConfirmDialogService`.

**MANDATORY**: Always use `ConfirmDialogService` for all confirmation dialogs. Never create custom modal components for confirmations.

## When to Use

Use `ConfirmDialogService` whenever you need to:

- Confirm a destructive action (delete, remove, etc.)
- Ask for user confirmation before proceeding with an operation
- Show a confirmation dialog with custom options

---

## Implementation Steps

### Step 1: Import the Service

```typescript
import { ConfirmDialogService, ConfirmMessage } from '@sdk/index';
```

### Step 2: Inject in Constructor

```typescript
constructor(private _confirmDialogService: ConfirmDialogService) {}
```

Note: The service is provided globally. No need to add it to component providers.

### Step 3: Create Confirmation Method

```typescript
async onConfirmAction(): Promise<void> {
  const message: ConfirmMessage = {
    title: $localize`Action title?`,
    message: $localize`This action cannot be undone.`,
    options: [
      {
        label: $localize`:action|:Confirm`,
        value: '1',
        class: 'warn'
      }
    ]
  };

  const response = await this._confirmDialogService.send(message);
  if (response === '1') {
    // Proceed with the action
  }
}
```

---

## Message Format

| Property  | Type              | Description                                   |
| --------- | ----------------- | --------------------------------------------- |
| `title`   | `string`          | Dialog title (include action and entity name) |
| `message` | `string`          | Explanation of consequences                   |
| `options` | `ConfirmOption[]` | Action buttons                                |

### Option Properties

| Property | Type     | Description                                     |
| -------- | -------- | ----------------------------------------------- |
| `label`  | `string` | Button text (use i18n with `:action\|` context) |
| `value`  | `string` | Unique identifier (usually `'1'` for confirm)   |
| `class`  | `string` | CSS class: `'warn'`, `'accent'`, `'primary'`    |

---

## Examples

### Delete Example

```typescript
private async _deleteFile(): Promise<void> {
  const message: ConfirmMessage = {
    title: $localize`Delete file '${this.file.name}'?`,
    message: $localize`This operation can't be undone`,
    options: [
      {
        label: $localize`:action|:Confirm`,
        value: '1',
        class: 'accent'
      }
    ]
  };
  const response = await this._confirmDialogService.send(message);
  if (response === '1') {
    this._cubit.delete(this.file.id);
  }
}
```

### Remove Participant Example

```typescript
async onRemoveParticipant(participantId: string, type: ChatParticipantType): Promise<void> {
  const message: ConfirmMessage = {
    title: $localize`Remove participant '${displayName}'?`,
    message: $localize`This action cannot be undone. The participant will no longer have access to this conversation.`,
    options: [
      {
        label: $localize`:action|:Remove`,
        value: '1',
        class: 'warn'
      }
    ]
  };

  const response = await this._confirmDialogService.send(message);
  if (response === '1') {
    this.removeParticipant.emit({ chatId: this.chat()!.id, participantId, type });
  }
}
```

---

## Rules

1. **Never create custom modal components** for confirmations
2. **Service is global** - no need to add to providers
3. **Always use `$localize`** for all text
4. **Methods should be `async`** and return `Promise<void>`
5. **Use `:action|` context** for action button labels in i18n

---

## What NOT to Do

```typescript
// WRONG - Don't create custom modals
showConfirmModal = signal(false);

@if (showConfirmModal()) {
  <div class="modal-backdrop">
    <div class="modal-content">
      <!-- custom modal HTML -->
    </div>
  </div>
}
```

```typescript
// CORRECT - Use ConfirmDialogService
async onDelete(): Promise<void> {
  const message: ConfirmMessage = { /* ... */ };
  const response = await this._confirmDialogService.send(message);
  if (response === '1') {
    // proceed
  }
}
```

---

## Reference Files

- Service interface: `src/app/sdk/infrastructure/confirm-dialog.service.ts`
- Example usage: `src/app/ui/shared/file-explorer/file-item/file-item.component.ts`
- Example usage: `src/app/ui/chat/chat-details/chat-details.component.ts`
