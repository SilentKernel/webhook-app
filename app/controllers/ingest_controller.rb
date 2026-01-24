# frozen_string_literal: true

# IngestController handles incoming webhooks from external services.
# It inherits from ActionController::Base to avoid ApplicationController's
# authentication and organization requirements.
class IngestController < ActionController::Base
  # No CSRF protection needed for webhooks
  skip_forgery_protection

  MAX_PAYLOAD_SIZE = 1.megabyte # 1,048,576 bytes

  def receive
    # Check payload size first (before any other processing)
    if payload_too_large?
      render json: {
        error: "Payload too large",
        message: "Request body exceeds maximum allowed size of 1 MB"
      }, status: :content_too_large
      return
    end
    # Find source by ingest token
    @source = Source.find_by(ingest_token: params[:token])

    unless @source
      render json: { error: "Invalid token" }, status: :not_found
      return
    end

    # Check if source is active
    unless @source.active?
      render json: { error: "Source is paused" }, status: :gone
      return
    end

    # Verify signature if configured
    unless verify_signature
      render json: { error: "Invalid signature" }, status: :unauthorized
      return
    end

    # Create event
    @event = create_event

    # Queue for processing
    ProcessWebhookJob.perform_later(@event.id)

    # Return success (202 Accepted - we've queued it)
    render json: {
      event_id: @event.uid,
      message: "Webhook received by HookStack"
    }, status: :accepted
  end

  private

  def payload_too_large?
    # Check Content-Length header first (fast path)
    content_length = request.content_length.to_i
    return true if content_length > MAX_PAYLOAD_SIZE

    # Also check actual body size (in case Content-Length is missing or spoofed)
    request.raw_post.bytesize > MAX_PAYLOAD_SIZE
  end

  def verify_signature
    case @source.verification_type_slug
    when "none"
      true
    when "stripe"
      SignatureVerifier.verify_stripe(request, @source.verification_secret)
    when "shopify"
      SignatureVerifier.verify_shopify(request, @source.verification_secret)
    when "github"
      SignatureVerifier.verify_github(request, @source.verification_secret)
    when "hmac"
      SignatureVerifier.verify_hmac(request, @source.verification_secret)
    else
      true # Unknown type, allow through
    end
  end

  def create_event
    raw_body = request.raw_post
    is_binary = binary_content?
    payload = request_payload(raw_body)

    @source.events.create!(
      payload: payload,
      raw_body: raw_body,
      body_is_binary: is_binary,
      body_size: raw_body.bytesize,
      headers: request_headers,
      query_params: request.query_parameters,
      source_ip: request.remote_ip,
      content_type: request.content_type,
      event_type: extract_event_type(payload),
      received_at: Time.current
    )
  end

  def request_payload(raw_body)
    content_type = request.content_type.to_s

    if content_type.include?("application/json")
      # JSON: parse to hash
      JSON.parse(raw_body) rescue { _format: "json", _error: "parse_failed", _preview: raw_body.truncate(500) }
    elsif content_type.include?("application/x-www-form-urlencoded")
      # Form-urlencoded: parse to hash
      Rack::Utils.parse_nested_query(raw_body)
    elsif content_type.include?("xml")
      # XML: store metadata only (parsing is complex and often unnecessary)
      { _format: "xml", _size: raw_body.bytesize, _preview: raw_body.truncate(500) }
    elsif content_type.start_with?("text/")
      # Plain text: store content directly
      { _content: raw_body.truncate(65_535) }
    elsif binary_content?
      # Binary: store metadata only
      { _format: "binary", _content_type: content_type, _size: raw_body.bytesize }
    else
      # Unknown: store as text if valid UTF-8, otherwise as binary metadata
      if raw_body.force_encoding("UTF-8").valid_encoding?
        { _content: raw_body.truncate(65_535) }
      else
        { _format: "binary", _content_type: content_type, _size: raw_body.bytesize }
      end
    end
  end

  def binary_content?
    content_type = request.content_type.to_s
    return true if content_type.start_with?("image/", "audio/", "video/", "application/octet-stream")
    return true if content_type.include?("multipart/")

    # Check if body contains non-UTF-8 bytes
    raw_post = request.raw_post
    !raw_post.force_encoding("UTF-8").valid_encoding?
  end

  def request_headers
    # Extract relevant headers (skip internal Rails headers)
    headers = {}
    request.headers.each do |key, value|
      next unless key.start_with?("HTTP_") || %w[CONTENT_TYPE CONTENT_LENGTH].include?(key)
      # Convert HTTP_X_CUSTOM_HEADER to X-Custom-Header
      header_name = key.sub(/^HTTP_/, "").split("_").map(&:capitalize).join("-")
      headers[header_name] = value
    end
    headers
  end

  def extract_event_type(payload)
    # Common patterns for event type extraction
    payload["type"] ||           # Stripe, many others
      payload["event_type"] ||   # Some providers
      payload["event"] ||        # Some providers
      request.headers["X-GitHub-Event"] ||   # GitHub
      request.headers["X-Shopify-Topic"] ||  # Shopify
      nil
  end
end
