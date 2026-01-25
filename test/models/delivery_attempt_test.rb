# frozen_string_literal: true

require "test_helper"

class DeliveryAttemptTest < ActiveSupport::TestCase
  test "valid delivery_attempt with required attributes" do
    attempt = DeliveryAttempt.new(
      delivery: deliveries(:pending_delivery),
      attempt_number: 1,
      request_url: "https://api.example.com/webhooks",
      request_method: "POST",
      attempted_at: Time.current
    )
    assert attempt.valid?
  end

  test "requires delivery" do
    attempt = DeliveryAttempt.new(
      attempt_number: 1,
      request_url: "https://api.example.com/webhooks",
      request_method: "POST",
      attempted_at: Time.current
    )
    assert_not attempt.valid?
    assert_includes attempt.errors[:delivery], "must exist"
  end

  test "requires attempt_number" do
    attempt = DeliveryAttempt.new(
      delivery: deliveries(:pending_delivery),
      request_url: "https://api.example.com/webhooks",
      request_method: "POST",
      attempted_at: Time.current
    )
    assert_not attempt.valid?
    assert_includes attempt.errors[:attempt_number], "can't be blank"
  end

  test "attempt_number must be positive" do
    attempt = DeliveryAttempt.new(
      delivery: deliveries(:pending_delivery),
      attempt_number: 0,
      request_url: "https://api.example.com/webhooks",
      request_method: "POST",
      attempted_at: Time.current
    )
    assert_not attempt.valid?
    assert attempt.errors[:attempt_number].any?
  end

  test "requires request_url" do
    attempt = DeliveryAttempt.new(
      delivery: deliveries(:pending_delivery),
      attempt_number: 1,
      request_method: "POST",
      attempted_at: Time.current
    )
    assert_not attempt.valid?
    assert_includes attempt.errors[:request_url], "can't be blank"
  end

  test "requires request_method" do
    attempt = DeliveryAttempt.new(
      delivery: deliveries(:pending_delivery),
      attempt_number: 1,
      request_url: "https://api.example.com/webhooks",
      attempted_at: Time.current
    )
    assert_not attempt.valid?
    assert_includes attempt.errors[:request_method], "can't be blank"
  end

  test "requires attempted_at" do
    attempt = DeliveryAttempt.new(
      delivery: deliveries(:pending_delivery),
      attempt_number: 1,
      request_url: "https://api.example.com/webhooks",
      request_method: "POST"
    )
    assert_not attempt.valid?
    assert_includes attempt.errors[:attempted_at], "can't be blank"
  end

  test "status enum includes expected values" do
    assert_equal 0, DeliveryAttempt.statuses[:pending]
    assert_equal 1, DeliveryAttempt.statuses[:success]
    assert_equal 2, DeliveryAttempt.statuses[:failed]
  end

  test "default status is pending" do
    attempt = DeliveryAttempt.new(
      delivery: deliveries(:pending_delivery),
      attempt_number: 2,
      request_url: "https://api.example.com/webhooks",
      request_method: "POST",
      attempted_at: Time.current
    )
    attempt.save!
    assert attempt.pending?
  end

  test "belongs_to delivery" do
    attempt = delivery_attempts(:successful_attempt)
    assert_equal deliveries(:successful_delivery), attempt.delivery
  end

  test "has_one event through delivery" do
    attempt = delivery_attempts(:successful_attempt)
    assert_equal attempt.delivery.event, attempt.event
  end

  test "has_one destination through delivery" do
    attempt = delivery_attempts(:successful_attempt)
    assert_equal attempt.delivery.destination, attempt.destination
  end

  test "success? returns true for 2xx response status" do
    attempt = DeliveryAttempt.new(response_status: 200)
    assert attempt.success?

    attempt.response_status = 201
    assert attempt.success?

    attempt.response_status = 299
    assert attempt.success?
  end

  test "success? returns false for non-2xx response status" do
    attempt = DeliveryAttempt.new(response_status: 400)
    assert_not attempt.success?

    attempt.response_status = 500
    assert_not attempt.success?

    attempt.response_status = 301
    assert_not attempt.success?
  end

  test "success? returns false when response_status is nil" do
    attempt = DeliveryAttempt.new(response_status: nil)
    assert_not attempt.success?
  end

  test "duration_seconds converts duration_ms to seconds" do
    attempt = DeliveryAttempt.new(duration_ms: 1500)
    assert_equal 1.5, attempt.duration_seconds

    attempt.duration_ms = 150
    assert_equal 0.15, attempt.duration_seconds

    attempt.duration_ms = 30000
    assert_equal 30.0, attempt.duration_seconds
  end

  test "duration_seconds returns nil when duration_ms is nil" do
    attempt = DeliveryAttempt.new(duration_ms: nil)
    assert_nil attempt.duration_seconds
  end

  test "stores request_headers as jsonb" do
    attempt = delivery_attempts(:successful_attempt)
    assert_kind_of Hash, attempt.request_headers
    assert_equal "application/json", attempt.request_headers["content-type"]
  end

  test "stores response_headers as jsonb" do
    attempt = delivery_attempts(:successful_attempt)
    assert_kind_of Hash, attempt.response_headers
  end

  test "request_body can store large text" do
    large_body = "x" * 10_000
    attempt = DeliveryAttempt.new(
      delivery: deliveries(:pending_delivery),
      attempt_number: 3,
      request_url: "https://api.example.com/webhooks",
      request_method: "POST",
      attempted_at: Time.current,
      request_body: large_body
    )
    attempt.save!
    assert_equal large_body, attempt.reload.request_body
  end

  test "response_body can store large text" do
    large_body = "y" * 10_000
    attempt = DeliveryAttempt.new(
      delivery: deliveries(:pending_delivery),
      attempt_number: 4,
      request_url: "https://api.example.com/webhooks",
      request_method: "POST",
      attempted_at: Time.current,
      response_body: large_body
    )
    attempt.save!
    assert_equal large_body, attempt.reload.response_body
  end

  test "error_message and error_code can be set" do
    attempt = delivery_attempts(:failed_attempt_timeout)
    assert_equal "Request timed out after 30 seconds", attempt.error_message
    assert_equal "timeout", attempt.error_code
  end
end
