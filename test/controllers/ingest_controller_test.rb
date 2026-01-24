# frozen_string_literal: true

require "test_helper"

class IngestControllerTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:stripe_production)
    @source.update!(verification_type: verification_types(:none), status: :active)
  end

  test "receives webhook with valid token" do
    payload = { type: "payment.completed", data: { id: "123" } }

    assert_difference "Event.count", 1 do
      post ingest_url(token: @source.ingest_token),
           params: payload.to_json,
           headers: { "Content-Type" => "application/json" }
    end

    assert_response :accepted
    assert_equal "payment.completed", Event.last.event_type

    json_response = JSON.parse(response.body)
    assert_equal Event.last.uid, json_response["event_id"]
    assert_equal "Webhook received by HookStack", json_response["message"]
  end

  test "returns 404 for invalid token" do
    post ingest_url(token: "invalid_token"),
         params: { test: true }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "Invalid token", json_response["error"]
  end

  test "returns 410 for paused source" do
    @source.update!(status: :paused)

    post ingest_url(token: @source.ingest_token),
         params: { test: true }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :gone
    json_response = JSON.parse(response.body)
    assert_equal "Source is paused", json_response["error"]
  end

  test "queues ProcessWebhookJob" do
    payload = { type: "test.event" }

    assert_enqueued_with(job: ProcessWebhookJob) do
      post ingest_url(token: @source.ingest_token),
           params: payload.to_json,
           headers: { "Content-Type" => "application/json" }
    end
  end

  test "extracts event type from payload" do
    payload = { type: "customer.created", data: { id: "cus_123" } }

    post ingest_url(token: @source.ingest_token),
         params: payload.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :accepted
    assert_equal "customer.created", Event.last.event_type
  end

  test "extracts event type from GitHub header" do
    payload = { action: "opened", repository: { full_name: "test/repo" } }

    post ingest_url(token: @source.ingest_token),
         params: payload.to_json,
         headers: {
           "Content-Type" => "application/json",
           "X-GitHub-Event" => "pull_request"
         }

    assert_response :accepted
    assert_equal "pull_request", Event.last.event_type
  end

  test "extracts event type from Shopify header" do
    payload = { id: 123, order_number: "1001" }

    post ingest_url(token: @source.ingest_token),
         params: payload.to_json,
         headers: {
           "Content-Type" => "application/json",
           "X-Shopify-Topic" => "orders/create"
         }

    assert_response :accepted
    assert_equal "orders/create", Event.last.event_type
  end

  test "stores request headers" do
    payload = { type: "test.event" }

    post ingest_url(token: @source.ingest_token),
         params: payload.to_json,
         headers: {
           "Content-Type" => "application/json",
           "X-Custom-Header" => "custom-value"
         }

    assert_response :accepted
    event = Event.last
    assert_includes event.headers.keys, "X-Custom-Header"
    assert_equal "custom-value", event.headers["X-Custom-Header"]
  end

  test "stores query parameters" do
    payload = { type: "test.event" }

    post ingest_url(token: @source.ingest_token) + "?foo=bar&baz=qux",
         params: payload.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :accepted
    event = Event.last
    assert_equal({ "foo" => "bar", "baz" => "qux" }, event.query_params)
  end

  test "stores source IP" do
    payload = { type: "test.event" }

    post ingest_url(token: @source.ingest_token),
         params: payload.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :accepted
    event = Event.last
    assert_not_nil event.source_ip
  end

  test "handles plain text content type" do
    post ingest_url(token: @source.ingest_token),
         params: "raw body content",
         headers: { "Content-Type" => "text/plain" }

    assert_response :accepted
    event = Event.last
    assert_equal({ "_content" => "raw body content" }, event.payload)
    assert_equal "raw body content", event.raw_body
    assert_equal 16, event.body_size
    assert_not event.body_is_binary
    assert event.text?
  end

  test "handles XML content type" do
    xml_body = '<event><type>test</type><data>123</data></event>'

    post ingest_url(token: @source.ingest_token),
         params: xml_body,
         headers: { "Content-Type" => "application/xml" }

    assert_response :accepted
    event = Event.last
    assert_equal "xml", event.payload["_format"]
    assert_equal xml_body.bytesize, event.payload["_size"]
    assert_equal xml_body, event.raw_body
    assert event.xml?
  end

  test "handles form-urlencoded content type" do
    form_body = "event=test&value=123&nested[key]=value"

    post ingest_url(token: @source.ingest_token),
         params: form_body,
         headers: { "Content-Type" => "application/x-www-form-urlencoded" }

    assert_response :accepted
    event = Event.last
    assert_equal "test", event.payload["event"]
    assert_equal "123", event.payload["value"]
    assert_equal({ "key" => "value" }, event.payload["nested"])
    assert_equal form_body, event.raw_body
    assert event.form_urlencoded?
  end

  test "handles binary content type" do
    binary_body = "\x00\x01\x02\xFF\xFE".b

    post ingest_url(token: @source.ingest_token),
         params: binary_body,
         headers: { "Content-Type" => "application/octet-stream" }

    assert_response :accepted
    event = Event.last
    assert_equal "binary", event.payload["_format"]
    assert_equal 5, event.payload["_size"]
    assert_equal binary_body.bytes, event.raw_body.bytes
    assert event.body_is_binary
    assert event.binary?
  end

  test "stores raw_body for JSON webhooks" do
    payload = { type: "payment.completed", data: { id: "123" } }

    post ingest_url(token: @source.ingest_token),
         params: payload.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :accepted
    event = Event.last
    assert_equal payload.to_json, event.raw_body
    assert_equal payload.to_json.bytesize, event.body_size
    assert_not event.body_is_binary
    assert event.json?
  end

  test "returns 401 for invalid stripe signature" do
    @source.update!(verification_type: verification_types(:stripe), verification_secret: "whsec_test_secret")

    post ingest_url(token: @source.ingest_token),
         params: { type: "test.event" }.to_json,
         headers: {
           "Content-Type" => "application/json",
           "Stripe-Signature" => "invalid_signature"
         }

    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal "Invalid signature", json_response["error"]
  end

  test "accepts valid stripe signature" do
    secret = "whsec_test_secret"
    @source.update!(verification_type: verification_types(:stripe), verification_secret: secret)

    payload = { type: "test.event" }.to_json
    timestamp = Time.now.to_i
    signed_payload = "#{timestamp}.#{payload}"
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)

    post ingest_url(token: @source.ingest_token),
         params: payload,
         headers: {
           "Content-Type" => "application/json",
           "Stripe-Signature" => "t=#{timestamp},v1=#{signature}"
         }

    assert_response :accepted
  end

  test "returns 413 for payload exceeding 1 MB" do
    large_payload = "x" * (1.megabyte + 1)

    assert_no_difference "Event.count" do
      post ingest_url(token: @source.ingest_token),
           params: large_payload,
           headers: { "Content-Type" => "text/plain" }
    end

    assert_response :content_too_large
    json_response = JSON.parse(response.body)
    assert_equal "Payload too large", json_response["error"]
    assert_equal "Request body exceeds maximum allowed size of 1 MB", json_response["message"]
  end

  test "accepts payload exactly at 1 MB limit" do
    payload = "x" * 1.megabyte

    assert_difference "Event.count", 1 do
      post ingest_url(token: @source.ingest_token),
           params: payload,
           headers: { "Content-Type" => "text/plain" }
    end

    assert_response :accepted
  end

  test "accepts payload under 1 MB limit" do
    payload = "x" * 1000

    assert_difference "Event.count", 1 do
      post ingest_url(token: @source.ingest_token),
           params: payload,
           headers: { "Content-Type" => "text/plain" }
    end

    assert_response :accepted
  end

  test "rejects large payload before checking token" do
    large_payload = "x" * (1.megabyte + 1)

    # Use an invalid token - should still get 413, not 404
    post ingest_url(token: "invalid_token"),
         params: large_payload,
         headers: { "Content-Type" => "text/plain" }

    assert_response :content_too_large
  end
end
