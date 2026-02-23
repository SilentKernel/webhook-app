source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft", "~> 1.3"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails", "~> 2.2"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails", "~> 2.0"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails", "~> 1.3"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder", "~> 2.14"

gem "openssl", "~> 3.3"
# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", "~> 2.0", platforms: %i[ windows jruby ]

# Authentication [https://github.com/heartcombo/devise]
gem "devise", "~> 5.0"

# Background job processing [https://github.com/sidekiq/sidekiq]
gem "sidekiq", "~> 8.0"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", "~> 1.20", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", "~> 2.10", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", "~> 0.1", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem 'pagy', '~> 43.2'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", "~> 1.11", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", "~> 7.1", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", "~> 1.1", require: false

  # Load environment variables from .env file
  gem "dotenv-rails", "~> 3.2"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console", "~> 4.2"

  # Preview emails in browser instead of sending [https://github.com/ryanb/letter_opener]
  gem "letter_opener", "~> 1.10"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara", "~> 3.40"
  gem "selenium-webdriver", "~> 4.39"
  # Pin minitest to avoid Rails 8 compatibility issue with minitest 6.x
  gem "minitest", "< 6.0"
  # Stub HTTP requests in tests
  gem "webmock", "~> 3.26"
end

gem "tailwindcss-rails", "~> 4.4"

gem "redis", "~> 5.0"

# Pin connection_pool to v2.x to fix Rails 8.1.1 incompatibility with v3
# See: https://github.com/rails/rails/issues/56461
gem "connection_pool", "~> 2.4"

# HTTP client for webhook delivery
gem "faraday", "~> 2.14"

# Autocomplete combobox for forms [https://github.com/josefarias/hotwire_combobox]
gem "hotwire_combobox", "~> 0.4.0"

# Syntax highlighting for code blocks
gem "rouge", "~> 4.6"
