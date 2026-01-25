# frozen_string_literal: true

require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "valid event with required attributes" do
    event = Event.new(
      source: sources(:stripe_production),
      received_at: Time.current
    )
    assert event.valid?
  end

  test "generates uid on create" do
    event = Event.new(
      source: sources(:stripe_production),
      received_at: Time.current
    )
    assert_nil event.uid
    event.save!
    assert_not_nil event.uid
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i, event.uid)
  end

  test "does not overwrite existing uid" do
    event = Event.new(
      source: sources(:stripe_production),
      uid: "custom_uid_12345",
      received_at: Time.current
    )
    event.save!
    assert_equal "custom_uid_12345", event.uid
  end

  test "requires received_at" do
    event = Event.new(
      source: sources(:stripe_production)
    )
    assert_not event.valid?
    assert_includes event.errors[:received_at], "can't be blank"
  end

  test "uid must be unique" do
    existing = events(:stripe_payment_event)
    event = Event.new(
      source: sources(:stripe_production),
      uid: existing.uid,
      received_at: Time.current
    )
    assert_not event.valid?
    assert_includes event.errors[:uid], "has already been taken"
  end

  test "belongs_to source" do
    event = events(:stripe_payment_event)
    assert_equal sources(:stripe_production), event.source
  end

  test "has_one organization through source" do
    event = events(:stripe_payment_event)
    assert_equal organizations(:acme), event.organization
  end

  test "has_many deliveries" do
    event = events(:stripe_payment_event)
    assert_respond_to event, :deliveries
  end

  test "destroying event destroys deliveries" do
    event = events(:stripe_payment_event)
    delivery_count = event.deliveries.count
    assert delivery_count > 0

    assert_difference "Delivery.count", -delivery_count do
      event.destroy
    end
  end

  test "scope recent orders by received_at descending" do
    events = Event.recent.limit(2)
    assert events.first.received_at >= events.second.received_at
  end

  test "scope by_event_type filters by event type" do
    events = Event.by_event_type("payment.completed")
    assert events.all? { |e| e.event_type == "payment.completed" }
    assert events.count >= 1
  end

  test "scope since filters events after given time" do
    time = 2.hours.ago
    events = Event.since(time)
    assert events.all? { |e| e.received_at >= time }
  end

  test "scope until filters events before given time" do
    time = 1.minute.from_now
    events = Event.until(time)
    assert events.all? { |e| e.received_at <= time }
  end

  test "stores payload as jsonb" do
    event = events(:stripe_payment_event)
    assert_kind_of Hash, event.payload
    assert_equal "pay_123", event.payload["id"]
  end

  test "stores headers as jsonb" do
    event = events(:stripe_payment_event)
    assert_kind_of Hash, event.headers
    assert_equal "application/json", event.headers["content-type"]
  end

  test "stores query_params as jsonb" do
    event = events(:stripe_payment_event)
    assert_kind_of Hash, event.query_params
  end

  test "event_type can be nil" do
    event = Event.new(
      source: sources(:stripe_production),
      received_at: Time.current,
      event_type: nil
    )
    assert event.valid?
  end

  test "source_ip can be nil" do
    event = Event.new(
      source: sources(:stripe_production),
      received_at: Time.current,
      source_ip: nil
    )
    assert event.valid?
  end

  # Status enum tests
  test "status defaults to received" do
    event = Event.create!(
      source: sources(:stripe_production),
      received_at: Time.current
    )
    assert_equal "received", event.status
    assert event.received?
  end

  test "status can be authentication_failed" do
    event = Event.create!(
      source: sources(:stripe_production),
      received_at: Time.current,
      status: :authentication_failed
    )
    assert_equal "authentication_failed", event.status
    assert event.authentication_failed?
  end

  test "status can be payload_too_large" do
    event = Event.create!(
      source: sources(:stripe_production),
      received_at: Time.current,
      status: :payload_too_large
    )
    assert_equal "payload_too_large", event.status
    assert event.payload_too_large?
  end

  test "scope by_status filters by status" do
    # Create events with different statuses
    Event.create!(source: sources(:stripe_production), received_at: Time.current, status: :received)
    Event.create!(source: sources(:stripe_production), received_at: Time.current, status: :authentication_failed)
    Event.create!(source: sources(:stripe_production), received_at: Time.current, status: :payload_too_large)

    received_events = Event.by_status(:received)
    auth_failed_events = Event.by_status(:authentication_failed)
    too_large_events = Event.by_status(:payload_too_large)

    assert received_events.all?(&:received?)
    assert auth_failed_events.all?(&:authentication_failed?)
    assert too_large_events.all?(&:payload_too_large?)
  end

  test "replayable? returns true for received events" do
    event = Event.new(status: :received)
    assert event.replayable?
  end

  test "replayable? returns false for authentication_failed events" do
    event = Event.new(status: :authentication_failed)
    assert_not event.replayable?
  end

  test "replayable? returns false for payload_too_large events" do
    event = Event.new(status: :payload_too_large)
    assert_not event.replayable?
  end
end
