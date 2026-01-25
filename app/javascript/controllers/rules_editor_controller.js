import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rules-editor"
// Provides a visual UI for editing connection rules (event type filters and delays)
export default class extends Controller {
  static targets = [
    "hiddenField",         // Hidden input storing JSON
    "eventTypeInput",      // Text input for new event type
    "eventTypesContainer", // Container for badge chips
    "delayInput",          // Number input for delay seconds
    "importSelect"         // Dropdown to select connection to import from
  ]

  static values = {
    rules: { type: Array, default: [] },      // Current rules state
    connections: { type: Array, default: [] } // Other connections for import
  }

  connect() {
    this.parseInitialRules()
    this.renderEventTypes()
    this.renderDelay()
  }

  // Value change callback - automatically serialize when rules change
  rulesValueChanged() {
    this.serializeToHiddenField()
  }

  // Parse rules from the hidden field on initial connect
  parseInitialRules() {
    if (this.hasHiddenFieldTarget && this.hiddenFieldTarget.value) {
      try {
        this.rulesValue = JSON.parse(this.hiddenFieldTarget.value)
      } catch (e) {
        // Invalid JSON, start with empty rules
        this.rulesValue = []
      }
    }
  }

  // Add a new event type filter
  addEventType(event) {
    event.preventDefault()
    const value = this.eventTypeInputTarget.value.trim()
    if (!value) return

    const eventTypes = this.getEventTypes()
    if (!eventTypes.includes(value)) {
      eventTypes.push(value)
      this.updateFilterRule(eventTypes)
      this.renderEventTypes()
    }
    this.eventTypeInputTarget.value = ""
    this.eventTypeInputTarget.focus()
  }

  // Handle enter key in the event type input
  addEventTypeOnEnter(event) {
    if (event.key === "Enter") {
      this.addEventType(event)
    }
  }

  // Remove an event type by clicking its badge
  removeEventType(event) {
    const typeToRemove = event.currentTarget.dataset.eventType
    const eventTypes = this.getEventTypes().filter(t => t !== typeToRemove)
    this.updateFilterRule(eventTypes)
    this.renderEventTypes()
  }

  // Update delay when the input changes
  updateDelay() {
    const seconds = parseInt(this.delayInputTarget.value) || 0
    this.updateDelayRule(seconds)
  }

  // Import rules from another connection
  importRules() {
    const connectionId = this.importSelectTarget.value
    if (!connectionId) return

    const connection = this.connectionsValue.find(c => c.id == connectionId)
    if (connection?.rules) {
      this.rulesValue = [...connection.rules]
      this.renderEventTypes()
      this.renderDelay()
    }
    // Reset select to placeholder
    this.importSelectTarget.value = ""
  }

  // Get current event types from the filter rule
  getEventTypes() {
    const filterRule = this.rulesValue.find(r => r.type === "filter")
    return filterRule?.config?.event_types ? [...filterRule.config.event_types] : []
  }

  // Update or create the filter rule with new event types
  updateFilterRule(eventTypes) {
    let rules = [...this.rulesValue]
    const filterIndex = rules.findIndex(r => r.type === "filter")

    if (eventTypes.length === 0) {
      // Remove filter rule if no event types
      if (filterIndex !== -1) {
        rules.splice(filterIndex, 1)
      }
    } else {
      const filterRule = { type: "filter", config: { event_types: eventTypes } }
      if (filterIndex !== -1) {
        rules[filterIndex] = filterRule
      } else {
        rules.unshift(filterRule) // Add filter at the beginning
      }
    }

    this.rulesValue = rules
  }

  // Get current delay seconds from the delay rule
  getDelaySeconds() {
    const delayRule = this.rulesValue.find(r => r.type === "delay")
    return delayRule?.config?.seconds || 0
  }

  // Update or create the delay rule
  updateDelayRule(seconds) {
    let rules = [...this.rulesValue]
    const delayIndex = rules.findIndex(r => r.type === "delay")

    if (seconds === 0) {
      // Remove delay rule if 0 seconds
      if (delayIndex !== -1) {
        rules.splice(delayIndex, 1)
      }
    } else {
      const delayRule = { type: "delay", config: { seconds: seconds } }
      if (delayIndex !== -1) {
        rules[delayIndex] = delayRule
      } else {
        rules.push(delayRule) // Add delay at the end
      }
    }

    this.rulesValue = rules
  }

  // Serialize the rules to the hidden field as JSON
  serializeToHiddenField() {
    if (this.hasHiddenFieldTarget) {
      if (this.rulesValue.length === 0) {
        this.hiddenFieldTarget.value = ""
      } else {
        this.hiddenFieldTarget.value = JSON.stringify(this.rulesValue)
      }
    }
  }

  // Render event type badges
  renderEventTypes() {
    if (!this.hasEventTypesContainerTarget) return

    const eventTypes = this.getEventTypes()
    const badges = eventTypes.map(type => `
      <span class="badge badge-primary gap-1">
        ${this.escapeHtml(type)}
        <button type="button"
                class="btn btn-ghost btn-xs p-0 h-auto min-h-0"
                data-action="click->rules-editor#removeEventType"
                data-event-type="${this.escapeHtml(type)}"
                aria-label="Remove ${this.escapeHtml(type)}">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>
      </span>
    `).join("")

    this.eventTypesContainerTarget.innerHTML = badges
  }

  // Render delay input value
  renderDelay() {
    if (!this.hasDelayInputTarget) return
    this.delayInputTarget.value = this.getDelaySeconds()
  }

  // Escape HTML to prevent XSS
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
