# frozen_string_literal: true

class DeliverWebhookJob < ApplicationJob
  queue_as :webhooks

  def perform(delivery_id)
    delivery = Delivery.find_by(id: delivery_id)
    return unless delivery
    return if delivery.success? || delivery.cancelled?

    delivery.update!(status: :delivering)

    event = delivery.event
    destination = delivery.destination
    connection = delivery.connection

    # Build and send request
    attempt = send_webhook(delivery, event, destination, connection)

    if attempt.success?
      delivery.mark_success!
    else
      delivery.mark_failed!

      # Send notification on every failure (rate limiting in job)
      SendDeliveryFailureNotificationJob.perform_later(delivery.id)

      # Schedule retry if possible
      if delivery.can_retry? && delivery.next_attempt_at.present?
        DeliverWebhookJob.set(wait_until: delivery.next_attempt_at).perform_later(delivery.id)
      end
    end
  end

  private

  def send_webhook(delivery, event, destination, connection)
    attempt_number = delivery.attempt_count + 1
    started_at = Time.current
    request_body = request_body_for(event)

    url = delivery_url(event, destination)

    begin
      response = make_request(event, destination, connection)

      delivery.delivery_attempts.create!(
        attempt_number: attempt_number,
        status: response.success? ? :success : :failed,
        request_url: url,
        request_method: destination.http_method,
        request_headers: sanitize_headers_for_storage(build_request_headers(event, destination, connection)),
        request_body: truncate_body(request_body),
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
        request_url: url,
        request_method: destination.http_method,
        request_headers: sanitize_headers_for_storage(build_request_headers(event, destination, connection)),
        request_body: truncate_body(request_body),
        duration_ms: ((Time.current - started_at) * 1000).to_i,
        error_message: e.message,
        error_code: error_code_for(e),
        attempted_at: started_at
      )
    end
  end

  def make_request(event, destination, connection)
    timeout = destination.timeout_seconds || 30

    conn = Faraday.new do |f|
      f.options.timeout = timeout
      f.options.open_timeout = 10
      f.adapter Faraday.default_adapter
    end

    headers = build_request_headers(event, destination, connection)
    body = request_body_for(event)
    url = delivery_url(event, destination)

    case destination.http_method.upcase
    when "POST"
      conn.post(url, body, headers)
    when "PUT"
      conn.put(url, body, headers)
    when "PATCH"
      conn.patch(url, body, headers)
    when "GET"
      conn.get(url, nil, headers)
    when "DELETE"
      conn.delete(url, nil, headers)
    else
      conn.post(url, body, headers)
    end
  end

  def delivery_url(event, destination)
    return destination.url if event.query_params.blank?

    uri = URI.parse(destination.url)
    existing_params = URI.decode_www_form(uri.query || "")
    new_params = event.query_params.to_a
    uri.query = URI.encode_www_form(existing_params + new_params)
    uri.to_s
  end

  def request_body_for(event)
    event.raw_body
  end

  def sanitize_headers_for_storage(headers)
    result = headers.transform_keys(&:to_s)
    auth_keys = result.keys.select { |k| k.casecmp?("authorization") }
    auth_keys.each { |k| result[k] = "[REDACTED]" }
    result
  end

  # Headers that should never be forwarded (hop-by-hop or conflict with destination)
  BLOCKED_FORWARD_HEADERS = %w[
    Host
    Content-Length
    Connection
    Transfer-Encoding
  ].map(&:downcase).freeze

  def build_request_headers(event, destination, connection = nil)
    # Start with forwarded headers if configured
    headers = forwarded_headers(event, connection)

    # Use original content-type if raw_body present, fallback to JSON for legacy events
    content_type = event.raw_body.present? ? event.content_type : "application/json"

    # Base platform headers (override forwarded headers)
    headers.merge!(
      "Content-Type" => content_type || "application/json",
      "X-Webhook-Event-Id" => event.uid,
      "X-Webhook-Event-Type" => event.event_type.to_s,
      "X-Webhook-Timestamp" => Time.current.iso8601
    )

    # Add custom headers from destination (can override platform headers)
    if destination.headers.present?
      headers.merge!(destination.headers)
    end

    # Add authentication (highest priority)
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

  def forwarded_headers(event, connection)
    return {} unless connection
    return {} unless event.headers.present?

    original_headers = event.headers

    if connection.forward_all_headers?
      # Forward all headers except blocklisted ones
      original_headers.reject do |key, _value|
        BLOCKED_FORWARD_HEADERS.include?(key.downcase)
      end
    elsif connection.forward_headers.present?
      # Forward only specified headers (case-insensitive matching)
      forward_list = connection.forward_headers.map(&:downcase)
      original_headers.select do |key, _value|
        forward_list.include?(key.downcase) && !BLOCKED_FORWARD_HEADERS.include?(key.downcase)
      end
    elsif (default_headers = source_type_default_headers(connection)).present?
      # Forward source type default headers (e.g., Stripe-Signature for Stripe sources)
      forward_list = default_headers.map(&:downcase)
      original_headers.select do |key, _value|
        forward_list.include?(key.downcase) && !BLOCKED_FORWARD_HEADERS.include?(key.downcase)
      end
    else
      {}
    end
  end

  def source_type_default_headers(connection)
    connection&.source&.source_type&.default_forward_headers || []
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
