# frozen_string_literal: true

require "test_helper"

class DeliveryTest < ActiveSupport::TestCase
  test "valid delivery with required attributes" do
    delivery = Delivery.new(
      event: events(:stripe_payment_event),
      connection: connections(:stripe_to_production),
      destination: destinations(:production_api)
    )
    assert delivery.valid?
  end

  test "requires event" do
    delivery = Delivery.new(
      connection: connections(:stripe_to_production),
      destination: destinations(:production_api)
    )
    assert_not delivery.valid?
    assert_includes delivery.errors[:event], "must exist"
  end

  test "requires connection" do
    delivery = Delivery.new(
      event: events(:stripe_payment_event),
      destination: destinations(:production_api)
    )
    assert_not delivery.valid?
    assert_includes delivery.errors[:connection], "must exist"
  end

  test "requires destination" do
    delivery = Delivery.new(
      event: events(:stripe_payment_event),
      connection: connections(:stripe_to_production)
    )
    assert_not delivery.valid?
    assert_includes delivery.errors[:destination], "must exist"
  end

  test "attempt_count must be non-negative" do
    delivery = Delivery.new(
      event: events(:stripe_payment_event),
      connection: connections(:stripe_to_production),
      destination: destinations(:production_api),
      attempt_count: -1
    )
    assert_not delivery.valid?
    assert delivery.errors[:attempt_count].any?
  end

  test "max_attempts must be positive" do
    delivery = Delivery.new(
      event: events(:stripe_payment_event),
      connection: connections(:stripe_to_production),
      destination: destinations(:production_api),
      max_attempts: 0
    )
    assert_not delivery.valid?
    assert delivery.errors[:max_attempts].any?
  end

  test "status enum includes expected values" do
    assert_equal 0, Delivery.statuses[:pending]
    assert_equal 1, Delivery.statuses[:queued]
    assert_equal 2, Delivery.statuses[:delivering]
    assert_equal 3, Delivery.statuses[:success]
    assert_equal 4, Delivery.statuses[:failed]
  end

  test "default status is pending" do
    delivery = Delivery.new(
      event: events(:stripe_payment_event),
      connection: connections(:stripe_to_production),
      destination: destinations(:production_api)
    )
    delivery.save!
    assert delivery.pending?
  end

  test "belongs_to event" do
    delivery = deliveries(:successful_delivery)
    assert_equal events(:stripe_payment_event), delivery.event
  end

  test "belongs_to connection" do
    delivery = deliveries(:successful_delivery)
    assert_kind_of Connection, delivery.connection
  end

  test "belongs_to destination" do
    delivery = deliveries(:successful_delivery)
    assert_kind_of Destination, delivery.destination
  end

  test "has_one source through event" do
    delivery = deliveries(:successful_delivery)
    assert_equal delivery.event.source, delivery.source
  end

  test "has_one organization through event" do
    delivery = deliveries(:successful_delivery)
    assert_equal delivery.event.organization, delivery.organization
  end

  test "has_many delivery_attempts" do
    delivery = deliveries(:successful_delivery)
    assert_respond_to delivery, :delivery_attempts
    assert delivery.delivery_attempts.count >= 1
  end

  test "destroying delivery destroys delivery_attempts" do
    delivery = deliveries(:successful_delivery)
    attempt_count = delivery.delivery_attempts.count
    assert attempt_count > 0

    assert_difference "DeliveryAttempt.count", -attempt_count do
      delivery.destroy
    end
  end

  test "scope pending_retry returns retryable deliveries" do
    # Create a delivery ready to retry
    delivery = Delivery.create!(
      event: events(:github_push_event),
      connection: connections(:paused_connection),
      destination: destinations(:staging_api),
      status: :failed,
      attempt_count: 2,
      max_attempts: 5,
      next_attempt_at: 1.minute.ago
    )

    pending = Delivery.pending_retry
    assert_includes pending, delivery
  end

  test "scope pending_retry excludes deliveries with future next_attempt_at" do
    delivery = deliveries(:retrying_delivery)
    # This delivery has next_attempt_at in the future
    pending = Delivery.pending_retry
    assert_not_includes pending, delivery
  end

  test "scope pending_retry excludes deliveries at max attempts" do
    delivery = deliveries(:failed_delivery)
    # This delivery has attempt_count >= max_attempts
    pending = Delivery.pending_retry
    assert_not_includes pending, delivery
  end

  test "scope successful returns success status deliveries" do
    successful = Delivery.successful
    assert successful.all?(&:success?)
    assert_includes successful, deliveries(:successful_delivery)
  end

  test "scope failed returns failed deliveries at max attempts" do
    failed = Delivery.failed
    assert failed.all? { |d| d.failed? && d.attempt_count >= d.max_attempts }
  end

  test "scope in_progress returns queued and delivering" do
    in_progress = Delivery.in_progress
    assert in_progress.all? { |d| d.queued? || d.delivering? }
    assert_includes in_progress, deliveries(:queued_delivery)
    assert_includes in_progress, deliveries(:delivering_delivery)
  end

  test "can_retry? returns true when under max attempts" do
    delivery = Delivery.new(attempt_count: 2, max_attempts: 5)
    assert delivery.can_retry?
  end

  test "can_retry? returns false when at max attempts" do
    delivery = Delivery.new(attempt_count: 5, max_attempts: 5)
    assert_not delivery.can_retry?
  end

  test "can_retry? returns false when over max attempts" do
    delivery = Delivery.new(attempt_count: 6, max_attempts: 5)
    assert_not delivery.can_retry?
  end

  test "mark_success! updates status, completed_at, and increments attempt_count" do
    delivery = deliveries(:pending_delivery)
    original_count = delivery.attempt_count
    freeze_time do
      delivery.mark_success!
      assert delivery.success?
      assert_equal Time.current, delivery.completed_at
      assert_equal original_count + 1, delivery.attempt_count
    end
  end

  test "mark_failed! increments attempt_count" do
    delivery = deliveries(:pending_delivery)
    original_count = delivery.attempt_count

    delivery.mark_failed!

    assert_equal original_count + 1, delivery.attempt_count
  end

  test "mark_failed! sets next_attempt_at when can retry" do
    delivery = Delivery.create!(
      event: events(:github_push_event),
      connection: connections(:paused_connection),
      destination: destinations(:staging_api),
      status: :pending,
      attempt_count: 1,
      max_attempts: 5
    )

    freeze_time do
      delivery.mark_failed!
      # After mark_failed!, attempt_count is 2, so backoff is 2^2 = 4 minutes
      assert_equal Time.current + 4.minutes, delivery.next_attempt_at
    end
  end

  test "mark_failed! sets status to failed when max attempts reached" do
    delivery = Delivery.create!(
      event: events(:github_push_event),
      connection: connections(:paused_connection),
      destination: destinations(:staging_api),
      status: :delivering,
      attempt_count: 4,
      max_attempts: 5
    )

    freeze_time do
      delivery.mark_failed!
      assert delivery.failed?
      assert_equal Time.current, delivery.completed_at
    end
  end

  test "calculate_next_attempt_at uses exponential backoff" do
    freeze_time do
      delivery = Delivery.new(attempt_count: 0)
      assert_equal Time.current + 1.minute, delivery.calculate_next_attempt_at

      delivery.attempt_count = 1
      assert_equal Time.current + 2.minutes, delivery.calculate_next_attempt_at

      delivery.attempt_count = 2
      assert_equal Time.current + 4.minutes, delivery.calculate_next_attempt_at

      delivery.attempt_count = 3
      assert_equal Time.current + 8.minutes, delivery.calculate_next_attempt_at
    end
  end

  test "calculate_next_attempt_at caps at 24 hours" do
    freeze_time do
      delivery = Delivery.new(attempt_count: 15) # 2^15 = 32768 minutes > 24 hours

      max_backoff = 24.hours
      assert_equal Time.current + max_backoff, delivery.calculate_next_attempt_at
    end
  end
end
