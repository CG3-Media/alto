/**
 * Alto Image Upload Component
 * Vanilla JavaScript image upload with preview, validation, and removal
 * Works with Rails ActiveStorage direct uploads
 */

class AltoImageUpload {
  constructor(container) {
    this.container = container
    this.fileInput = container.querySelector('.image-file-input')
    this.uploadButton = container.querySelector('.upload-button-container')
    this.previewContainer = container.querySelector('.image-preview-container')
    this.previewImage = container.querySelector('.preview-image')
    this.loadingContainer = container.querySelector('.upload-loading')
    this.errorContainer = container.querySelector('.upload-error')
    this.removeField = container.querySelector('input[name*="remove_images"]')

    this.init()
  }

  init() {
    this.setupEventListeners()
    this.setupDirectUploadListeners()
  }

  setupEventListeners() {
    // Upload button click
    const uploadTrigger = this.container.querySelector('.upload-trigger')
    if (uploadTrigger) {
      uploadTrigger.addEventListener('click', () => this.triggerFileSelect())
    }

    // Replace button click
    const replaceButton = this.container.querySelector('.replace-button')
    if (replaceButton) {
      replaceButton.addEventListener('click', () => this.triggerFileSelect())
    }

    // Remove button click
    const removeButton = this.container.querySelector('.remove-button')
    if (removeButton) {
      removeButton.addEventListener('click', () => this.removeImage())
    }

    // File input change
    if (this.fileInput) {
      this.fileInput.addEventListener('change', (e) => this.handleFileSelect(e))
    }
  }

  setupDirectUploadListeners() {
    if (!this.fileInput) return

    this.fileInput.addEventListener('direct-upload:start', () => this.uploadStart())
    this.fileInput.addEventListener('direct-upload:progress', (e) => this.uploadProgress(e))
    this.fileInput.addEventListener('direct-upload:end', () => this.uploadEnd())
    this.fileInput.addEventListener('direct-upload:error', (e) => this.uploadError(e))
  }

  triggerFileSelect() {
    if (this.fileInput) {
      this.fileInput.click()
    }
  }

  handleFileSelect(event) {
    const file = event.target.files[0]
    if (!file) return

    // Validate file
    const validation = this.validateFile(file)
    if (!validation.valid) {
      this.showError(validation.message)
      this.fileInput.value = '' // Clear the input
      return
    }

    this.hideError()
    this.showPreview(file)
  }

  validateFile(file) {
    // Check file type
    const allowedTypes = ['image/png', 'image/jpeg', 'image/jpg']
    if (!allowedTypes.includes(file.type)) {
      return {
        valid: false,
        message: 'Please select a PNG or JPEG file.'
      }
    }

    // Check file size (10MB = 10 * 1024 * 1024 bytes)
    const maxSize = 10 * 1024 * 1024
    if (file.size > maxSize) {
      return {
        valid: false,
        message: 'File size must be less than 10MB.'
      }
    }

    return { valid: true }
  }

    showPreview(file) {
    // Create preview image
    const reader = new FileReader()
    reader.onload = (e) => {
      if (this.previewImage) {
        this.previewImage.src = e.target.result
        this.previewImage.alt = file.name
        // Show the image using Tailwind classes
        this.previewImage.classList.remove('hidden')
      }
    }
    reader.readAsDataURL(file)

    // Show preview, hide upload button
    this.hideElement(this.uploadButton)
    this.showElement(this.previewContainer)

    // Reset remove field
    if (this.removeField) {
      this.removeField.value = 'false'
    }
  }

    removeImage() {
    // Clear file input
    if (this.fileInput) {
      this.fileInput.value = ''
    }

    // Hide the preview image using Tailwind classes
    if (this.previewImage) {
      this.previewImage.classList.add('hidden')
      this.previewImage.src = ''
    }

    // Mark for removal if this was an existing image
    if (this.removeField) {
      this.removeField.value = 'true'
    }

    // Show upload button, hide preview
    this.hideElement(this.previewContainer)
    this.showElement(this.uploadButton)

    this.hideError()
    this.hideLoading()
  }

  uploadStart() {
    this.showLoading()
    this.hideError()
  }

  uploadProgress(event) {
    // Could add progress bar here if needed
    // Progress tracking available at event.detail.progress
  }

  uploadEnd() {
    this.hideLoading()
  }

  uploadError(event) {
    this.hideLoading()
    this.showError('Upload failed. Please try again.')

    // Reset to upload state
    this.removeImage()
  }

  showLoading() {
    this.showElement(this.loadingContainer)
    this.hideElement(this.uploadButton)
    this.hideElement(this.previewContainer)
  }

  hideLoading() {
    this.hideElement(this.loadingContainer)
  }

  showError(message) {
    if (this.errorContainer) {
      this.errorContainer.textContent = message
      this.showElement(this.errorContainer)
    }
  }

  hideError() {
    this.hideElement(this.errorContainer)
  }

  showElement(element) {
    if (element) {
      element.style.display = ''
    }
  }

  hideElement(element) {
    if (element) {
      element.style.display = 'none'
    }
  }
}

// Auto-initialize image upload components
function initializeImageUploads() {
  const components = document.querySelectorAll('.image-upload-component:not([data-initialized])')

  components.forEach(container => {
    new AltoImageUpload(container)
    container.setAttribute('data-initialized', 'true')
  })
}

// Initialize on DOM ready (works with all Rails versions)
document.addEventListener('DOMContentLoaded', () => {
  initializeImageUploads()
})

// Optional: Re-initialize if host app uses Turbo/Turbolinks
if (typeof Turbo !== 'undefined') {
  document.addEventListener('turbo:render', initializeImageUploads)
}
if (typeof Turbolinks !== 'undefined') {
  document.addEventListener('turbolinks:load', initializeImageUploads)
}

// Export for manual initialization if needed
window.AltoImageUpload = AltoImageUpload
window.initializeImageUploads = initializeImageUploads
