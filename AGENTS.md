# CLAUDE.md

## Important: Use Context7 for Documentation

**Always use Context7 MCP tools** to look up documentation for Rails, Ruby, and other libraries in this project.

## Tech Stack

| Category | Technology | Notes |
|----------|------------|-------|
| **Framework** | Rails 8.1 | Full-stack MVC |
| **Database** | PostgreSQL | Primary store |
| **Cache/Queue** | Sidekiq + Redis | Redis-backed jobs & caching |
| **Auth** | Devise | User authentication |
| **CSS** | Tailwind CSS 4 | Via `tailwindcss-rails`, CSS-first config (`@import "tailwindcss"`) |
| **Components** | DaisyUI 5 | Loaded via `@plugin "./daisyui.mjs"` |
| **JS** | Hotwire (Turbo + Stimulus) | Importmap, no bundler |
| **Assets** | Propshaft | Modern asset pipeline |
| **HTTP Client** | Faraday | Webhook delivery |
| **Pagination** | Pagy | Fast pagination |
| **Deployment** | Kamal + Thruster | Docker-based |

## Development

```bash
docker compose -f docker-compose-dev.yml up -d  # Start PostgreSQL (port 2003)
bin/dev  # Starts server on port 3002, CSS watcher, and Sidekiq worker
```

- **URL**: http://localhost:3002
- **Login**: `ludo@hey.com` / `JustForDev2026` (after `bin/rails db:seed`)

## Architecture Overview

Webhook receiving platform. External services send webhooks to Sources, which are forwarded to Destinations via Connections.

```
User --< Membership >-- Organization --< Source --< Connection >-- Destination
                                           |                           |
                                         Event --< Delivery >----------+
                                                      |
                                               DeliveryAttempt
```

### Multi-Tenant Model

Users belong to organizations through memberships with roles:
- `owner` (2): Full access, settings, one per org
- `admin` (1): Can invite/remove members
- `member` (0): Basic access

Authorization helpers: `owner?`, `admin_or_owner?`, `current_membership`

### Locale-Prefixed Routes

All routes scoped under `/:locale`. Route helpers need `locale:` param:
```ruby
dashboard_path(locale: :en)
```

Custom Devise paths: `/en/login`, `/en/logout`, `/en/signup`

## Webhook System

### Ingest Endpoint (Public)

`POST /ingest/:token` - No auth required. Inherits from `ActionController::Base` (not ApplicationController).

### Verification Types

Stored in `verification_types` table. Use `source.verification_type_slug` for signature verification:
- `none` - No verification
- `stripe` - Stripe-Signature header
- `shopify` - X-Shopify-Hmac-SHA256 header
- `github` - X-Hub-Signature-256 header
- `hmac` - Generic HMAC-SHA256

### Encrypted Fields

```ruby
Source.encrypts :verification_secret
Destination.encrypts :auth_value
```

### Destination Auth Formats

- `bearer`: token string
- `basic`: `"username:password"`
- `api_key`: `"my_key"` (uses X-API-Key) or `"Custom-Header:value"`

### Connection Rules (JSONB)

```ruby
{ "type" => "filter", "config" => { "event_types" => ["payment.completed"] } }
{ "type" => "delay", "config" => { "seconds" => 60 } }
```

## Frontend

### Hotwire Priority

Prefer Turbo over Stimulus:
1. **Turbo Frames** - For replacing page sections
2. **Turbo Streams** - For updating multiple DOM elements
3. **Stimulus** - Only when JS behavior is truly needed (animations, third-party integrations, complex client state)

### Stimulus Controllers

- **notification** (`@stimulus-components/notification`): Auto-dismisses flash alerts after 10s
- **clipboard** (`@stimulus-components/clipboard`): Copy ingest URLs
- **source-form**: Auto-fills verification_type when source_type changes

### HotwireCombobox Gotcha

Do NOT pass input classes - styling is global in `application.css`:
```erb
<%= f.combobox :timezone, options, id: "org-timezone" %>  # Correct
<%= f.combobox :timezone, options, input: { class: "..." } %>  # Wrong
```

## Testing

**Always write tests** for new features and bug fixes. Run `bin/rails test` before considering work complete.

- **WebMock** stubs outbound HTTP requests: `stub_request(:post, url).to_return(status: 200)`
- Jobs use `:test` adapter in tests

## Background Jobs

- **Queue adapter**: Sidekiq (Redis-backed)
- **Cache store**: Redis (production), memory store (development)
- **Web UI**: Sidekiq dashboard at `/sidekiq` (owners only)
- **Config**: `config/sidekiq.yml` (queues: webhooks, default, mailers)
- **Concurrency**: 5 threads in development, 10 threads in production
