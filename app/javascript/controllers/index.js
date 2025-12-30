// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"

// Lazy load local controllers only
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
lazyLoadControllersFrom("controllers", application)