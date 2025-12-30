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
end
