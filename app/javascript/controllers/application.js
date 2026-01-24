import {Application} from "@hotwired/stimulus"
import Clipboard from "@stimulus-components/clipboard"
import ClipboardWithAlert from "controllers/clipboard_with_alert_controller"
import Notification from "@stimulus-components/notification"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Register stimulus-components
application.register("clipboard", Clipboard)
application.register("clipboard-with-alert", ClipboardWithAlert)
application.register("notification", Notification)

export {application}
