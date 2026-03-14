# Shared UI Components Reference

Detailed inputs/outputs for all shared components in `src/app/ui/shared/`.

---

## Form Controls (`ui/shared/fields/`)

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-input` | `value: string`, `label?: string`, `placeholder?: string`, `type: 'text' \| 'number' \| 'email' \| 'password' \| 'tel'`, `size: 'small' \| 'medium' \| 'large'`, `disabled: boolean`, `readonly: boolean`, `invalid: boolean`, `required: boolean`, `autofocus: boolean`, `alwaysShowLabel: boolean`, `min: string`, `max: string`, `step: string`, `autocomplete: string`, `mask: InputMaskSettings` | `valueChange`, `changeEvent`, `updateEvent`, `keydownEvent`, `blurEvent` |
| `app-textarea` | `value: string`, `label?: string`, `placeholder?: string`, `size: 'small' \| 'medium' \| 'large'`, `minRows: number`, `maxRows: number`, `disabled: boolean`, `readonly: boolean`, `invalid: boolean`, `required: boolean`, `autofocus: boolean`, `resizable: boolean`, `alwaysShowLabel: boolean` | `valueChange`, `changeEvent`, `updateEvent`, `keydownEvent`, `pasteEvent` |
| `app-date` | `value?: string`, `label?: string`, `placeholder?: string`, `size: 'small' \| 'medium' \| 'large'`, `disabled: boolean`, `min?: string`, `max?: string`, `clear?: boolean`, `alwaysShowLabel: boolean` | `valueChange`, `changeEvent`, `updateEvent`, `inputFocus`, `blurEvent` |
| `app-time` | `value?: string`, `label?: string`, `placeholder?: string`, `size: 'small' \| 'medium' \| 'large'`, `disabled: boolean`, `min: string`, `max: string`, `clear?: boolean`, `alwaysShowLabel: boolean` | `valueChange`, `inputFocus` |
| `app-date-time` | `value: DateTime \| undefined \| null`, `label: string`, `size: 'small' \| 'medium' \| 'large'`, `disabled: boolean` | `valueChange: DateTime \| null`, `dateChange: string`, `timeChange: string` |
| `app-select` | `selectedOption: SelectOption \| undefined`, `options: SelectOption[]`, `loadingOptions: boolean`, `placeholder?: string`, `disabled: boolean`, `label: string`, `canOpen: boolean`, `required: boolean`, `canClear: boolean`, `alwaysShowLabel: boolean`, `size: 'small' \| 'medium' \| 'large'`, `fixedOptions: boolean`, `showSelectedItemCode: boolean`, `useCustomDisplayTemplate: boolean`, `groups: SelectOptionGroup[]` | `selectedOptionChange: SelectOption \| undefined`, `updateOptions: string`, `selectedOptionOpen`, `closeSelect` |
| `app-checkbox` | `checked: boolean`, `disabled: boolean`, `halfChecked: boolean` | `checkedChange: boolean` |
| `app-radio` | `name: string`, `value: any`, `checked: boolean`, `disabled: boolean` | `valueChange: any`, `radioBlur` |
| `app-switch` | `value: boolean`, `disabled: boolean` | `valueChange: boolean` |
| `app-slider` | `value: number`, `min: number`, `max: number`, `step: number`, `label?: string`, `disabled: boolean`, `markers: SliderMarker[]` | `valueChange: number`, `changeEvent: number`, `markerClick: number` |
| `app-chips` | `selectedOptions: ChipOption[]`, `options: ChipOption[]`, `loadingOptions: boolean`, `label?: string`, `placeholder?: string`, `size: 'small' \| 'medium' \| 'large'`, `disabled: boolean`, `required: boolean`, `alwaysShowLabel: boolean`, `emptySearchMessage: string`, `noResultsMessage: string` | `selectedOptionsChange: ChipOption[]`, `updateOptions: string` |
| `app-rating` | `rating: number`, `max: number`, `readonly: boolean` | `ratingChange: number` |
| `app-field-group` | *(content projection)* | *(none)* |
| `app-params-input` | *(key-value pairs)* | *(value changes)* |
| `app-json-editor` | *(JSON content)* | *(value changes)* |
| `app-markdown-editor` | *(markdown content)* | *(value changes)* |
| `app-code-editor` | *(code content)* | *(value changes)* |

---

## Layout (`ui/shared/layout/`)

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-row` | `gap?: string`, `align: 'start' \| 'center' \| 'end' \| 'stretch' \| 'baseline'`, `justify: 'start' \| 'center' \| 'end' \| 'space-between' \| 'space-around' \| 'space-evenly'` | *(none)* |
| `app-column` | `gap?: string`, `align?: 'start' \| 'center' \| 'end' \| 'stretch' \| 'baseline'`, `justify?: 'start' \| 'center' \| 'end' \| 'space-between' \| 'space-around' \| 'space-evenly'` | *(none)* |

---

## Typography (`ui/shared/text/`)

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-text` | `type: TextType` (title3, title4, caption, headline), `text: string`, `color?: string` | *(none)* |

---

## Buttons and Menus

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-button` | `type: string`, `tooltip: string`, `active: boolean`, `highlighted: boolean`, `on: boolean`, `hover: boolean`, `disabled: boolean` | `btnClick: MouseEvent` |
| `app-options-menu` | `items: (OptionMenuGroup \| OptionMenuItem)[]`, `disabled: boolean`, `hideItemIcon: boolean`, `openWithMouse: boolean`, `buttonClass?: string` | `selectOption: OptionMenuItem`, `menuOpen`, `menuClose` |

---

## Feedback and Overlays

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-modal` | `minWidth: string`, `maxWidth: string`, `hideHeader: boolean`, `hideCloseButton: boolean`, `positionStrategy: PositionStrategy`, `keybindings: KeyBindingMap \| undefined` | `closeByBackdrop`, `closeByEscape`, `closeByButton`, `closeModal` |
| `app-feedback-modal` | *(none)* | `closeModal`, `sendFeedback` |
| `app-progress-bar` | `progress: number` | *(none)* |
| `app-progress-circle` | `percentage: number` (required), `size: number` | *(none)* |
| `app-tag` | *(content projection)* | *(none)* |
| `app-status-pill-display` | `status: StatusPillDisplay` (required) — `{ name: string, color: string }` | *(none)* |
| `app-key-bind-hint` | *(keybinding config)* | *(none)* |
| `app-multiple-update-result` | *(update results)* | *(none)* |

---

## Pagination

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-paginator` | `currentPage: number`, `total: number`, `limit: number`, `limitOptions: number[]`, `disabled: boolean`, `limitedMessage: boolean`, `loading: boolean` | `pageChanged: number`, `limitChanged: number`, `getTotalCount` |
| `app-search-window-paginator` | `currentPage: number`, `total: number`, `limit: number`, `limitOptions: number[]`, `disabled: boolean`, `limitedMessage: boolean`, `loading: boolean` | `pageChanged: number`, `limitChanged: number`, `getTotalCount` |

---

## File and Media

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-file-dropper` | `multiple: boolean`, `accept: string` | `filesSelected: File[]` |
| `app-file-selector` | `accept: string`, `multiple: boolean`, `readonly: boolean` | `filesSelected: File[]` |
| `app-file-explorer` | *(provided via contentType/objectId providers)* | *(file operations)* |
| `app-image-cropper` | *(image source)* | *(cropped image)* |
| `app-audio-player` | `src: string` (required) | *(none)* |
| `app-signature-pad` | `width: number`, `height: number` | `signatureChange: string` |
| `app-selected-definition-image-item` | `contentType`, `entityId`, `fileId`, `imageFit`, `imageSize`, `imageAlignment` | `fileUploaded` |

---

## User and Avatar

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-avatar` | `avatar: string \| undefined`, `name: string`, `size: number \| string` | *(none)* |
| `app-user-avatar-status` | `userId: string` (required), `name: string`, `avatar: string \| undefined`, `size: number \| string` | *(none)* |
| `app-profile-header` | `scrolled: boolean`, `sections`, `name: string`, `position: string`, `email: string`, `code: string`, `currentAvatarUrl: string`, `contentType`, `entityId`, `showLegacyWindowButton: boolean` | `sectionClick`, `avatarFileSelected`, `avatarRemove`, `avatarUploaded`, `openLegacyWindow`, `codeChange` |
| `app-avatar-edit-modal` | *(image data)* | *(avatar result)* |
| `app-user-permissions` | *(user data)* | *(none)* |
| `app-user-roles` | *(user data)* | *(none)* |
| `app-user-stock` | *(user data)* | *(none)* |

---

## Maps and Location

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-map` | `elements: MapElements` (required), `openOnClick: boolean`, `autoFitBounds: boolean`, `initialCoordinatesBound: CoordinatesBound \| undefined` | `boundsChange: CoordinatesBound`, `openDetail: string` |
| `app-static-map` | `coordinates: Coordinates[]` | *(none)* |
| `app-location-picker-map` | `coordinates: Coordinates \| undefined` | `coordinatesChange: Coordinates` |

---

## Calendar

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-calendar` | `events: EventInput[]` | `itemClick: string`, `viewChange: CalendarSelectedView` |

---

## Search Infrastructure

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-search-header` | `qFilterProperty?: FilterNameType`, `disableHeader: boolean`, `disableSavedViews: boolean`, `disableContainsText: boolean`, `sorting?: ColumnSort`, `savedViewContext: SavedViewContext`, `selectedView?: SavedView`, `filters: FilterDisplay[]`, `selectedFilters: SearchFilterConfigurationField[]`, `displayedColumns: string[]`, `columnConfigurations: Record<string, SavedViewColumnConfiguration>`, `visualizationMode: SearchVisualizationOption`, `coordinatesBound?: CoordinatesBound`, `searchOnInit: boolean`, `disabled: boolean` | `performSearch`, `selectedViewChange: SavedView \| undefined`, `selectedFiltersChange: SearchFilterConfigurationField[]`, `searchFilterChange: SearchFilterItem[]`, `initialVisualizationModeSet: SearchVisualizationMode` |
| `app-result-list` | `resultItems: ResultItem[]`, `displayedColumns: string[]`, `columns: TableColumn[]`, `sort: ColumnSort \| undefined`, `disableSelection: boolean` | `sortChange: ColumnSort`, `resultItemToggle: ResultItem`, `resultItemClick: ResultItem`, `resultItemDoubleClick: ResultItem`, `resultItemsSelect`, `resultItemsDeselect`, `emptyAreaClick`, *(plus value change outputs per renderer type)* |
| `app-visualization-mode-selector` | `visualizationOptions: SearchVisualizationOption[]`, `selectedVisualizationMode: SearchVisualizationOption`, `disabled: boolean`, `onlyShowIcon: boolean`, `buttonClass?: string` | `visualizationModeSelect: SearchVisualizationMode` |
| `app-customize-columns` | *(column configuration)* | *(column changes)* |
| `app-more-filters` | *(filter configuration)* | *(filter changes)* |
| `app-filter-display` | *(active filters)* | *(filter actions)* |
| `app-saved-views-selector` | `disabled: boolean`, `savedViewContext: SavedViewContext` | `viewSelect: SavedView` |
| `app-selected-view-display` | `disabled: boolean`, `selectedView: SavedView` | `favoriteChange`, `update`, `delete` |
| `app-save-as-view` | `disabled: boolean` | `saveView` |

---

## Search Filter Selectors (`ui/shared/search/`)

| Selector | Purpose |
|----------|---------|
| `app-chip-selector` | Multi-select chip-based filter value selection |
| `app-text-selector` | Text value filter selection |
| `app-text-input-selector` | Text input with apply button |
| `app-date-selector` | Date value filter selection |
| `app-boolean-selector` | Boolean value filter selection |
| `app-status-selector` | Status filter selection |
| `app-fixed-options-selector` | Fixed options filter selection |
| `app-generic-entity-selector` | Generic entity search/select |
| `app-approval-step-name-selector` | Approval step name selection |
| `app-selection-options-bar` | Bulk selection actions bar |
| `app-selection-options-dialog` | Bulk selection options dialog |
| `app-date-range-selector` | Date range picker |
| `app-custom-field-name-selector` | Custom field name selection |

---

## Search Renderers (`ui/shared/search-renderers/`)

Cell renderers used inside `app-result-list`:

| Selector | Purpose |
|----------|---------|
| `app-text-renderer` | Text cell |
| `app-date-renderer` | Date cell |
| `app-avatar-renderer` | Avatar cell |
| `app-status-renderer` | Status cell |
| `app-status-step-renderer` | Status step cell |
| `app-chips-renderer` | Chips cell |
| `app-choices-renderer` | Choices cell |
| `app-boolean-renderer` | Boolean cell |
| `app-rating-renderer` | Rating cell |
| `app-progress-renderer` | Progress bar cell |
| `app-duration-renderer` | Duration cell |
| `app-file-link-renderer` | File link cell |
| `app-generic-entity-renderer` | Generic entity cell |

---

## Status and Workflow

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-status-editor` | *(status data)* | *(status changes)* |
| `app-status-step-editor` | *(status step data)* | *(step changes)* |

---

## Quick Views

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-task-quick-view` | `taskId: string`, `readonly: boolean` | `closeQuickView`, `openFullView`, `updateTask` |
| `app-milestone-quick-view` | *(milestone data)* | *(milestone actions)* |
| `app-error-list-quick-view` | *(error data)* | *(none)* |

---

## Activity Logs (`ui/shared/activity-logs/`)

| Selector | Purpose |
|----------|---------|
| `app-activity-logs` | Activity log list container |
| `app-activity-log-group` | Group of activity log items |
| `app-activity-log-item` | Single activity log entry |
| `app-activity-log-text` | Text content for activity logs |

---

## AI and Templates

| Selector | Key Inputs | Key Outputs |
|----------|------------|-------------|
| `app-ai-chat-assistant` | `config: AssistantConfig`, `suggestions: string[]`, `showFullscreenButton: boolean`, `defaultFullscreen: boolean` | `closeRequest`, `contentActionClicked`, `conversationLoaded`, `messageChange`, `userMessageSent` |
| `app-template-library` | *(template config)* | `templateUse`, `templateCreated` |

---

## Other Utilities

| Selector | Purpose |
|----------|---------|
| `app-generate-password` | Password generator |
| `app-set-new-password` | Set new password form |
| `app-quick-add-staff` | Quick add staff dialog |
| `app-quick-add-supplier-resource` | Quick add supplier resource dialog |
