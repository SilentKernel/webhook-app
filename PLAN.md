# Implementation Plan: Auto-Dismissing Flash Alerts

## Overview

The current flash alert system (`app/views/shared/_flash.html.erb`) displays notifications but they never disappear, requiring manual page navigation to clear them. This plan adds:

1. **Auto-dismiss after 10 seconds** - Alerts fade out automatically
2. **Close button (X)** - Users can dismiss alerts immediately

## Current State

- **Flash partial**: `app/views/shared/_flash.html.erb` renders alerts using DaisyUI styling
- **Layout**: `app/views/layouts/application.html.erb` includes the flash partial
- **Tech stack**: Rails 8.1, Hotwire (Turbo + Stimulus), DaisyUI 5, Tailwind CSS 4
- **Existing Stimulus**: Project uses `@stimulus-components/clipboard` already

## Research Findings

### Option 1: `@stimulus-components/notification` (Recommended)
A mature, well-maintained Stimulus controller from stimulus-components.com designed specifically for this use case:
- Auto-dismiss with configurable delay (`data-notification-delay-value`)
- Manual close via `data-action="notification#hide"`
- CSS transition support built-in
- Already follows the project's pattern of using stimulus-components

### Option 2: Custom Stimulus controller
Write a custom `flash_controller.js` from scratch. More code to maintain and test.

### Option 3: Tailwind + CSS-only
Pure CSS animations with `animation-delay`. No close button support without JS.

**Recommendation**: Option 1 aligns with CLAUDE.md guidance to "Use controllers from stimulus-components.com when applicable before writing custom ones."

## Step-by-Step Implementation

### Step 1: Install @stimulus-components/notification

Add the npm package and pin it in importmap:

```bash
npm install @stimulus-components/notification
bin/importmap pin @stimulus-components/notification
```

### Step 2: Register the Notification controller

Update `app/javascript/controllers/application.js` to register the notification controller:

```javascript
import { Application } from "@hotwired/stimulus"
import Notification from "@stimulus-components/notification"

const application = Application.start()
application.debug = false
window.Stimulus = application

// Register stimulus-components
application.register("notification", Notification)

export { application }
```

### Step 3: Update the flash partial

Modify `app/views/shared/_flash.html.erb` to:
- Add `data-controller="notification"` to each alert
- Set `data-notification-delay-value="10000"` (10 seconds)
- Add CSS transition classes for smooth fade-out
- Add a close button with `data-action="notification#hide"`

### Step 4: Write tests

Add system tests to verify:
- Alerts auto-dismiss after 10 seconds
- Close button immediately dismisses alert
- Multiple alerts can be dismissed independently

## Potential Risks and Considerations

1. **Turbo compatibility**: Flash alerts may reappear on Turbo navigation. The current implementation handles this naturally since Rails clears flash after display.

2. **Accessibility**: Close button needs proper aria-label. The X icon should have accessible text.

3. **CSS transitions**: Need to ensure DaisyUI's alert styles don't conflict with transition classes.

## Estimated Scope

- **Files modified**: 3 files
  - `config/importmap.rb` (add pin)
  - `app/javascript/controllers/application.js` (register controller)
  - `app/views/shared/_flash.html.erb` (update markup)
- **Files added**: 0 (using existing package)
- **Test files**: 1 new system test file

## Implementation Notes

The `@stimulus-components/notification` controller uses these data attributes:
- `data-notification-delay-value`: Milliseconds before auto-hide (default: 3000, we'll use 10000)
- `data-notification-hidden-value`: Start hidden (we won't use this)
- Transition attributes for CSS animations

The close button uses `data-action="notification#hide"` to trigger immediate dismissal.
