import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="source-form"
export default class extends Controller {
  static targets = ["sourceType", "verificationType"]
  static values = {
    verificationTypes: Object // Maps source_type_id to verification_type
  }

  connect() {
    // Set initial state if source type is already selected
    this.updateVerificationType()
  }

  sourceTypeChanged() {
    this.updateVerificationType()
  }

  updateVerificationType() {
    if (!this.hasSourceTypeTarget || !this.hasVerificationTypeTarget) return

    const sourceTypeId = this.sourceTypeTarget.value
    if (!sourceTypeId) return

    const verificationType = this.verificationTypesValue[sourceTypeId]
    if (verificationType) {
      this.verificationTypeTarget.value = verificationType
    }
  }
}
