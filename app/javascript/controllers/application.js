import {Application} from "@hotwired/stimulus"
import Clipboard from "@stimulus-components/clipboard"
import Notification from "@stimulus-components/notification"
import Dialog from "@stimulus-components/dialog"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Register stimulus-components
application.register("clipboard", Clipboard)
application.register("notification", Notification)
application.register("dialog", Dialog)

export {application}
