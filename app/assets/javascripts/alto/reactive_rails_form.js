/**
 * ReactiveRailsForm (RRF) - Minimal reactive forms for Rails
 * Provides scoped reactive behavior for form fields with automatic cleanup
 *
 * Usage:
 *   // Auto initialization
 *   <div data-rrf>...</div>
 *
 *   // Manual initialization with handlers
 *   RRF.init('#my-form', {
 *     onFieldChange: ({ fieldName, field, fieldContainer, meta }) => {
 *       // Handle field changes
 *     },
 *     onFieldAdd: ({ fieldContainer, meta }) => {
 *       // Handle new fields
 *     }
 *   })
 */
const ReactiveRailsForm = {
      // Manual initialization API (for custom handlers)
  init(selector, options = {}) {
    const container = typeof selector === 'string' ? document.querySelector(selector) : selector
    if (!container) {
      throw new Error(`ReactiveRailsForm: Could not find container with selector "${selector}"`)
    }

    const instance = this.create(container, options)
    instance.init()

    // Store instance on container for access
    container._rrf = instance
    container._rrfManualInit = true // Mark as manually initialized

    if (options.debug || (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')) {
      const debugInstance = instance.enableDebug()
      container._rrf = debugInstance
    }

    return instance
  },

  // Factory function to create scoped instances
  create(container, options = {}) {
    if (!container) {
      throw new Error('ReactiveRailsForm requires a container element')
    }

    const subs = new Map()
    const cleanup = new WeakMap()
    const listeners = new Map()
    let debug = false
    let fieldCounter = 1000

    // Event handlers from options
    const handlers = {
      onFieldChange: options.onFieldChange || null,
      onFieldAdd: options.onFieldAdd || null,
      onFieldRemove: options.onFieldRemove || null,
      ...options
    }

    // Enhanced error handling
    function safeExecute(context, fn, fallback = null) {
      try {
        return fn()
      } catch (error) {
        logError(context, error)
        return fallback
      }
    }

    function logError(context, error) {
      if (debug) {
        console.error(`RRF[${container.id || 'unnamed'}][${context}]:`, error)
      }
    }

    // Enhanced signal with better memory management
    function signal(initial) {
      let v = initial
      const get = () => v
      get.set = nv => {
        safeExecute('signal.set', () => {
          if (v !== nv) {
            v = nv
            const subscribers = subs.get(get)
            if (subscribers) {
              Array.from(subscribers).forEach(fn => {
                safeExecute('subscriber', () => fn(v))
              })
            }
          }
        })
      }

      get.cleanup = () => {
        if (subs.has(get)) {
          subs.delete(get)
        }
      }

      return get
    }

    function watch(get, fn) {
      safeExecute('watch.setup', () => {
        if (!subs.has(get)) subs.set(get, new Set())
        subs.get(get).add(fn)
        safeExecute('watch.initial', () => fn(get()))
      })
    }

    // Enhanced state management
    const formState = signal({})
    const computedCache = new Map()
    const nestedCounters = new Map() // Track indices for nested attributes

    function computed(fn) {
      if (!computedCache.has(fn)) {
        const computedSignal = signal(null)
        watch(formState, () => {
          const newValue = safeExecute('computed', fn)
          computedSignal.set(newValue)
        })
        computedCache.set(fn, computedSignal)
      }
      return computedCache.get(fn)
    }

    // Memory management helpers
    function addListener(element, event, handler, key) {
      if (!listeners.has(key)) {
        listeners.set(key, [])
      }

      const wrappedHandler = (e) => safeExecute(`listener.${event}`, () => handler(e))
      element.addEventListener(event, wrappedHandler)
      listeners.get(key).push({ element, event, handler: wrappedHandler })
    }

    function removeListeners(key) {
      if (listeners.has(key)) {
        listeners.get(key).forEach(({ element, event, handler }) => {
          safeExecute('removeListener', () => {
            element.removeEventListener(event, handler)
          })
        })
        listeners.delete(key)
      }
    }

    function cleanupElement(element) {
      safeExecute('cleanup', () => {
        const reactiveKey = element.dataset.reactive
        if (reactiveKey) {
          const state = { ...formState() }
          delete state[reactiveKey]
          formState.set(state)
          removeListeners(reactiveKey)
        }

        if (cleanup.has(element)) {
          cleanup.get(element)()
          cleanup.delete(element)
        }
      })
    }

    // Helper to register a reactive field with consistent setup
    function registerField(field, key, element = field) {
      safeExecute('registerField', () => {
        // Set initial state
        const state = { ...formState() }
        state[key] = field.value
        formState.set(state)

        // Add change listener if not already present
        if (!listeners.has(key)) {
          addListener(field, 'change', () => {
            const newState = { ...formState() }
            newState[key] = field.value
            formState.set(newState)
          }, key)
        }

        // Store cleanup function if element provided
        if (element && element !== field) {
          cleanup.set(element, () => {
            removeListeners(key)
          })
        }
      })
    }

    // Auto-generate initial state and setup reactive fields
    function initReactives() {
      container.querySelectorAll('[data-reactive]').forEach(field => {
        const key = field.dataset.reactive
        if (key) {
          registerField(field, key)
        }
      })

      // Watch for state changes and trigger conditional display
      watch(formState, (state) => {
        updateVisibility(state)
      })

      // Trigger initial display state
      updateVisibility(formState())
    }

    function updateVisibility(state) {
      container.querySelectorAll('[data-show-when]').forEach(element => {
        safeExecute('updateVisibility', () => {
          const condition = element.dataset.showWhen
          let shouldShow = false

          const conditions = condition.split(',')
          for (const cond of conditions) {
            const [field, value] = cond.trim().split('=')
            if (state[field] === value) {
              shouldShow = true
              break
            }
          }

          // Smooth visibility changes
          if (shouldShow && element.style.display === 'none') {
            element.style.display = ''
            element.style.opacity = '0'
            requestAnimationFrame(() => {
              element.style.transition = 'opacity 150ms ease'
              element.style.opacity = '1'
            })
          } else if (!shouldShow && element.style.display !== 'none') {
            element.style.transition = 'opacity 150ms ease'
            element.style.opacity = '0'
            setTimeout(() => {
              if (element.style.opacity === '0') {
                element.style.display = 'none'
              }
            }, 150)
          }
        })
      })
    }

    // Setup dynamic field arrays
    function initArrays() {
      container.querySelectorAll('[data-add-field]').forEach(button => {
        const arrayName = button.dataset.addField
        const arrayContainer = container.querySelector(`[data-field-array="${arrayName}"]`)
        const template = container.querySelector('#field-template') || document.getElementById('field-template')

        if (!arrayContainer || !template) {
          logError('initArrays', new Error(`Missing container or template for ${arrayName}`))
          return
        }

        addListener(button, 'click', () => {
          safeExecute('addField', () => {
            const newField = template.content.cloneNode(true)
            const fieldItem = newField.querySelector('.field-item')

            const uniqueId = `field-type-${fieldCounter++}`
            const selectField = newField.querySelector('select[data-reactive]')

            if (!selectField) {
              logError('addField', new Error('No select field found in template'))
              return
            }

            selectField.dataset.reactive = uniqueId

            // Update conditional show-when attributes
            newField.querySelectorAll('[data-show-when]').forEach(conditionalElement => {
              const currentCondition = conditionalElement.dataset.showWhen
              const updatedCondition = currentCondition.replace(/field-type-new/g, uniqueId)
              conditionalElement.dataset.showWhen = updatedCondition
            })

            arrayContainer.appendChild(newField)

            // Register the new field with cleanup
            registerField(selectField, uniqueId, fieldItem)

            const removeBtn = fieldItem.querySelector('[data-remove-field]')
            if (removeBtn) {
              addListener(removeBtn, 'click', () => {
                cleanupElement(fieldItem)
                fieldItem.remove()
              }, `${uniqueId}-remove`)
            }
          })
        }, `add-${arrayName}`)
      })

      // Scoped event delegation for remove buttons
      addListener(container, 'click', (e) => {
        if (e.target.closest('[data-remove-field]')) {
          const fieldItem = e.target.closest('.field-item')
          if (fieldItem) {
            cleanupElement(fieldItem)
            fieldItem.remove()
          }
        }
      }, 'scoped-remove')
    }

        // Rails nested attributes support
    function initNestedAttributes() {
      container.querySelectorAll('[data-nested-attributes]').forEach(arrayContainer => {
        const associationName = arrayContainer.dataset.nestedAttributes
        const addButton = container.querySelector(`[data-add-nested="${associationName}"]`)
        // Look for template inside container first, then document-wide
        let template = container.querySelector(`#${associationName}-template`) ||
                      container.querySelector('[data-nested-template]')

        if (!template) {
          template = document.querySelector(`#${associationName}-template`) ||
                    document.querySelector('[data-nested-template]')
        }

        if (!addButton || !template) {
          logError('initNestedAttributes', new Error(`Missing button or template for ${associationName}`))
          return
        }

        // Initialize counter from existing fields and set up their reactivity
        const existingFields = arrayContainer.querySelectorAll('[data-nested-field]')
        let counter = existingFields.length

        // Set up reactivity for existing server-rendered fields
        existingFields.forEach((fieldContainer, index) => {
          if (!fieldContainer.dataset.nestedIndex) {
            fieldContainer.dataset.nestedIndex = index
          }
          setupNestedFieldReactivity(fieldContainer, associationName, parseInt(fieldContainer.dataset.nestedIndex))
        })

        nestedCounters.set(associationName, counter)

        addListener(addButton, 'click', () => {
          safeExecute('addNestedField', () => {
            const currentCounter = nestedCounters.get(associationName)
            const newField = createNestedField(template, associationName, currentCounter)

            if (newField) {
              arrayContainer.appendChild(newField)
              nestedCounters.set(associationName, currentCounter + 1)

              // Setup reactive fields in the new nested field
              setupNestedFieldReactivity(newField, associationName, currentCounter)
            }
          })
        }, `add-nested-${associationName}`)
      })

      // Handle removal of nested fields
      addListener(container, 'click', (e) => {
        if (e.target.closest('[data-remove-nested]')) {
          const fieldContainer = e.target.closest('[data-nested-field]')
          if (fieldContainer) {
            handleNestedFieldRemoval(fieldContainer)
          }
        }
      }, 'remove-nested')
    }

    function createNestedField(template, associationName, index) {
      const templateContent = template.content.cloneNode(true)
      const fieldContainer = templateContent.querySelector('[data-nested-field]')

      if (!fieldContainer) {
        logError('createNestedField', new Error('Template must contain element with data-nested-field'))
        return null
      }

      // Set the nested index
      fieldContainer.dataset.nestedIndex = index

      // Replace field names for Rails nested attributes
      const fields = fieldContainer.querySelectorAll('input, select, textarea')
      fields.forEach(field => {
        const fieldName = field.dataset.nestedField
        if (fieldName) {
          field.name = `${container.dataset.nestedModel || 'model'}[${associationName}_attributes][${index}][${fieldName}]`
          field.id = `${container.dataset.nestedModel || 'model'}_${associationName}_attributes_${index}_${fieldName}`
        }
      })

      // Update labels to match new field IDs
      fieldContainer.querySelectorAll('label[for]').forEach(label => {
        const forAttr = label.getAttribute('for')
        if (forAttr && forAttr.includes('TEMPLATE')) {
          label.setAttribute('for', forAttr.replace(/TEMPLATE_\w+/g,
            `${container.dataset.nestedModel || 'model'}_${associationName}_attributes_${index}_${label.dataset.nestedField || 'field'}`))
        }
      })

      // Set computed values (like position)
      const positionField = fieldContainer.querySelector('[data-nested-field="position"]')
      if (positionField) {
        positionField.value = index
      }

      // Update dynamic content (like titles)
      const titleElement = fieldContainer.querySelector('[data-nested-title]')
      if (titleElement) {
        const titleTemplate = titleElement.dataset.nestedTitle
        titleElement.textContent = titleTemplate.replace('{index}', index + 1)
      }

      return fieldContainer
    }

        // Helper to trigger field change handlers
    function triggerFieldChangeHandler(field, fieldContainer, associationName, index) {
      if (handlers.onFieldChange) {
        safeExecute('fieldChangeHandler', () => {
          // Extract field name from data attribute or name attribute
          let fieldName = field.dataset.nestedField
          if (!fieldName && field.name) {
            // Extract from Rails field name pattern: model[association_attributes][index][field_name]
            const match = field.name.match(/\[([^\]]+)\]$/)
            fieldName = match ? match[1] : null
          }

          if (fieldName) {
            handlers.onFieldChange({
              fieldName,
              field,
              fieldContainer,
              meta: {
                associationName,
                index,
                container
              }
            })
          }
        })
      }
    }

    function setupNestedFieldReactivity(fieldContainer, associationName, index) {
      // Setup reactive fields within the nested field
      fieldContainer.querySelectorAll('[data-reactive]').forEach(field => {
        const reactiveKey = `${associationName}_${index}_${field.dataset.reactive}`
        registerField(field, reactiveKey, fieldContainer)
      })

      // Auto-detect and setup event handlers for all input fields
      const formFields = fieldContainer.querySelectorAll('input, select, textarea')
      formFields.forEach(field => {
        // Skip hidden fields and readonly fields unless they have data attributes
        if (field.type === 'hidden' && !field.dataset.nestedField) return
        if (field.readOnly && !field.dataset.nestedField) return

        const fieldName = field.dataset.nestedField ||
                         (field.name ? field.name.match(/\[([^\]]+)\]$/)?.[1] : null)

        if (fieldName) {
          // Setup change listener that triggers the handler
          const eventType = field.type === 'text' || field.tagName === 'TEXTAREA' ? 'input' : 'change'

          addListener(field, eventType, () => {
            triggerFieldChangeHandler(field, fieldContainer, associationName, index)
          }, `${fieldName}-${associationName}-${index}`)

          // Trigger initial handler call for existing values
          if (field.value) {
            triggerFieldChangeHandler(field, fieldContainer, associationName, index)
          }
        }
      })

      // Trigger onFieldAdd handler if provided
      if (handlers.onFieldAdd) {
        safeExecute('fieldAddHandler', () => {
          handlers.onFieldAdd({
            fieldContainer,
            meta: {
              associationName,
              index,
              container
            }
          })
        })
      }
    }

    function handleNestedFieldRemoval(fieldContainer) {
      safeExecute('handleNestedFieldRemoval', () => {
        const destroyField = fieldContainer.querySelector('input[name*="_destroy"]')

        // Trigger onFieldRemove handler if provided
        if (handlers.onFieldRemove) {
          handlers.onFieldRemove({
            fieldContainer,
            isDestroy: !!destroyField,
            meta: {
              container
            }
          })
        }

        if (destroyField) {
          // Existing record - mark for destruction
          destroyField.value = '1'

          // Disable required fields to prevent validation issues
          const requiredFields = fieldContainer.querySelectorAll('[required]')
          requiredFields.forEach(field => {
            field.removeAttribute('required')
            field.disabled = true
          })

          // Hide the field with smooth transition
          fieldContainer.style.transition = 'opacity 300ms ease'
          fieldContainer.style.opacity = '0'
          setTimeout(() => {
            fieldContainer.style.display = 'none'
          }, 300)
        } else {
          // New record - remove from DOM
          cleanupElement(fieldContainer)
          fieldContainer.remove()
        }
      })
    }

    // Instance cleanup
    function destroy() {
      formState.cleanup()
      computedCache.forEach(signal => signal.cleanup())
      listeners.clear()
      subs.clear()
      computedCache.clear()
    }

    // Initialize the instance
    function init() {
      safeExecute('init', () => {
        initReactives()
        initArrays()
        initNestedAttributes()
      })
    }

    // Development helper
    function enableDebug() {
      debug = true
      console.log(`RRF debug mode enabled for container: ${container.id || 'unnamed'}`)
      return {
        container: container,
        state: () => formState(),
        listeners: () => listeners.size,
        subscriptions: () => subs.size,
        cleanup: () => cleanup
      }
    }

    // Return the instance
    return {
      init,
      destroy,
      enableDebug,
      cleanup: cleanupElement,
      state: formState,
      computed
    }
  }
}

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
  autoInitializeRRF()
})

function autoInitializeRRF() {
  // Auto-initialize any containers with data-rrf attribute
  document.querySelectorAll('[data-rrf]').forEach(container => {
    // Skip if already manually initialized
    if (container._rrfManualInit) return

    initializeContainer(container)
  })

  // Legacy support for data-miniui attribute
  document.querySelectorAll('[data-miniui]').forEach(container => {
    // Skip if already manually initialized
    if (container._rrfManualInit) return

    initializeContainer(container)
  })

  // For backward compatibility, initialize the field customization form
  const fieldCustomizationContainer = document.querySelector('[data-field-array="custom-fields"]')?.closest('.space-y-4')
  if (fieldCustomizationContainer &&
      !fieldCustomizationContainer.hasAttribute('data-rrf') &&
      !fieldCustomizationContainer.hasAttribute('data-miniui') &&
      !fieldCustomizationContainer._rrfManualInit) {

    const rrf = ReactiveRailsForm.create(fieldCustomizationContainer)
    rrf.init()

    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
      window.RRF = rrf.enableDebug()
    }
  }
}

function initializeContainer(container) {
  const rrf = ReactiveRailsForm.create(container)
  rrf.init()

  // Enable debug in development
  if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    const debugInstance = rrf.enableDebug()
    // Store on container for access
    container._rrf = debugInstance
  } else {
    container._rrf = rrf
  }
}

// Global alias for convenience
window.RRF = ReactiveRailsForm
