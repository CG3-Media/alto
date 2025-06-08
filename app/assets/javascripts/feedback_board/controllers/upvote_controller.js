import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="upvote"
export default class extends Controller {
  static targets = ["button", "count", "icon"]
  static values = {
    upvoted: Boolean,
    count: Number,
    url: String
  }

  connect() {
    this.updateAppearance()
  }

  async toggle(event) {
    event.preventDefault()

    // Disable button during request
    this.buttonTarget.disabled = true
    this.addLoadingState()

    try {
      const method = this.upvotedValue ? 'DELETE' : 'POST'
      const response = await this.makeRequest(method)

      if (response.ok) {
        const data = await response.json()
        this.upvotedValue = data.upvoted
        this.countValue = data.upvotes_count
        this.updateAppearance()
      } else {
        this.showError()
      }
    } catch (error) {
      console.error('Upvote request failed:', error)
      this.showError()
    } finally {
      this.buttonTarget.disabled = false
      this.removeLoadingState()
    }
  }

  async makeRequest(method) {
    const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

    return fetch(this.urlValue, {
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': token,
        'Accept': 'application/json'
      }
    })
  }

  updateAppearance() {
    // Update count
    if (this.hasCountTarget) {
      this.countTarget.textContent = this.countValue
    }

    // Update button appearance
    if (this.hasButtonTarget) {
      if (this.upvotedValue) {
        this.setActiveState()
      } else {
        this.setInactiveState()
      }
    }
  }

  setActiveState() {
    // Remove inactive classes
    this.buttonTarget.classList.remove('text-gray-400', 'hover:text-blue-600', 'hover:bg-blue-50')

    // Add active classes
    this.buttonTarget.classList.add('bg-blue-50', 'text-blue-600', 'hover:bg-blue-100')

    // Update icon if present
    if (this.hasIconTarget) {
      this.iconTarget.classList.add('text-blue-600')
      this.iconTarget.classList.remove('text-gray-400')
    }
  }

  setInactiveState() {
    // Remove active classes
    this.buttonTarget.classList.remove('bg-blue-50', 'text-blue-600', 'hover:bg-blue-100')

    // Add inactive classes
    this.buttonTarget.classList.add('text-gray-400', 'hover:text-blue-600', 'hover:bg-blue-50')

    // Update icon if present
    if (this.hasIconTarget) {
      this.iconTarget.classList.remove('text-blue-600')
      this.iconTarget.classList.add('text-gray-400')
    }
  }

  addLoadingState() {
    if (this.hasButtonTarget) {
      this.buttonTarget.classList.add('opacity-50', 'cursor-wait')
    }
  }

  removeLoadingState() {
    if (this.hasButtonTarget) {
      this.buttonTarget.classList.remove('opacity-50', 'cursor-wait')
    }
  }

  showError() {
    // Simple error feedback - could be enhanced with toast notifications
    if (this.hasButtonTarget) {
      this.buttonTarget.classList.add('animate-pulse')
      setTimeout(() => {
        this.buttonTarget.classList.remove('animate-pulse')
      }, 1000)
    }
  }
}
