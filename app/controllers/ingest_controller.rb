# frozen_string_literal: true

# IngestController handles incoming webhooks from external services.
# It inherits from ActionController::Base to avoid ApplicationController's
# authentication and organization requirements.
class IngestController < ActionController::Base
  # No CSRF protection needed for webhooks
  skip_forgery_protection

  def receive
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
    @source.events.create!(
      payload: request_payload,
      headers: request_headers,
      query_params: request.query_parameters,
      source_ip: request.remote_ip,
      content_type: request.content_type,
      event_type: extract_event_type,
      received_at: Time.current
    )
  end

  def request_payload
    # Parse JSON body, or store raw body for other content types
    if request.content_type&.include?("application/json")
      JSON.parse(request.raw_post) rescue { raw: request.raw_post }
    else
      { raw: request.raw_post }
    end
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

  def extract_event_type
    payload = request_payload

    # Common patterns for event type extraction
    payload["type"] ||           # Stripe, many others
      payload["event_type"] ||   # Some providers
      payload["event"] ||        # Some providers
      request.headers["X-GitHub-Event"] ||   # GitHub
      request.headers["X-Shopify-Topic"] ||  # Shopify
      nil
  end
end
