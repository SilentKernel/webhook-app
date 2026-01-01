# frozen_string_literal: true

class DeliverWebhookJob < ApplicationJob
  queue_as :webhooks

  def perform(delivery_id)
    delivery = Delivery.find_by(id: delivery_id)
    return unless delivery
    return if delivery.success? # Already delivered

    delivery.update!(status: :delivering)

    event = delivery.event
    destination = delivery.destination

    # Build and send request
    attempt = send_webhook(delivery, event, destination)

    if attempt.success?
      delivery.mark_success!
    else
      delivery.mark_failed!

      # Schedule retry if possible
      if delivery.can_retry? && delivery.next_attempt_at.present?
        DeliverWebhookJob.set(wait_until: delivery.next_attempt_at).perform_later(delivery.id)
      end
    end
  end

  private

  def send_webhook(delivery, event, destination)
    attempt_number = delivery.attempt_count + 1
    started_at = Time.current

    begin
      response = make_request(event, destination)

      delivery.delivery_attempts.create!(
        attempt_number: attempt_number,
        status: response.success? ? :success : :failed,
        request_url: destination.url,
        request_method: destination.http_method,
        request_headers: build_request_headers(event, destination),
        request_body: event.payload.to_json,
        response_status: response.status,
        response_headers: response.headers.to_h,
        response_body: truncate_body(response.body),
        duration_ms: ((Time.current - started_at) * 1000).to_i,
        attempted_at: started_at
      )
    rescue Faraday::Error => e
      delivery.delivery_attempts.create!(
        attempt_number: attempt_number,
        status: :failed,
        request_url: destination.url,
        request_method: destination.http_method,
        request_headers: build_request_headers(event, destination),
        request_body: event.payload.to_json,
        duration_ms: ((Time.current - started_at) * 1000).to_i,
        error_message: e.message,
        error_code: error_code_for(e),
        attempted_at: started_at
      )
    end
  end

  def make_request(event, destination)
    timeout = destination.timeout_seconds || 30

    conn = Faraday.new do |f|
      f.options.timeout = timeout
      f.options.open_timeout = 10
      f.adapter Faraday.default_adapter
    end

    headers = build_request_headers(event, destination)
    body = event.payload.to_json

    case destination.http_method.upcase
    when "POST"
      conn.post(destination.url, body, headers)
    when "PUT"
      conn.put(destination.url, body, headers)
    when "PATCH"
      conn.patch(destination.url, body, headers)
    when "GET"
      conn.get(destination.url, nil, headers)
    when "DELETE"
      conn.delete(destination.url, nil, headers)
    else
      conn.post(destination.url, body, headers)
    end
  end

  def build_request_headers(event, destination)
    headers = {
      "Content-Type" => "application/json",
      "User-Agent" => "WebhookPlatform/1.0",
      "X-Webhook-Event-Id" => event.uid,
      "X-Webhook-Event-Type" => event.event_type.to_s,
      "X-Webhook-Timestamp" => Time.current.iso8601
    }

    # Add custom headers from destination
    if destination.headers.present?
      headers.merge!(destination.headers)
    end

    # Add authentication
    case destination.auth_type
    when "bearer"
      headers["Authorization"] = "Bearer #{destination.auth_value}"
    when "basic"
      # auth_value should be "username:password"
      encoded = Base64.strict_encode64(destination.auth_value.to_s)
      headers["Authorization"] = "Basic #{encoded}"
    when "api_key"
      # auth_value should be "header_name:value" or just the key
      if destination.auth_value.to_s.include?(":")
        header_name, value = destination.auth_value.split(":", 2)
        headers[header_name] = value
      else
        headers["X-API-Key"] = destination.auth_value
      end
    end

    headers
  end

  def truncate_body(body)
    return nil if body.nil?
    body.to_s.truncate(65_535) # TEXT column limit
  end

  def error_code_for(error)
    case error
    when Faraday::TimeoutError
      "timeout"
    when Faraday::ConnectionFailed
      "connection_failed"
    when Faraday::SSLError
      "ssl_error"
    else
      "request_error"
    end
  end
end
