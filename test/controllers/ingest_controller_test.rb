# frozen_string_literal: true

require "test_helper"

class IngestControllerTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:stripe_production)
    @source.update!(verification_type: "none", status: :active)
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
    assert_equal "Webhook received", json_response["message"]
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

  test "handles non-JSON content type" do
    post ingest_url(token: @source.ingest_token),
         params: "raw body content",
         headers: { "Content-Type" => "text/plain" }

    assert_response :accepted
    event = Event.last
    assert_equal({ "raw" => "raw body content" }, event.payload)
  end

  test "returns 401 for invalid stripe signature" do
    @source.update!(verification_type: "stripe", verification_secret: "whsec_test_secret")

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
    @source.update!(verification_type: "stripe", verification_secret: secret)

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
end
