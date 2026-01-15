import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="source-form"
// Works with HotwireCombobox for Source Type and Verification Type dropdowns
export default class extends Controller {
  static targets = ["sourceType", "verificationType"]
  static values = {
    verificationTypes: Object, // Maps source_type_id to verification_type_id
    verificationTypeNames: Object // Maps verification_type_id to display name
  }

  connect() {
    // Set initial state if source type is already selected
    this.updateVerificationType()
  }

  sourceTypeChanged(event) {
    // Get the selected value from the hw-combobox:selection event detail
    const sourceTypeId = event?.detail?.value
    if (!sourceTypeId) return

    this.setVerificationTypeForSourceType(sourceTypeId)
  }

  updateVerificationType() {
    if (!this.hasSourceTypeTarget || !this.hasVerificationTypeTarget) return

    // HotwireCombobox uses a hidden input for the actual value
    // The target is the combobox container, find the hidden input within it
    const hiddenInput = this.sourceTypeTarget.querySelector('input[type="hidden"]')
    const sourceTypeId = hiddenInput?.value
    if (!sourceTypeId) return

    this.setVerificationTypeForSourceType(sourceTypeId)
  }

  setVerificationTypeForSourceType(sourceTypeId) {
    if (!this.hasVerificationTypeTarget) return

    const verificationTypeId = this.verificationTypesValue[sourceTypeId]
    if (!verificationTypeId) return

    // Find the hidden input and text input within the verification type combobox
    const hiddenInput = this.verificationTypeTarget.querySelector('input[type="hidden"]')
    const textInput = this.verificationTypeTarget.querySelector('input[type="text"]')

    if (hiddenInput) {
      hiddenInput.value = verificationTypeId
    }

    // Update the display text to match the selected verification type
    if (textInput) {
      const displayText = this.verificationTypeNamesValue[verificationTypeId.toString()]
      if (displayText) {
        textInput.value = displayText
      }
    }
  }
}
