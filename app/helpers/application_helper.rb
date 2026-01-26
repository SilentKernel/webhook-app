module ApplicationHelper
  # Generate page series for pagination (similar to old Pagy behavior)
  # Returns an array of page numbers, :gap symbols, and current page as string
  def pagination_series(pagy, size: 7)
    return [] if pagy.last <= 1

    page = pagy.page
    last = pagy.last
    series = []

    # Calculate which pages to show
    if last <= size
      # Show all pages
      series = (1..last).to_a
    else
      # Show first, last, and pages around current
      half = (size - 3) / 2  # Leave room for first, last, and one gap
      left = [page - half, 2].max
      right = [page + half, last - 1].min

      # Adjust if near edges
      if left <= 2
        left = 2
        right = [size - 2, last - 1].min
      elsif right >= last - 1
        right = last - 1
        left = [last - size + 3, 2].max
      end

      series << 1
      series << :gap if left > 2
      (left..right).each { |p| series << p }
      series << :gap if right < last - 1
      series << last
    end

    series.map { |item| item == page ? item.to_s : item }
  end

  # Returns "menu-active" if the current controller matches, for navbar highlighting
  def nav_link_class(controller)
    controller_name == controller.to_s ? "menu-active" : ""
  end

  def status_badge(status)
    colors = {
      "active" => "badge-success",
      "paused" => "badge-warning",
      "disabled" => "badge-error"
    }
    css_class = colors[status.to_s] || "badge-ghost"
    content_tag(:span, status.to_s.titleize, class: "badge #{css_class}")
  end

  # Badge for delivery statuses (pending, queued, delivering, success, failed)
  def delivery_status_badge(status)
    colors = {
      "pending" => "badge-ghost",
      "queued" => "badge-ghost",
      "delivering" => "badge-info",
      "success" => "badge-success",
      "failed" => "badge-error"
    }
    css_class = colors[status.to_s] || "badge-ghost"
    content_tag(:span, status.to_s.titleize, class: "badge #{css_class}")
  end

  # Badge for event reception statuses (received, authentication_failed, payload_too_large)
  def event_status_badge(status)
    config = {
      "received" => { class: "badge-success", label: "Received" },
      "authentication_failed" => { class: "badge-error", label: "Auth Failed" },
      "payload_too_large" => { class: "badge-warning", label: "Too Large" }
    }
    badge = config[status.to_s] || { class: "badge-ghost", label: status.to_s.titleize }
    content_tag(:span, badge[:label], class: "badge #{badge[:class]}")
  end

  # Delivery status summary for event index (e.g., "2/2 ✓")
  def delivery_status_summary(event)
    total = event.deliveries.size
    return "—" if total.zero?

    successful = event.deliveries.count { |d| d.status == "success" }

    if successful == total
      content_tag(:span, "#{successful}/#{total} ✓", class: "text-success font-medium")
    elsif successful.zero?
      content_tag(:span, "#{successful}/#{total} ✗", class: "text-error font-medium")
    else
      content_tag(:span, "#{successful}/#{total} ⚠", class: "text-warning font-medium")
    end
  end

  # Relative time with full timestamp on hover
  def relative_time(time)
    return "—" if time.nil?

    content_tag(:span, time_ago_in_words(time) + " ago", title: time.strftime("%b %d, %Y at %I:%M %p"))
  end

  # Format next retry time for delivery
  def next_retry_display(delivery)
    return "—" unless delivery.next_attempt_at.present?

    if delivery.next_attempt_at > Time.current
      "In #{distance_of_time_in_words(Time.current, delivery.next_attempt_at)}"
    else
      "Pending"
    end
  end

  # Color class for success rate percentage
  def success_rate_color(rate)
    return "" if rate.nil?

    if rate >= 95
      "text-success"
    elsif rate >= 80
      "text-warning"
    else
      "text-error"
    end
  end

  # Strip HTML tags and normalize whitespace for readable response display
  def cleaned_response_body(body)
    return nil if body.blank?
    cleaned = strip_tags(body)
    cleaned.gsub(/\s+/, " ").strip.presence
  end

  # Detect if response contains HTML/XML markup
  def html_response?(body)
    return false if body.blank?
    body.include?("<") && body.include?(">")
  end
end
