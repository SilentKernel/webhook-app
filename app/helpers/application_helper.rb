module ApplicationHelper
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
end
