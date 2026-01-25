import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="header-forwarding"
// Toggles visibility of specific headers input based on "forward all" checkbox
export default class extends Controller {
  static targets = ["specificHeaders"]

  connect() {
    this.toggle()
  }

  toggle() {
    if (!this.hasSpecificHeadersTarget) return

    const checkbox = this.element.querySelector('input[type="checkbox"][name*="forward_all_headers"]')
    if (!checkbox) return

    if (checkbox.checked) {
      this.specificHeadersTarget.classList.add("hidden")
    } else {
      this.specificHeadersTarget.classList.remove("hidden")
    }
  }
}
