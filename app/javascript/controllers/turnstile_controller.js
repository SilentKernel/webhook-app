import { Controller } from "@hotwired/stimulus"

// Global state for script loading
let turnstileScriptLoaded = false
let turnstileScriptLoading = false

export default class extends Controller {
  static targets = ["container"]

  connect() {
    this.widgetId = null
    this.loadTurnstileScript().then(() => this.renderWidget())
  }

  disconnect() {
    // Clean up widget when controller disconnects (Turbo navigation)
    if (this.widgetId !== null && window.turnstile) {
      try {
        window.turnstile.remove(this.widgetId)
      } catch (e) {
        // Widget may already be removed
      }
      this.widgetId = null
    }
  }

  loadTurnstileScript() {
    return new Promise((resolve) => {
      if (turnstileScriptLoaded) {
        resolve()
        return
      }

      if (turnstileScriptLoading) {
        // Wait for script to load
        const checkLoaded = setInterval(() => {
          if (turnstileScriptLoaded) {
            clearInterval(checkLoaded)
            resolve()
          }
        }, 50)
        return
      }

      turnstileScriptLoading = true

      const script = document.createElement("script")
      script.src = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"
      script.async = true
      script.defer = true

      script.onload = () => {
        turnstileScriptLoaded = true
        resolve()
      }

      document.head.appendChild(script)
    })
  }

  renderWidget() {
    if (!this.hasContainerTarget || !window.turnstile) return

    const container = this.containerTarget
    const sitekey = container.dataset.sitekey
    const theme = container.dataset.theme || "auto"
    const size = container.dataset.size || "normal"

    // Clear any existing content
    container.innerHTML = ""

    this.widgetId = window.turnstile.render(container, {
      sitekey: sitekey,
      theme: theme,
      size: size,
      callback: (token) => this.onSuccess(token),
      "error-callback": () => this.onError(),
      "expired-callback": () => this.onExpired()
    })
  }

  onSuccess(token) {
    this.dispatch("success", { detail: { token } })
  }

  onError() {
    this.dispatch("error")
  }

  onExpired() {
    this.dispatch("expired")
  }

  // Reset widget (useful if form submission fails)
  reset() {
    if (this.widgetId !== null && window.turnstile) {
      window.turnstile.reset(this.widgetId)
    }
  }
}
