# frozen_string_literal: true

# IngestController handles incoming webhooks from external services.
# It inherits from ActionController::Base to avoid ApplicationController's
# authentication and organization requirements.
class IngestController < ActionController::Base
  # No CSRF protection needed for webhooks
  skip_forgery_protection

  MAX_PAYLOAD_SIZE = 1.megabyte # 1,048,576 bytes

  STRIPPED_HEADERS = %w[
    X-Forwarded-For
    X-Forwarded-Proto
    X-Forwarded-Port
    X-Forwarded-Host
    X-Forwarded-Scheme
    X-Forwarded-Ssl
    X-Real-Ip
    Forwarded
    Via
  ].freeze

  def receive
    # Find source by ingest token first
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

    # Check payload size - create event for tracking if too large
    if payload_too_large?
      @event = create_event(status: :payload_too_large, store_body: false)
      render json: {
        error: "Payload too large",
        message: "Request body exceeds maximum allowed size of 1 MB",
        event_id: @event.uid
      }, status: :content_too_large
      return
    end

    # Create event first (we'll update status if verification fails)
    @event = create_event

    # Verify signature if configured
    unless verify_signature
      @event.update!(status: :authentication_failed)
      render json: {
        error: "Invalid signature",
        event_id: @event.uid
      }, status: :unauthorized
      return
    end

    # Queue for processing (only for successfully received events)
    ProcessWebhookJob.perform_later(@event.id)

    # Return success with configured status code (default: 202 Accepted)
    render json: {
      event_id: @event.uid,
      message: "Webhook received by HookStack"
    }, status: @source.success_status_code
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

  def create_event(status: :received, store_body: true)
    raw_body = request.raw_post
    is_binary = binary_content?

    @source.events.create!(
      status: status,
      raw_body: store_body ? raw_body : nil,
      body_is_binary: is_binary,
      body_size: raw_body.bytesize,
      headers: request_headers,
      query_params: request.query_parameters,
      source_ip: request.remote_ip,
      content_type: request.content_type,
      event_type: store_body ? extract_event_type(raw_body) : nil,
      received_at: Time.current
    )
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
    # Extract relevant headers (skip internal Rails headers and reverse proxy headers)
    headers = {}
    request.headers.each do |key, value|
      next unless key.start_with?("HTTP_") || %w[CONTENT_TYPE CONTENT_LENGTH].include?(key)
      # Convert HTTP_X_CUSTOM_HEADER to X-Custom-Header
      header_name = key.sub(/^HTTP_/, "").split("_").map(&:capitalize).join("-")
      next if STRIPPED_HEADERS.include?(header_name)
      headers[header_name] = value
    end
    headers
  end

  def extract_event_type(raw_body)
    # Try to parse JSON to extract event type
    if request.content_type.to_s.include?("application/json")
      begin
        payload = JSON.parse(raw_body)
        event_type = payload["type"] ||       # Stripe, many others
                     payload["event_type"] || # Some providers
                     payload["event"]         # Some providers
        return event_type if event_type.present?
      rescue JSON::ParserError
        # Fall through to header-based extraction
      end
    end

    # Header-based event type extraction
    request.headers["X-GitHub-Event"] ||   # GitHub
      request.headers["X-Shopify-Topic"] ||  # Shopify
      nil
  end
end
