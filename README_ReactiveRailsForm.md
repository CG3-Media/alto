# ReactiveRailsForm (RRF)

A minimal reactive form library for Rails applications that provides scoped reactive behavior with automatic cleanup.

## Features

- **Scoped Instances**: Each form gets its own isolated reactive state
- **Automatic Cleanup**: Memory leak prevention with proper listener management
- **Error Handling**: Graceful error handling that doesn't break user experience
- **Smooth Animations**: Subtle fade transitions for conditional fields
- **Development Debug**: Debug mode with state inspection in development
- **Rails Nested Attributes**: Full support for Rails nested attributes with automatic field naming
- **Dynamic Color Previews**: Built-in support for color field previews and dynamic content updates

## Usage

### Basic Usage

```html
<div data-rrf id="my-form">
  <select data-reactive="field-type">
    <option value="text">Text</option>
    <option value="number">Number</option>
  </select>

  <div data-show-when="field-type=text">
    Text field options...
  </div>

  <div data-show-when="field-type=number">
    Number field options...
  </div>
</div>
```

### Two Ways to Initialize

**Option 1: Auto-initialization (zero config)**
```html
<div data-rrf>
  <!-- Your form fields -->
</div>
```

**Option 2: Manual initialization (with custom handlers)**
```javascript
RRF.init('#my-form', {
  onFieldChange: ({ fieldName, field, fieldContainer, meta }) => {
    if (fieldName === 'color') {
      updateColorPreview(fieldContainer)
    }
  },

  onFieldAdd: ({ fieldContainer, meta }) => {
    setupCustomBehavior(fieldContainer)
  },

  onFieldRemove: ({ fieldContainer, isDestroy, meta }) => {
    console.log(isDestroy ? 'Marking for deletion' : 'Removing from DOM')
  }
})
```

**When to use which:**
- **Auto-init (`data-rrf`)**: Simple forms with standard RRF behavior
- **Manual init (`RRF.init()`)**: Forms needing custom logic (previews, validation, etc.)

### Data Attributes

- `data-rrf`: Auto-initialize container
- `data-reactive="key"`: Make field reactive
- `data-show-when="key=value"`: Conditional visibility
- `data-show-when="key=value1,key=value2"`: Multiple conditions
- `data-add-field="array-name"`: Add button for field arrays
- `data-field-array="array-name"`: Container for field arrays
- `data-remove-field`: Remove button for field items
- **Rails Nested Attributes**:
  - `data-nested-attributes="association_name"`: Container for nested attributes
  - `data-add-nested="association_name"`: Add button for nested fields
  - `data-nested-template`: Template for nested fields
  - `data-nested-field="field_name"`: Field within nested template
  - `data-remove-nested`: Remove button for nested fields
  - `data-nested-index`: Auto-set index for nested fields
  - `data-nested-title="{index}"`: Dynamic title with index placeholder
  - `data-color-preview`: Element for color preview updates
  - `data-nested-model="model_name"`: Override model name for field naming

### Field Arrays

```html
<div data-rrf>
  <div data-field-array="skills">
    <!-- Existing fields -->
  </div>

  <template id="field-template">
    <div data-field-template>
      <input type="text" data-reactive="skill-name">
      <button data-remove-field>Remove</button>
    </div>
  </template>

  <button data-add-field="skills">Add Skill</button>
</div>
```

### Development Debug

In development (localhost), access debug information:

```javascript
// Global access
window.RRF.state()        // Current state
window.RRF.listeners()    // Listener count

// Per-container access
container._rrf.state()    // Container-specific state
container._rrf.container  // Container reference
```

### Instance Methods

```javascript
const rrf = ReactiveRailsForm.create(container)

rrf.init()              // Auto-discover and initialize all reactive fields
rrf.destroy()           // Clean up everything
rrf.state()             // Access form state
rrf.computed(fn)        // Create computed property
rrf.enableDebug()       // Enable debug mode
```

### Internal Architecture

- **Auto-Discovery**: `init()` automatically finds all `[data-reactive]` fields and sets up reactivity
- **DRY Field Registration**: `registerField()` helper eliminates duplication in field setup
- **Concise Method Names**: `initReactives()`, `initArrays()`, `updateVisibility()`
- **Smart Cleanup**: Automatic cleanup registration when fields are created/destroyed

### Event Handlers

RRF provides event hooks for custom application logic:

```javascript
RRF.init('#my-form', {
  // Triggered when any field value changes
  onFieldChange: ({ fieldName, field, fieldContainer, meta }) => {
    console.log(`Field ${fieldName} changed to: ${field.value}`)

    // Custom logic based on field name
    if (fieldName === 'color') {
      updateColorPreview(fieldContainer)
    } else if (fieldName === 'name') {
      generateSlug(field, fieldContainer)
    }
  },

  // Triggered when a new nested field is added
  onFieldAdd: ({ fieldContainer, meta }) => {
    console.log(`New field added to ${meta.associationName}`)
    setupCustomValidation(fieldContainer)
  },

  // Triggered when a field is removed
  onFieldRemove: ({ fieldContainer, isDestroy, meta }) => {
    if (isDestroy) {
      console.log('Existing record marked for deletion')
    } else {
      console.log('New record removed from DOM')
    }
  }
})
```

**Event Parameters:**
- **onFieldChange**: `{ fieldName, field, fieldContainer, meta }`
- **onFieldAdd**: `{ fieldContainer, meta }`
- **onFieldRemove**: `{ fieldContainer, isDestroy, meta }`

**Meta Object**: `{ associationName, index, container }`

## Examples

### Conditional Field Visibility

```html
<div data-rrf>
  <select data-reactive="payment-method">
    <option value="credit-card">Credit Card</option>
    <option value="paypal">PayPal</option>
    <option value="bank">Bank Transfer</option>
  </select>

  <div data-show-when="payment-method=credit-card">
    <input type="text" placeholder="Card Number">
    <input type="text" placeholder="CVV">
  </div>

  <div data-show-when="payment-method=paypal">
    <input type="email" placeholder="PayPal Email">
  </div>

  <div data-show-when="payment-method=bank">
    <input type="text" placeholder="Account Number">
    <input type="text" placeholder="Routing Number">
  </div>
</div>
```

### Dynamic Field Arrays

```html
<div data-rrf id="contact-form">
  <div data-field-array="phone-numbers">
    <!-- Phone numbers will be added here -->
  </div>

  <template id="phone-template">
    <div data-field-template class="phone-entry">
      <select data-reactive="phone-type">
        <option value="mobile">Mobile</option>
        <option value="home">Home</option>
        <option value="work">Work</option>
      </select>
      <input type="tel" placeholder="Phone Number">
      <button data-remove-field>Remove</button>
    </div>
  </template>

  <button data-add-field="phone-numbers">Add Phone Number</button>
</div>
```

### Rails Nested Attributes

Perfect for Rails `accepts_nested_attributes_for` with automatic field naming and destroy handling:

```html
<div data-rrf data-nested-model="status_set">
  <!-- Container for nested statuses -->
  <div data-nested-attributes="statuses" class="space-y-4">
    <!-- Existing status fields render here -->
  </div>

  <!-- Template for new status fields -->
  <template id="statuses-template">
    <div data-nested-field data-nested-index class="status-field">
      <h4 data-nested-title="Status {index}">Status</h4>

      <input type="hidden" data-nested-field="_destroy" value="false">
      <input type="hidden" data-nested-field="position">

      <input type="text" data-nested-field="name" placeholder="Status Name" required>
      <input type="text" data-nested-field="slug" placeholder="slug">

      <select data-nested-field="color" data-reactive="color">
        <option value="green">🟢 Green</option>
        <option value="blue">🔵 Blue</option>
        <option value="red">🔴 Red</option>
      </select>

      <!-- Color preview -->
      <span data-color-preview class="badge">Status Name</span>

      <button type="button" data-remove-nested>Remove</button>
    </div>
  </template>

  <button type="button" data-add-nested="statuses">Add Status</button>
</div>
```

**Key Features:**
- **Automatic Field Naming**: Generates proper Rails nested attribute names like `status_set[statuses_attributes][0][name]`
- **Destroy Handling**: Automatically handles `_destroy` fields for existing records vs DOM removal for new records
- **Position Management**: Auto-sets position values for ordering
- **Color Previews**: Built-in color preview functionality with dynamic styling
- **Index Tracking**: Maintains proper indices even when fields are removed
- **Validation Handling**: Disables required validation when marking fields for destruction

## Browser Support

- Modern browsers (ES6+)
- Graceful degradation without JavaScript
- No external dependencies

## Integration with Rails

Include in your Rails application:

```erb
<%= javascript_include_tag 'reactive_rails_form' %>
```

Or in your layout:

```html
<script src="/assets/reactive_rails_form.js"></script>
```

## Performance

- Minimal footprint (~8KB uncompressed)
- Efficient event delegation
- Memory leak prevention
- Smart change detection (only updates when values change)
