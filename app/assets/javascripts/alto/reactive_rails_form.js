/**
 * ReactiveRailsForm (RRF) v2.0 - Modern reactive forms for Rails
 *
 * Features:
 * - rf-* attributes for cleaner syntax
 * - Auto-initialization (no manual setup needed)
 * - Custom events for field changes, additions, and removals
 * - Template-free nested forms (clones first rendered item)
 * - Full Rails nested attributes support with auto field naming
 * - Efficient event delegation and memory management
 *
 * Usage:
 *   <div rf rf-model="project">
 *     <select rf-key="category">...</select>
 *     <div rf-show-if="category=engineering">...</div>
 *     <div rf-nest-for="tasks">
 *       <%= f.fields_for :tasks do |tf| %>
 *         <div rf-nest-item>...</div>
 *       <% end %>
 *     </div>
 *     <button rf-nest-add="tasks">Add Task</button>
 *   </div>
 */

// Constants for maintainability
const RF_CONSTANTS = {
  SELECTORS: {
    CONTAINER: '[rf]:not([rf-initialized])',
    REACTIVE_FIELD: '[rf-key]',
    CONDITIONAL: '[rf-show-if]',
    NEST_CONTAINER: '[rf-nest-for]',
    NEST_ITEM: '[rf-nest-item]',
    NEST_REMOVE: '[rf-nest-remove]',
    FORM_FIELDS: 'input, select, textarea',
    HIDDEN_INPUTS: 'input[type="hidden"][name*="_data"]'
  },
  FIELD_CLASSES: {
    LABEL: '.field-label',
    TYPE: '.field-type',
    REQUIRED: '.field-required',
    PLACEHOLDER: '.field-placeholder',
    OPTIONS_SELECT: '.field-options-select',
    OPTIONS_MULTISELECT: '.field-options-multiselect'
  },
  EVENTS: {
    FIELD_CHANGE: 'rf:field:change',
    FIELD_ADD: 'rf:field:add',
    FIELD_REMOVE: 'rf:field:remove',
    UPDATED: 'rf:updated',
    SERIALIZE: 'rf:serialize'
  },
  FIELD_TYPES: {
    HIDDEN: 'hidden',
    CHECKBOX: 'checkbox',
    RADIO: 'radio',
    TEXT: 'text',
    TEXTAREA: 'textarea'
  }
}

const ReactiveRailsForm = {
  // Global state management
  instances: new Map(),
  nextInstanceId: 1,

  // Auto-initialize all rf containers
  init() {
    document.querySelectorAll(RF_CONSTANTS.SELECTORS.CONTAINER).forEach(container => {
      this.createInstance(container)
    })
  },

  // Create a new RRF instance for a container
  createInstance(container) {
    const instanceId = this.nextInstanceId++
    const instance = new RFInstance(container, instanceId)

    this.instances.set(instanceId, instance)
    container.setAttribute('rf-initialized', instanceId)
    container._rfInstance = instance

    instance.init()
    return instance
  },

  // Get instance for a container
  getInstance(container) {
    const instanceId = container.getAttribute('rf-initialized')
    return instanceId ? this.instances.get(parseInt(instanceId)) : null
  },

  // Clean up instance
  destroyInstance(container) {
    const instance = this.getInstance(container)
    if (instance) {
      instance.destroy()
      this.instances.delete(instance.id)
      container.removeAttribute('rf-initialized')
      delete container._rfInstance
    }
  }
}

// Simple Signals system for predictable reactive updates
class RFSignals {
  constructor() {
    this.signals = new Map()
    this.effects = new Set()
    this.updateScheduled = false
  }

  // Create or get a signal
  signal(key, initialValue) {
    if (!this.signals.has(key)) {
      this.signals.set(key, {
        value: initialValue,
        subscribers: new Set()
      })
    }
    return {
      get: () => this.signals.get(key).value,
      set: (newValue) => this.setSignal(key, newValue),
      subscribe: (fn) => this.subscribe(key, fn)
    }
  }

  // Set signal value and notify subscribers
  setSignal(key, newValue) {
    const signal = this.signals.get(key)
    if (!signal || signal.value === newValue) return

    signal.value = newValue
    this.scheduleUpdate(() => {
      signal.subscribers.forEach(fn => {
        try {
          fn(newValue, signal.value)
        } catch (error) {
          console.error('Signal subscriber error:', error)
        }
      })
    })
  }

  // Subscribe to signal changes
  subscribe(key, fn) {
    const signal = this.signals.get(key)
    if (signal) {
      signal.subscribers.add(fn)
    }
    return () => signal?.subscribers.delete(fn)
  }

  // Batch updates using requestAnimationFrame
  scheduleUpdate(fn) {
    this.effects.add(fn)

    if (!this.updateScheduled) {
      this.updateScheduled = true
      requestAnimationFrame(() => {
        const effectsToRun = Array.from(this.effects)
        this.effects.clear()
        this.updateScheduled = false
        effectsToRun.forEach(effect => effect())
      })
    }
  }

  // Get current value without subscribing
  peek(key) {
    return this.signals.get(key)?.value
  }

  // Debug helper
  debug() {
    console.log('🎯 RF Signals State:', Object.fromEntries(
      Array.from(this.signals.entries()).map(([key, signal]) => [key, signal.value])
    ))
  }
}

class RFInstance {
  constructor(container, id) {
    this.container = container
    this.id = id
    this.listeners = []
    this.nestedCounters = new Map()
    this.modelName = container.getAttribute('rf-model') || 'model'
    this.signals = new RFSignals()
  }

  init() {
    this.setupReactiveFields()
    this.setupConditionalVisibility()
    this.setupNestedForms()
    this.setupAutoSerialization()
    this.logDebug('RRF instance initialized', { id: this.id, model: this.modelName })
  }

  destroy() {
    this.listeners.forEach(({ element, event, handler }) => {
      element.removeEventListener(event, handler)
    })
    this.listeners = []
    this.signals.signals.clear()
    this.signals.effects.clear()
    this.nestedCounters.clear()
  }

  // HELPER METHODS (DRY principle)

  // Add event listener with cleanup tracking
  addListener(element, event, handler, context = 'unknown') {
    const wrappedHandler = (e) => {
      try {
        handler(e)
      } catch (error) {
        this.logError(`Event handler error [${context}]`, error)
      }
    }

    element.addEventListener(event, wrappedHandler)
    this.listeners.push({ element, event, handler: wrappedHandler, context })
  }

  // Unified field detection helper - finds visible fields when multiple exist
  getFieldElements(item) {
    return {
      label: item.querySelector(`input${RF_CONSTANTS.FIELD_CLASSES.LABEL}, textarea${RF_CONSTANTS.FIELD_CLASSES.LABEL}`),
      type: item.querySelector(`select${RF_CONSTANTS.FIELD_CLASSES.TYPE}`),
      required: item.querySelector(`input${RF_CONSTANTS.FIELD_CLASSES.REQUIRED}`),
      placeholder: this.findVisibleField(item, `input${RF_CONSTANTS.FIELD_CLASSES.PLACEHOLDER}, textarea${RF_CONSTANTS.FIELD_CLASSES.PLACEHOLDER}`),
      options: this.findVisibleField(item, `textarea${RF_CONSTANTS.FIELD_CLASSES.OPTIONS_SELECT}, textarea${RF_CONSTANTS.FIELD_CLASSES.OPTIONS_MULTISELECT}`)
    }
  }

  // Find the field whose container is actually visible (handles multiple conditional fields)
  findVisibleField(item, selector) {
    const fields = item.querySelectorAll(selector)
    for (const field of fields) {
      if (this.isFieldContainerVisible(field)) {
        return field
      }
    }
    return null
  }

  // Unified visibility check
  isVisible(element) {
    return element?.offsetParent !== null && getComputedStyle(element).display !== 'none'
  }

  // Get appropriate event type for field
  getFieldEventType(field) {
    const { TEXT, TEXTAREA } = RF_CONSTANTS.FIELD_TYPES
    return (field.type === TEXT || field.type === TEXTAREA || field.tagName === 'TEXTAREA') ? 'input' : 'change'
  }

  // Unified event dispatching
  dispatchEvent(eventType, detail) {
    this.container.dispatchEvent(new CustomEvent(eventType, {
      bubbles: true,
      detail: { ...detail, instance: this }
    }))
  }

  // REACTIVE FIELDS SETUP

  setupReactiveFields() {
    this.container.querySelectorAll(RF_CONSTANTS.SELECTORS.REACTIVE_FIELD).forEach(field => {
      this.setupReactiveField(field)
    })
  }

  setupReactiveField(field) {
    const key = field.getAttribute('rf-key')
    if (!key) return

    const signal = this.createReactiveState(key, field.value)
    const eventType = this.getFieldEventType(field)

    this.addListener(field, eventType, () => {
      const newValue = field.value
      signal.set(newValue)
      this.dispatchEvent(RF_CONSTANTS.EVENTS.FIELD_CHANGE, { key, value: newValue, field })
      this.dispatchEvent(RF_CONSTANTS.EVENTS.UPDATED, {
        action: 'field_changed',
        data: { key, value: newValue, field },
        serializedData: this.previewSerialization()
      })
      this.previewSerialization()
    }, `reactive-${key}`)

    this.logDebug(`🎯 Reactive field registered: ${key}`, { value: field.value })
  }

  setupReactiveFieldsInElement(element) {
    element.querySelectorAll(RF_CONSTANTS.SELECTORS.REACTIVE_FIELD).forEach(field => {
      this.setupReactiveField(field)
    })
  }

  // Create reactive state with automatic conditional visibility updates
  createReactiveState(key, initialValue) {
    const signal = this.signals.signal(key, initialValue)
    signal.subscribe((newValue, oldValue) => {
      this.logDebug(`🎯 Signal ${key} changed: ${oldValue} → ${newValue}`)
      this.signals.scheduleUpdate(() => {
        this.updateConditionalVisibility()
        this.signals.debug()
      })
    })
    return signal
  }

  // CONDITIONAL VISIBILITY

  setupConditionalVisibility() {
    this.updateConditionalVisibility()
  }

  updateConditionalVisibility() {
    this.container.querySelectorAll(RF_CONSTANTS.SELECTORS.CONDITIONAL).forEach(element => {
      const condition = element.getAttribute('rf-show-if')
      const shouldShow = this.evaluateCondition(condition)

      if (shouldShow !== (element.style.display !== 'none')) {
        shouldShow ? this.showElement(element) : this.hideElement(element)
      }
    })
  }

  evaluateCondition(condition) {
    return condition.split(',')
      .map(c => c.trim())
      .some(cond => {
        const [key, value] = cond.split('=').map(s => s.trim())
        return this.signals.peek(key) === value
      })
  }

  showElement(element) {
    element.style.display = ''
    element.style.opacity = ''
    element.style.transition = ''
  }

  hideElement(element) {
    element.style.display = 'none'
    element.style.opacity = ''
    element.style.transition = ''
  }

  // NESTED FORMS

  setupNestedForms() {
    this.container.querySelectorAll(RF_CONSTANTS.SELECTORS.NEST_CONTAINER).forEach(nestedContainer => {
      const groupName = nestedContainer.getAttribute('rf-nest-for')
      if (!groupName) return

      this.initNestedGroup(nestedContainer, groupName)
      this.setupNestedAddButtons(groupName, nestedContainer)
      this.setupNestedRemoveButtons(nestedContainer, groupName)
    })
  }

  initNestedGroup(container, groupName) {
    const existingItems = container.querySelectorAll(RF_CONSTANTS.SELECTORS.NEST_ITEM)
    this.nestedCounters.set(groupName, existingItems.length)
    this.logDebug(`Nested form setup: ${groupName}`, { count: existingItems.length })
  }

  setupNestedAddButtons(groupName, container) {
    this.container.querySelectorAll(`[rf-nest-add="${groupName}"]`).forEach(addBtn => {
      this.addListener(addBtn, 'click', (e) => {
        e.preventDefault()
        this.addNestedItem(container, groupName)
      }, `nest-add-${groupName}`)
    })
  }

  setupNestedRemoveButtons(container, groupName) {
    this.addListener(container, 'click', (e) => {
      const removeBtn = e.target.closest(RF_CONSTANTS.SELECTORS.NEST_REMOVE)
      if (removeBtn) {
        e.preventDefault()
        const item = removeBtn.closest(RF_CONSTANTS.SELECTORS.NEST_ITEM)
        if (item) this.removeNestedItem(item, groupName)
      }
    }, `nest-remove-${groupName}`)
  }

  addNestedItem(container, groupName) {
    const template = container.querySelector(RF_CONSTANTS.SELECTORS.NEST_ITEM)
    if (!template) {
      this.logError('No template item found for nested form', { groupName })
      return
    }

    const currentIndex = this.nestedCounters.get(groupName)
    const newItem = template.cloneNode(true)

    this.processNewNestedItem(newItem, groupName, currentIndex)
    container.appendChild(newItem)
    this.nestedCounters.set(groupName, currentIndex + 1)

    this.finalizeNestedItem(newItem, groupName, currentIndex)
  }

  processNewNestedItem(newItem, groupName, index) {
    this.updateNestedFieldNames(newItem, groupName, index)
    this.clearFieldValues(newItem)
    this.logDebug(`🔄 Keys updated for ${groupName}[${index}]`)
  }

  finalizeNestedItem(newItem, groupName, index) {
    this.setupReactiveFieldsInElement(newItem)
    this.updateConditionalVisibility()

    this.dispatchEvent(RF_CONSTANTS.EVENTS.FIELD_ADD, { groupName, item: newItem, index })
    this.dispatchEvent(RF_CONSTANTS.EVENTS.UPDATED, {
      action: 'field_added',
      data: { groupName, item: newItem, index },
      serializedData: this.previewSerialization()
    })

    this.previewSerialization()
    this.logDebug(`Added nested item: ${groupName}[${index}]`)
  }

  removeNestedItem(item, groupName) {
    const destroyField = item.querySelector('input[name*="_destroy"]')
    const isDestroy = !!destroyField

    if (destroyField) {
      destroyField.value = '1'
      this.hideElement(item)
      this.disableRequiredFields(item)
      this.logDebug(`Marked for destruction: ${groupName}`)
    } else {
      item.remove()
      this.logDebug(`Removed from DOM: ${groupName}`)
    }

    this.dispatchEvent(RF_CONSTANTS.EVENTS.FIELD_REMOVE, { groupName, item, isDestroy })
    this.dispatchEvent(RF_CONSTANTS.EVENTS.UPDATED, {
      action: 'field_removed',
      data: { groupName, item, isDestroy },
      serializedData: this.previewSerialization()
    })
    this.previewSerialization()
  }

  // FIELD MANIPULATION

  updateNestedFieldNames(element, groupName, index) {
    this.updateFormFieldNames(element, groupName, index)
    this.updateReactiveFieldKeys(element, index)
    this.updateConditionalAttributes(element, index)
    this.updateFieldLabels(element, groupName, index)
  }

  updateFormFieldNames(element, groupName, index) {
    element.querySelectorAll(RF_CONSTANTS.SELECTORS.FORM_FIELDS).forEach(field => {
      if (field.name) {
        field.name = field.name.replace(
          new RegExp(`\\[${groupName}_attributes\\]\\[\\d+\\]`),
          `[${groupName}_attributes][${index}]`
        )
      }
      if (field.id) {
        field.id = field.id.replace(
          new RegExp(`_${groupName}_attributes_\\d+_`),
          `_${groupName}_attributes_${index}_`
        )
      }
    })
  }

  updateReactiveFieldKeys(element, index) {
    element.querySelectorAll(RF_CONSTANTS.SELECTORS.REACTIVE_FIELD).forEach(field => {
      const currentKey = field.getAttribute('rf-key')
      if (currentKey?.startsWith('field-type-')) {
        field.setAttribute('rf-key', `field-type-new-${index}`)
      }
    })
  }

  updateConditionalAttributes(element, index) {
    element.querySelectorAll(RF_CONSTANTS.SELECTORS.CONDITIONAL).forEach(conditionalElement => {
      const currentCondition = conditionalElement.getAttribute('rf-show-if')
      const updatedCondition = currentCondition.replace(/field-type-[^=]+=/g, `field-type-new-${index}=`)
      conditionalElement.setAttribute('rf-show-if', updatedCondition)
      this.logDebug(`Updated rf-show-if: ${currentCondition} → ${updatedCondition}`)
    })
  }

  updateFieldLabels(element, groupName, index) {
    element.querySelectorAll('label[for]').forEach(label => {
      const currentFor = label.getAttribute('for')
      if (currentFor) {
        label.setAttribute('for', currentFor.replace(
          new RegExp(`_${groupName}_attributes_\\d+_`),
          `_${groupName}_attributes_${index}_`
        ))
      }
    })
  }

  clearFieldValues(element) {
    element.querySelectorAll(RF_CONSTANTS.SELECTORS.FORM_FIELDS).forEach(field => {
      if (this.isDestroyField(field)) {
        field.value = 'false'
      } else if (field.type !== RF_CONSTANTS.FIELD_TYPES.HIDDEN) {
        this.clearFieldValue(field)
      }
    })
  }

  isDestroyField(field) {
    return field.type === RF_CONSTANTS.FIELD_TYPES.HIDDEN &&
           field.name?.includes('_destroy')
  }

  clearFieldValue(field) {
    const { CHECKBOX, RADIO, TEXTAREA } = RF_CONSTANTS.FIELD_TYPES

    if (field.tagName === 'SELECT') {
      field.selectedIndex = 0
    } else if (field.type === CHECKBOX || field.type === RADIO) {
      field.checked = false
    } else if (field.tagName === 'TEXTAREA') {
      this.clearTextareaValue(field)
    } else {
      this.clearInputValue(field)
    }
  }

  clearTextareaValue(field) {
    field.value = ''
    field.textContent = ''
    field.innerHTML = ''
    field.removeAttribute('value')
  }

  clearInputValue(field) {
    field.value = ''
    field.removeAttribute('value')
  }

  disableRequiredFields(element) {
    element.querySelectorAll('[required]').forEach(field => {
      field.removeAttribute('required')
      field.disabled = true
    })
  }

  // SERIALIZATION

  setupAutoSerialization() {
    const form = this.container.closest('form')
    if (!form) return

    this.createHiddenInputs(form)
    this.setupSerializationEvents(form)
  }

  createHiddenInputs(form) {
    this.container.querySelectorAll(RF_CONSTANTS.SELECTORS.NEST_CONTAINER).forEach(container => {
      const groupName = container.getAttribute('rf-nest-for')
      const inputName = `${this.modelName}[${groupName}_data]`

      if (!form.querySelector(`input[name="${inputName}"]`)) {
        const hiddenInput = document.createElement('input')
        Object.assign(hiddenInput, {
          type: 'hidden',
          name: inputName,
          id: `${groupName}-data-input`
        })
        form.appendChild(hiddenInput)
        this.logDebug(`Auto-created hidden input: ${inputName}`)
      }
    })
  }

  setupSerializationEvents(form) {
    const dataInputs = form.querySelectorAll(RF_CONSTANTS.SELECTORS.HIDDEN_INPUTS)
    if (dataInputs.length === 0) return

    this.addListener(form, 'submit', () => this.serializeToForm(form), 'auto-serialize')
    this.setupLivePreview()
    this.logDebug('Auto-serialization enabled', { inputs: dataInputs.length })
  }

  setupLivePreview() {
    const previewHandler = (e) => {
      const target = e.target
      if (target.closest(RF_CONSTANTS.SELECTORS.NEST_ITEM) &&
          target.matches(RF_CONSTANTS.SELECTORS.FORM_FIELDS) &&
          !target.matches(RF_CONSTANTS.SELECTORS.REACTIVE_FIELD)) {
        setTimeout(() => {
          this.previewSerialization()
          this.dispatchEvent(RF_CONSTANTS.EVENTS.UPDATED, {
            action: 'form_input',
            data: { field: target, value: target.type === 'checkbox' ? target.checked : target.value },
            serializedData: this.previewSerialization()
          })
        }, 0)
      }
    }

    this.addListener(this.container, 'input', previewHandler, 'live-preview')
    this.addListener(this.container, 'change', previewHandler, 'live-preview-change')
  }

  serializeToForm(form) {
    this.container.querySelectorAll(RF_CONSTANTS.SELECTORS.NEST_CONTAINER).forEach(nestedContainer => {
      const groupName = nestedContainer.getAttribute('rf-nest-for')
      const serializedData = this.serializeNestedGroup(groupName, nestedContainer)
      const hiddenInput = form.querySelector(`input[name*="${groupName}_data"]`)

      if (hiddenInput) {
        hiddenInput.value = JSON.stringify(serializedData)
        this.logDebug(`Serialized ${groupName}:`, serializedData)
      }
    })

    this.dispatchEvent(RF_CONSTANTS.EVENTS.SERIALIZE, { form })
  }

  previewSerialization() {
    const preview = {}
    this.container.querySelectorAll(RF_CONSTANTS.SELECTORS.NEST_CONTAINER).forEach(nestedContainer => {
      const groupName = nestedContainer.getAttribute('rf-nest-for')
      preview[groupName] = this.serializeNestedGroup(groupName, nestedContainer)
    })

    console.group(`🔥 RRF Live Preview - ${this.modelName}`)
    console.log('📦 Current form data:', preview)
    console.log('📤 JSON for backend:', JSON.stringify(preview, null, 2))
    console.groupEnd()

    return preview
  }

  serializeNestedGroup(groupName, container) {
    const items = container.querySelectorAll(RF_CONSTANTS.SELECTORS.NEST_ITEM)
    const serializedItems = []

    items.forEach((item, index) => {
      if (this.shouldSkipItem(item)) return

      const itemData = this.serializeItem(item, index)
      if (itemData && Object.keys(itemData).length > 0) {
        serializedItems.push(itemData)
      }
    })

    return serializedItems
  }

  shouldSkipItem(item) {
    const destroyField = item.querySelector('input[name*="_destroy"]')
    return destroyField?.value === '1' && item.style.display === 'none'
  }

  serializeItem(item, index) {
    const data = { position: index }
    const itemId = item.dataset.fieldId || item.querySelector('input[name*="[id]"]')?.value

    if (itemId) data.id = itemId

    const fields = this.getFieldElements(item)
    this.extractFieldData(fields, data)
    this.extractOtherFields(item, data)

    return data
  }

      extractFieldData(fields, data) {
    if (fields.label) data.label = fields.label.value || ''
    if (fields.type) data.field_type = fields.type.value || 'text_field'
    if (fields.required) data.required = fields.required.checked || false

    if (fields.placeholder) {
      data.placeholder = fields.placeholder.value || ''
      this.logDebug(`Found visible placeholder field: ${fields.placeholder.className}`, { value: data.placeholder })
    }

    if (fields.options) {
      data.options = fields.options.value || ''
      this.logDebug(`Found visible options field: ${fields.options.className}`, { value: data.options })
    }
  }

  // Check if the parent container of a form field is visible (has rf-show-if logic)
  isFieldContainerVisible(field) {
    const container = field.closest('[rf-show-if]')
    return !container || this.isVisible(container)
  }

  extractOtherFields(item, data) {
    const excludeClasses = ['field-label', 'field-required', 'field-placeholder', 'field-options']
    const excludeSelector = excludeClasses.map(cls => `:not(.${cls})`).join('')
    const selector = `input${excludeSelector}, select:not(.field-type), textarea:not([class*="field-options"])`

    item.querySelectorAll(selector).forEach(field => {
      if (!field.name || field.type === RF_CONSTANTS.FIELD_TYPES.HIDDEN) return

      const fieldName = this.extractFieldName(field.name)
      if (fieldName) {
        data[fieldName] = this.getFieldValue(field)
      }
    })
  }

  getFieldValue(field) {
    if (field.type === RF_CONSTANTS.FIELD_TYPES.CHECKBOX) {
      return field.checked
    } else if (field.type === 'number') {
      return field.value ? parseFloat(field.value) : null
    }
    return field.value
  }

  extractFieldName(fullName) {
    const match = fullName.match(/\[([^\]]+)\]$/)
    return match ? match[1] : null
  }

  // PUBLIC API

  serialize(options = {}) {
    const { format = 'json' } = options
    const data = {}

    if (this.signals.signals.size > 0) {
      data.state = Object.fromEntries(
        Array.from(this.signals.signals.entries()).map(([key, signal]) => [key, signal.value])
      )
    }

    this.container.querySelectorAll(RF_CONSTANTS.SELECTORS.NEST_CONTAINER).forEach(container => {
      const groupName = container.getAttribute('rf-nest-for')
      data[groupName] = this.serializeNestedGroup(groupName, container)
    })

    return format === 'rails' ? this.convertToRailsFormat(data) : data
  }

  convertToRailsFormat(data) {
    const railsData = {}
    Object.keys(data).forEach(key => {
      if (key === 'state') return

      const items = data[key]
      if (Array.isArray(items)) {
        railsData[`${key}_attributes`] = {}
        items.forEach((item, index) => {
          railsData[`${key}_attributes`][index] = item
        })
      }
    })
    return railsData
  }

  // UTILITIES

  logDebug(message, data = {}) {
    if (this.isDebugMode()) {
      console.log(`RRF[${this.id}]: ${message}`, data)
    }
  }

  logError(message, error) {
    console.error(`RRF[${this.id}] ERROR: ${message}`, error)
  }

  isDebugMode() {
    return window.location.hostname === 'localhost' ||
           window.location.hostname === '127.0.0.1' ||
           window.RRF_DEBUG === true
  }
}

// Auto-initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
  ReactiveRailsForm.init()
})

// Re-initialize when new content is added (Turbo compatibility)
document.addEventListener('turbo:render', () => {
  ReactiveRailsForm.init()
})

// Global access for debugging
window.RRF = ReactiveRailsForm
