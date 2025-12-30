# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Not loaded on page loading
pin_all_from "app/javascript/controllers", under: "controllers", preload: false
pin "@stimulus-components/clipboard", to: "@stimulus-components--clipboard.js", preload: false# @5.0.0
