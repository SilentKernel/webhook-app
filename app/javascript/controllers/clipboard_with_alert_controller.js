import Clipboard from "@stimulus-components/clipboard"

export default class extends Clipboard {
  copied() {
    super.copied()
    this.showNotification("Ingest link copied")
  }

  showNotification(message) {
    const container = this.getOrCreateNotificationContainer()
    const alert = this.createAlert(message)
    container.appendChild(alert)

    // Auto-dismiss after 3 seconds (shorter than flash messages since this is a confirmation)
    setTimeout(() => {
      alert.classList.add("opacity-0")
      setTimeout(() => alert.remove(), 300)
    }, 3000)
  }

  getOrCreateNotificationContainer() {
    let container = document.querySelector(".js-notification-container")
    if (!container) {
      container = document.createElement("div")
      container.className = "js-notification-container fixed top-4 right-4 z-50 flex flex-col gap-2"
      document.body.appendChild(container)
    }
    return container
  }

  createAlert(message) {
    const alert = document.createElement("div")
    alert.className = "alert alert-success shadow-lg transition-opacity duration-300"
    alert.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 shrink-0 stroke-current" fill="none" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <span>${message}</span>
      <button
        type="button"
        class="ml-auto p-1 rounded-full opacity-70 hover:opacity-100 hover:bg-black/10 transition-opacity"
        aria-label="Dismiss"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    `

    // Add close button functionality
    const closeButton = alert.querySelector("button")
    closeButton.addEventListener("click", () => {
      alert.classList.add("opacity-0")
      setTimeout(() => alert.remove(), 300)
    })

    return alert
  }
}
