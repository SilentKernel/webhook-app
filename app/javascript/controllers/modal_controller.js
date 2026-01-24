import { Controller } from "@hotwired/stimulus"

// Modal controller for Turbo Frame modals
// Handles auto-opening, focusing first input, closing on backdrop click, and clearing frame on close
export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    // Auto-open modal when connected
    if (this.hasDialogTarget) {
      this.dialogTarget.showModal()
      this.focusFirstInput()
    }
  }

  close() {
    if (this.hasDialogTarget) {
      this.dialogTarget.close()
    }
    this.clearTurboFrame()
  }

  // Close on backdrop click (click outside dialog content)
  backdropClick(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }

  // Close on Escape key
  keydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    }
  }

  focusFirstInput() {
    const input = this.element.querySelector("input:not([type='hidden']), select, textarea")
    if (input) {
      // Delay to ensure dialog is fully rendered
      setTimeout(() => input.focus(), 50)
    }
  }

  clearTurboFrame() {
    const turboFrame = document.getElementById("modal")
    if (turboFrame) {
      turboFrame.innerHTML = ""
    }
  }
}
