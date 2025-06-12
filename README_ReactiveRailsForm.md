# ReactiveRailsForm (RRF) v2.0

A modern, zero-config, Rails-friendly reactive form library for dynamic forms with automatic serialization and event-driven updates.

---

## ✨ Features

- **rf-* attributes** for clean, declarative markup
- **Zero configuration**: just add `rf` to your form container
- **Auto-serialization**: automatically populates hidden fields on form submit
- **Rails nested attributes**: full support for `accepts_nested_attributes_for`
- **No templates needed**: clones the first rendered item as a template
- **Conditional visibility**: show/hide fields based on other field values
- **Real-time events**: `rf:updated` fires on any form change with serialized data
- **Turbo/Hotwire compatible**: auto-initializes on page change
- **Memory safe**: automatic cleanup of listeners

---

## 🚀 Quick Start

### Basic Rails Nested Form

```erb
<%= form_with model: @project, local: true do |f| %>
  <div rf rf-model="project" id="project-form">
    <%= f.label :category %>
    <%= f.select :category, [["General", "general"], ["Engineering", "engineering"]], {}, { 'rf-key': "category" } %>

    <div rf-show-if="category=engineering">
      <%= f.label :tech_lead %>
      <%= f.text_field :tech_lead %>
    </div>

    <div rf-nest-for="tasks">
      <%= f.fields_for :tasks do |tf| %>
        <div rf-nest-item>
          <%= tf.text_field :title %>
          <%= tf.date_field :due_date %>
          <%= tf.hidden_field :_destroy %>
          <button type="button" rf-nest-remove>Remove</button>
        </div>
      <% end %>
    </div>
    <button type="button" rf-nest-add="tasks">Add Task</button>
    <%= f.submit %>
  </div>
<% end %>
```

### Custom Data Structure (Non-Rails Models)

```html
<form>
  <div rf>
    <div rf-nest-for="fields">
      <div rf-nest-item>
        <input type="text" class="field-label" placeholder="Field name">
        <select class="field-type" rf-key="field-type-0">
          <option value="text_field">Text Input</option>
          <option value="select_field">Dropdown</option>
        </select>
        <div rf-show-if="field-type-0=text_field">
          <input type="text" class="field-placeholder-input" placeholder="Placeholder text">
        </div>
        <div rf-show-if="field-type-0=select_field">
          <textarea class="field-options-input" placeholder="Option 1&#10;Option 2"></textarea>
        </div>
        <button type="button" rf-nest-remove>Remove</button>
      </div>
    </div>
    <button type="button" rf-nest-add="fields">Add Field</button>

    <!-- RRF automatically populates this on form submit -->
    <input type="hidden" name="board[fields_data]" id="fields-data-input">
  </div>
</form>
```

---

## 🏷️ Attribute Reference

### Container
- `rf` — enables RRF on this container
- `rf-model="model_name"` — (optional) model name for debugging

### Reactive Fields
- `rf-key="field_name"` — makes a field reactive (updates state, triggers conditions)
- `rf-show-if="key=value"` — shows element if condition matches (supports multiple: `key1=value1,key2=value2`)

### Nested Groups
- `rf-nest-for="group_name"` — container for repeatable items
- `rf-nest-item` — a single item within the group (at least one required)
- `rf-nest-add="group_name"` — button to add new items
- `rf-nest-remove` — button to remove an item

---

## 🔄 Auto-Serialization

RRF automatically detects hidden inputs with `*_data` in their name and populates them on form submit:

```html
<!-- This gets auto-populated with JSON data -->
<input type="hidden" name="board[fields_data]" id="fields-data-input">
```

**Serialization works by:**
1. **CSS Class Detection**: Uses classes like `.field-label`, `.field-type`, `.field-required`
2. **Smart Type Conversion**: Booleans for checkboxes, numbers for number inputs
3. **Rails Integration**: Preserves existing record IDs and handles `_destroy` fields
4. **Position Tracking**: Maintains field ordering with position indexes

**Example Output:**
```json
[
  {
    "id": "123",
    "label": "Full Name",
    "field_type": "text_field",
    "required": true,
    "placeholder": "Enter your name",
    "position": 0
  }
]
```

---

## 📡 Events

### General Update Event
```js
// Fires on ANY form change with full serialized data
container.addEventListener('rf:updated', (e) => {
  console.log(`Action: ${e.detail.action}`, e.detail.serializedData)
  // Actions: 'field_added', 'field_removed', 'field_changed', 'form_input', 'form_change'
})
```

### Specific Events
```js
const form = document.getElementById('project-form')

form.addEventListener('rf:field:add', e => {
  // { groupName, item, index, instance }
})

form.addEventListener('rf:field:remove', e => {
  // { groupName, item, isDestroy, instance }
})

form.addEventListener('rf:field:change', e => {
  // { key, value, field, instance } - for rf-key fields
})

form.addEventListener('rf:serialize', e => {
  // Fires when form is submitted and data is serialized
})
```

---

## 🧑‍💻 How It Works

### No Templates Needed
The first `rf-nest-item` element is automatically cloned when adding new items. Values are cleared and field names/IDs are updated for Rails compatibility.

### Rails Nested Attributes
For Rails forms, RRF handles:
- Field name updates: `model[tasks_attributes][0][title]` → `model[tasks_attributes][1][title]`
- ID updates for labels and form fields
- `_destroy` field handling for existing records

### Conditional Visibility
Elements with `rf-show-if` automatically show/hide based on reactive field values:
```html
<div rf-show-if="category=engineering,type=complex">
  <!-- Shows when category=engineering OR type=complex -->
</div>
```

### Smart Serialization
RRF automatically:
- Detects form structure from CSS classes
- Converts data types appropriately
- Preserves existing record relationships
- Handles destroyed vs removed items
- Maintains field ordering

---

## 🛠️ Real-World Example: Dynamic Field Builder

```erb
<%= form_with model: @board, local: true do |f| %>
  <div rf id="field-customization-form">
    <div rf-nest-for="fields">
      <% @board.fields.each do |field| %>
        <div rf-nest-item data-field-id="<%= field.id %>">
          <input type="text" value="<%= field.label %>" class="field-label">
          <select class="field-type" rf-key="field-type-<%= field.id %>">
            <option value="text_field" <%= 'selected' if field.text_field? %>>Text Input</option>
            <option value="select_field" <%= 'selected' if field.select_field? %>>Dropdown</option>
          </select>
          <input type="checkbox" class="field-required" <%= 'checked' if field.required %>>

          <div rf-show-if="field-type-<%= field.id %>=text_field">
            <input type="text" class="field-placeholder-input" value="<%= field.placeholder %>">
          </div>

          <div rf-show-if="field-type-<%= field.id %>=select_field">
            <textarea class="field-options-input"><%= field.options_array.join("\n") %></textarea>
          </div>

          <button type="button" rf-nest-remove>Remove</button>
        </div>
      <% end %>
    </div>

    <button type="button" rf-nest-add="fields">Add Field</button>
    <input type="hidden" name="board[fields_data]">
    <%= f.submit %>
  </div>
<% end %>
```

---

## 🔧 Manual Serialization API

```js
// Get RRF instance
const container = document.querySelector('[rf]')
const rfInstance = ReactiveRailsForm.getInstance(container)

// Manual serialization
const data = rfInstance.serialize()                    // JSON format
const railsData = rfInstance.serialize({ format: 'rails' })  // Rails nested attributes format

// Current reactive state
console.log(rfInstance.state)  // Map of all rf-key values
```

---

## 🐛 Debugging

RRF provides comprehensive logging in development:

- **Auto-enabled**: localhost/127.0.0.1 automatically enable debug mode
- **Manual**: Set `window.RRF_DEBUG = true` to force debug mode
- **Live Preview**: Real-time console output showing serialized data
- **Event Tracking**: All events logged with context
- **Error Handling**: Graceful error handling with detailed logging

**Console Output Example:**
```
🔥 RRF Live Preview - board
📦 Current form data: { fields: [...] }
📤 JSON for backend: [prettified JSON]
```

---

## 📦 Installation

### Rails Asset Pipeline
```erb
<%= javascript_include_tag 'alto/reactive_rails_form' %>
```

### Direct Include
```html
<script src="path/to/reactive_rails_form.js"></script>
```

**No dependencies required** - works with vanilla JavaScript, Rails UJS, and Turbo/Hotwire.

---

## 🚦 Browser Support

- **Modern browsers** (ES6+ features used)
- **No polyfills needed** for supported browsers
- **Memory efficient** with automatic cleanup

---

## 🎯 Migration from v1.x

### Attribute Changes
- `data-rrf` → `rf`
- `data-reactive="key"` → `rf-key="key"`
- `data-show-when="key=value"` → `rf-show-if="key=value"`
- `data-nested-attributes="assoc"` → `rf-nest-for="assoc"`
- `data-add-nested="assoc"` → `rf-nest-add="assoc"`
- `data-remove-nested` → `rf-nest-remove`
- `data-nested-field` → `rf-nest-item`

### New Features in v2.0
- ✅ Auto-serialization (no manual form handling needed)
- ✅ `rf:updated` event for general form changes
- ✅ Simplified unified syntax (removed rf-field-array complexity)
- ✅ Real-time console preview during development
- ✅ Better Rails integration with proper field naming

---

## 🎉 That's it!

ReactiveRailsForm v2.0 makes dynamic Rails forms simple, powerful, and developer-friendly. No more complex JavaScript, no more manual serialization - just clean, declarative markup that works! 🚀
