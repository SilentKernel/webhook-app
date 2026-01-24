# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rolemodel/turbo-confirm", to: "@rolemodel--turbo-confirm.js" # @2.2.0

# Not loaded on page loading
pin_all_from "app/javascript/controllers", under: "controllers", preload: false
pin "@stimulus-components/clipboard", to: "@stimulus-components--clipboard.js", preload: false# @5.0.0
pin "@stimulus-components/notification", to: "@stimulus-components--notification.js", preload: false # @3.0.0
pin "@stimulus-components/dialog", to: "@stimulus-components--dialog.js", preload: false # @1.0.1
pin "stimulus-use", preload: false # @0.52.3
