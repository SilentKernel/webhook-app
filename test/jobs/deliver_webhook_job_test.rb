# frozen_string_literal: true

require "test_helper"

class DeliverWebhookJobTest < ActiveJob::TestCase
  setup do
    @delivery = deliveries(:pending_delivery)
    @delivery.delivery_attempts.destroy_all  # Clear any existing attempts from fixtures
    @delivery.update!(status: :queued, attempt_count: 0)
    @destination = @delivery.destination
  end

  test "marks delivery as success on 2xx response" do
    stub_request(:post, @destination.url)
      .to_return(status: 200, body: "OK", headers: { "Content-Type" => "text/plain" })

    DeliverWebhookJob.perform_now(@delivery.id)

    @delivery.reload
    assert_equal "success", @delivery.status
    assert_equal 1, @delivery.delivery_attempts.count
    assert_not_nil @delivery.completed_at
  end

  test "marks delivery as failed on error response" do
    stub_request(:post, @destination.url)
      .to_return(status: 500, body: "Internal Server Error")

    DeliverWebhookJob.perform_now(@delivery.id)

    @delivery.reload
    assert_equal "failed", @delivery.status
    assert @delivery.next_attempt_at.present?
  end

  test "creates delivery attempt record on success" do
    stub_request(:post, @destination.url)
      .to_return(status: 200, body: "OK", headers: { "X-Custom" => "header" })

    assert_difference "DeliveryAttempt.count", 1 do
      DeliverWebhookJob.perform_now(@delivery.id)
    end

    @delivery.reload
    attempt = @delivery.delivery_attempts.last
    assert_equal 1, attempt.attempt_number
    assert_equal "success", attempt.status
    assert_equal 200, attempt.response_status
    assert_equal @destination.url, attempt.request_url
    assert_equal @destination.http_method, attempt.request_method
    assert_not_nil attempt.duration_ms
  end

  test "creates delivery attempt record on failure" do
    stub_request(:post, @destination.url)
      .to_return(status: 503, body: "Service Unavailable")

    assert_difference "DeliveryAttempt.count", 1 do
      DeliverWebhookJob.perform_now(@delivery.id)
    end

    @delivery.reload
    attempt = @delivery.delivery_attempts.last
    assert_equal "failed", attempt.status
    assert_equal 503, attempt.response_status
  end

  test "handles connection errors" do
    stub_request(:post, @destination.url)
      .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

    DeliverWebhookJob.perform_now(@delivery.id)

    @delivery.reload
    assert_equal "failed", @delivery.status

    attempt = @delivery.delivery_attempts.last
    assert_equal "connection_failed", attempt.error_code
    assert_includes attempt.error_message, "Connection refused"
  end

  test "handles timeout errors" do
    stub_request(:post, @destination.url)
      .to_raise(Faraday::TimeoutError.new("Request timed out"))

    DeliverWebhookJob.perform_now(@delivery.id)

    @delivery.reload
    attempt = @delivery.delivery_attempts.last
    assert_equal "timeout", attempt.error_code
  end

  test "handles SSL errors" do
    stub_request(:post, @destination.url)
      .to_raise(Faraday::SSLError.new("SSL certificate error"))

    DeliverWebhookJob.perform_now(@delivery.id)

    @delivery.reload
    attempt = @delivery.delivery_attempts.last
    assert_equal "ssl_error", attempt.error_code
  end

  test "schedules retry on failure" do
    stub_request(:post, @destination.url)
      .to_return(status: 500)

    DeliverWebhookJob.perform_now(@delivery.id)

    @delivery.reload
    assert @delivery.can_retry?
    assert @delivery.next_attempt_at.present?
    assert_enqueued_jobs 1, only: DeliverWebhookJob
  end

  test "does not schedule retry when max attempts reached" do
    @delivery.update!(attempt_count: 4, max_attempts: 5)

    stub_request(:post, @destination.url)
      .to_return(status: 500)

    DeliverWebhookJob.perform_now(@delivery.id)

    @delivery.reload
    assert_not @delivery.can_retry?
    assert_not_nil @delivery.completed_at
    assert_no_enqueued_jobs only: DeliverWebhookJob
  end

  test "enqueues failure notification job on permanent failure" do
    @delivery.update!(attempt_count: 4, max_attempts: 5)

    stub_request(:post, @destination.url)
      .to_return(status: 500)

    assert_enqueued_with(job: SendDeliveryFailureNotificationJob) do
      DeliverWebhookJob.perform_now(@delivery.id)
    end
  end

  test "does not enqueue failure notification job when retrying" do
    @delivery.update!(attempt_count: 0, max_attempts: 5)

    stub_request(:post, @destination.url)
      .to_return(status: 500)

    assert_no_enqueued_jobs(only: SendDeliveryFailureNotificationJob) do
      DeliverWebhookJob.perform_now(@delivery.id)
    end
  end

  test "skips already successful delivery" do
    @delivery.update!(status: :success)

    stub_request(:post, @destination.url)

    assert_no_difference "DeliveryAttempt.count" do
      DeliverWebhookJob.perform_now(@delivery.id)
    end
  end

  test "does nothing for non-existent delivery" do
    assert_no_difference "DeliveryAttempt.count" do
      DeliverWebhookJob.perform_now(-1)
    end
  end

  test "sends correct request headers" do
    stub_request(:post, @destination.url)
      .with(
        headers: {
          "Content-Type" => "application/json",
          "User-Agent" => "WebhookPlatform/1.0"
        }
      )
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    assert_requested :post, @destination.url
  end

  test "sends webhook event headers" do
    event = @delivery.event
    event.update!(uid: "test-uid-123", event_type: "test.event")

    stub_request(:post, @destination.url)
      .with(
        headers: {
          "X-Webhook-Event-Id" => "test-uid-123",
          "X-Webhook-Event-Type" => "test.event"
        }
      )
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    assert_requested :post, @destination.url
  end

  test "adds bearer auth header when configured" do
    @destination.update!(auth_type: :bearer, auth_value: "my_bearer_token")

    stub_request(:post, @destination.url)
      .with(headers: { "Authorization" => "Bearer my_bearer_token" })
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    assert_requested :post, @destination.url
  end

  test "adds basic auth header when configured" do
    @destination.update!(auth_type: :basic, auth_value: "user:password")

    expected_auth = "Basic " + Base64.strict_encode64("user:password")

    stub_request(:post, @destination.url)
      .with(headers: { "Authorization" => expected_auth })
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    assert_requested :post, @destination.url
  end

  test "adds api key header when configured" do
    @destination.update!(auth_type: :api_key, auth_value: "my_api_key")

    stub_request(:post, @destination.url)
      .with(headers: { "X-API-Key" => "my_api_key" })
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    assert_requested :post, @destination.url
  end

  test "adds custom api key header when configured with header name" do
    @destination.update!(auth_type: :api_key, auth_value: "X-Custom-Key:custom_value")

    stub_request(:post, @destination.url)
      .with(headers: { "X-Custom-Key" => "custom_value" })
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    assert_requested :post, @destination.url
  end

  test "uses correct HTTP method" do
    @destination.update!(http_method: "PUT")

    stub_request(:put, @destination.url)
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    assert_requested :put, @destination.url
  end

  test "sends event payload as JSON body" do
    event = @delivery.event
    # Clear raw_body to test legacy JSON payload conversion
    event.update!(payload: { "id" => "test_123", "amount" => 1000 }, raw_body: nil)

    stub_request(:post, @destination.url)
      .with(body: '{"id":"test_123","amount":1000}')
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    assert_requested :post, @destination.url
  end

  test "truncates long response body" do
    long_body = "x" * 70_000

    stub_request(:post, @destination.url)
      .to_return(status: 200, body: long_body)

    DeliverWebhookJob.perform_now(@delivery.id)

    @delivery.reload
    attempt = @delivery.delivery_attempts.last
    assert attempt.response_body.length <= 65_535
  end

  test "forwards raw_body when present" do
    raw_xml = '<event><type>test</type></event>'
    event = @delivery.event
    event.update!(
      raw_body: raw_xml,
      content_type: "application/xml",
      body_size: raw_xml.bytesize
    )

    stub_request(:post, @destination.url)
      .with(body: raw_xml)
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    assert_requested :post, @destination.url, body: raw_xml
  end

  test "uses original content-type when raw_body present" do
    raw_text = "Hello, world!"
    event = @delivery.event
    event.update!(
      raw_body: raw_text,
      content_type: "text/plain",
      body_size: raw_text.bytesize
    )

    stub_request(:post, @destination.url)
      .with(headers: { "Content-Type" => "text/plain" })
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    assert_requested :post, @destination.url
  end

  test "forwards form-urlencoded body with correct content-type" do
    form_body = "event=test&value=123"
    event = @delivery.event
    event.update!(
      raw_body: form_body,
      content_type: "application/x-www-form-urlencoded",
      body_size: form_body.bytesize
    )

    stub_request(:post, @destination.url)
      .with(
        body: form_body,
        headers: { "Content-Type" => "application/x-www-form-urlencoded" }
      )
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    assert_requested :post, @destination.url
  end

  test "falls back to JSON for legacy events without raw_body" do
    event = @delivery.event
    event.update!(
      payload: { "id" => "legacy_123", "type" => "test" },
      raw_body: nil,
      content_type: "application/json"
    )

    expected_body = '{"id":"legacy_123","type":"test"}'

    stub_request(:post, @destination.url)
      .with(
        body: expected_body,
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    assert_requested :post, @destination.url
  end

  test "stores raw_body in delivery attempt request_body" do
    raw_xml = '<webhook><id>123</id></webhook>'
    event = @delivery.event
    event.update!(
      raw_body: raw_xml,
      content_type: "application/xml",
      body_size: raw_xml.bytesize
    )

    stub_request(:post, @destination.url)
      .to_return(status: 200)

    DeliverWebhookJob.perform_now(@delivery.id)

    @delivery.reload
    attempt = @delivery.delivery_attempts.last
    assert_equal raw_xml, attempt.request_body
    assert_equal "application/xml", attempt.request_headers["Content-Type"]
  end
end
