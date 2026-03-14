---
name: shared-components
description: Catalog of reusable shared UI components in ui/shared/. Use when creating or modifying UI components, templates, or HTML to ensure existing shared components are used instead of creating new ones or using native HTML elements.
---

# Shared UI Components

## Core Directive

Before creating any UI element, **always check if a shared component already exists** in `src/app/ui/shared/`. Never recreate functionality that is already available. When in doubt, explore `ui/shared/` subdirectories.

When using a shared component for the first time, **read its `.ts` file** to understand its inputs, outputs, and usage patterns.

## Component Catalog

### Form Controls (`ui/shared/fields/`)

| Selector | Purpose |
|----------|---------|
| `app-input` | Text input with label, validation, size variants |
| `app-textarea` | Multi-line text input with auto-resize |
| `app-date` | Date picker |
| `app-time` | Time picker |
| `app-date-time` | Combined date + time input |
| `app-select` | Searchable dropdown with groups and options |
| `app-checkbox` | Checkbox with half-checked state |
| `app-radio` / `app-radio-group` | Radio buttons |
| `app-switch` | Toggle switch |
| `app-slider` | Numeric slider with optional markers |
| `app-chips` | Multi-select chips with search |
| `app-rating` | Star rating input |
| `app-params-input` | Key-value parameter input |
| `app-json-editor` | JSON editor |
| `app-markdown-editor` | Markdown editor |
| `app-code-editor` | Code editor |
| `app-field-group` | Field grouping wrapper |

### Layout (`ui/shared/layout/`)

| Selector | Purpose |
|----------|---------|
| `app-row` | Flex row container (gap, align, justify) |
| `app-column` | Flex column container (gap, align, justify) |

### Typography (`ui/shared/text/`)

| Selector | Purpose |
|----------|---------|
| `app-text` | Typography component (title3, title4, caption, headline) |

### Buttons and Menus

| Selector | Location | Purpose |
|----------|----------|---------|
| `app-button` | `ui/shared/button/` | Button with style/color/size variants |
| `app-options-menu` | `ui/shared/options-menu/` | Dropdown menu with grouped items |

### Feedback and Overlays

| Selector | Location | Purpose |
|----------|----------|---------|
| `app-modal` | `ui/shared/modal/` | Overlay modal with backdrop |
| `app-feedback-modal` | `ui/shared/feedback-modal/` | Feedback form modal |
| `app-progress-bar` | `ui/shared/progress-bar/` | Horizontal progress bar |
| `app-progress-circle` | `ui/shared/progress-circle/` | Circular progress indicator |
| `app-tag` | `ui/shared/tag/` | Tag/badge display |
| `app-status-pill-display` | `ui/shared/status-pill-display/` | Status pill with color |
| `app-key-bind-hint` | `ui/shared/key-bind-hint/` | Keyboard shortcut hint |
| `app-multiple-update-result` | `ui/shared/multiple-update-result/` | Bulk update results display |

### Pagination

| Selector | Location | Purpose |
|----------|----------|---------|
| `app-paginator` | `ui/shared/paginator/` | Pagination controls |
| `app-search-window-paginator` | `ui/shared/search-window-paginator/` | Pagination for search windows |

### File and Media

| Selector | Location | Purpose |
|----------|----------|---------|
| `app-file-dropper` | `ui/shared/file-dropper/` | Drag-and-drop file upload area |
| `app-file-selector` | `ui/shared/file-selector/` | File picker button |
| `app-file-explorer` | `ui/shared/file-explorer/` | File/folder browser with upload |
| `app-image-cropper` | `ui/shared/image-cropper/` | Image cropping tool |
| `app-audio-player` | `ui/shared/audio-player/` | Audio player with controls |
| `app-signature-pad` | `ui/shared/signature-pad/` | Signature capture pad |
| `app-selected-definition-image-item` | `ui/shared/selected-definition-image-item/` | Image upload/display for definitions |

### User and Avatar

| Selector | Location | Purpose |
|----------|----------|---------|
| `app-avatar` | `ui/shared/avatar/` | User avatar with initials fallback |
| `app-user-avatar-status` | `ui/shared/user-avatar-status/` | Avatar with online status indicator |
| `app-profile-header` | `ui/shared/profile-header/` | Profile header with avatar and tabs |
| `app-avatar-edit-modal` | `ui/shared/avatar-edit-modal/` | Avatar upload/edit modal |
| `app-user-permissions` | `ui/shared/user-permissions/` | User permissions display |
| `app-user-roles` | `ui/shared/user-roles/` | User roles display |
| `app-user-stock` | `ui/shared/user-stock/` | User stock display |

### Maps and Location

| Selector | Location | Purpose |
|----------|----------|---------|
| `app-map` | `ui/shared/map/` | Interactive map |
| `app-static-map` | `ui/shared/static-map/` | Static map image |
| `app-location-picker-map` | `ui/shared/location-picker-map/` | Map for picking coordinates |

### Calendar

| Selector | Location | Purpose |
|----------|----------|---------|
| `app-calendar` | `ui/shared/calendar/` | Calendar view with events |

### Search Infrastructure

| Selector | Location | Purpose |
|----------|----------|---------|
| `app-search-header` | `ui/shared/search-header/` | Search header with filters, views, actions |
| `app-more-filters` | `ui/shared/search-header/more-filters/` | Additional filters panel |
| `app-filter-display` | `ui/shared/search-header/filter-display/` | Active filter chips display |
| `app-saved-views-selector` | `ui/shared/search-header/saved-views-selector/` | Saved views dropdown |
| `app-result-list` | `ui/shared/result-list/` | Search result table with column renderers |
| `app-visualization-mode-selector` | `ui/shared/visualization-mode-selector/` | View mode switcher (list/map/calendar/board) |
| `app-customize-columns` | `ui/shared/customize-columns/` | Column customization dialog |

### Search Filter Selectors (`ui/shared/search/`)

Specialized selectors for search filter values:

`app-chip-selector`, `app-text-selector`, `app-text-input-selector`, `app-date-selector`, `app-boolean-selector`, `app-status-selector`, `app-fixed-options-selector`, `app-generic-entity-selector`, `app-approval-step-name-selector`, `app-selection-options-bar`, `app-date-range-selector`

### Search Renderers (`ui/shared/search-renderers/`)

Cell renderers for `app-result-list` columns:

`app-text-renderer`, `app-date-renderer`, `app-avatar-renderer`, `app-status-renderer`, `app-status-step-renderer`, `app-chips-renderer`, `app-choices-renderer`, `app-boolean-renderer`, `app-rating-renderer`, `app-progress-renderer`, `app-duration-renderer`, `app-file-link-renderer`, `app-generic-entity-renderer`

### Status and Workflow

| Selector | Location | Purpose |
|----------|----------|---------|
| `app-status-editor` | `ui/shared/status-editor/` | Status editing |
| `app-status-step-editor` | `ui/shared/status-step-editor/` | Status step editing |

### Quick Views

| Selector | Location | Purpose |
|----------|----------|---------|
| `app-task-quick-view` | `ui/shared/task-quick-view/` | Task quick view panel |
| `app-milestone-quick-view` | `ui/shared/milestone-quick-view/` | Milestone quick view panel |
| `app-error-list-quick-view` | `ui/shared/error-list-quick-view/` | Error list quick view |

### Activity Logs (`ui/shared/activity-logs/`)

`app-activity-logs`, `app-activity-log-group`, `app-activity-log-item`, `app-activity-log-text`

### AI and Templates

| Selector | Location | Purpose |
|----------|----------|---------|
| `app-ai-chat-assistant` | `ui/shared/ai-chat-assistant/` | AI chat assistant panel |
| `app-template-library` | `ui/shared/template-library/` | Template library browser |

### Other Utilities

| Selector | Location | Purpose |
|----------|----------|---------|
| `app-generate-password` | `ui/shared/generate-password/` | Password generator |
| `app-set-new-password` | `ui/shared/set-new-password/` | Set new password form |
| `app-quick-add-staff` | `ui/shared/quick-add-staff/` | Quick add staff dialog |
| `app-quick-add-supplier-resource` | `ui/shared/quick-add-supplier-resource/` | Quick add supplier resource |

## Detailed Reference

For comprehensive inputs/outputs of each component, see [reference.md](reference.md).
