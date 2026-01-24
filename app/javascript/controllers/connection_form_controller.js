import { Controller } from "@hotwired/stimulus"

// Connection form controller for managing edit links visibility
export default class extends Controller {
  static targets = ["sourceSelect", "sourceEditLink", "destinationSelect", "destinationEditLink"]
  static values = {
    sourceEditPath: String,
    destinationEditPath: String
  }

  connect() {
    this.updateSourceEditLink()
    this.updateDestinationEditLink()
  }

  sourceChanged() {
    this.updateSourceEditLink()
  }

  destinationChanged() {
    this.updateDestinationEditLink()
  }

  updateSourceEditLink() {
    if (!this.hasSourceSelectTarget || !this.hasSourceEditLinkTarget) return

    const selectedId = this.sourceSelectTarget.value
    if (selectedId) {
      const editPath = this.sourceEditPathValue.replace("__ID__", selectedId)
      this.sourceEditLinkTarget.href = editPath
      this.sourceEditLinkTarget.classList.remove("hidden")
    } else {
      this.sourceEditLinkTarget.classList.add("hidden")
    }
  }

  updateDestinationEditLink() {
    if (!this.hasDestinationSelectTarget || !this.hasDestinationEditLinkTarget) return

    const selectedId = this.destinationSelectTarget.value
    if (selectedId) {
      const editPath = this.destinationEditPathValue.replace("__ID__", selectedId)
      this.destinationEditLinkTarget.href = editPath
      this.destinationEditLinkTarget.classList.remove("hidden")
    } else {
      this.destinationEditLinkTarget.classList.add("hidden")
    }
  }
}
