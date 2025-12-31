# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # status_badge tests
  test "status_badge returns success badge for active status" do
    result = status_badge("active")
    assert_match(/badge-success/, result)
    assert_match(/Active/, result)
  end

  test "status_badge returns warning badge for paused status" do
    result = status_badge("paused")
    assert_match(/badge-warning/, result)
    assert_match(/Paused/, result)
  end

  test "status_badge returns error badge for disabled status" do
    result = status_badge("disabled")
    assert_match(/badge-error/, result)
    assert_match(/Disabled/, result)
  end

  test "status_badge returns ghost badge for unknown status" do
    result = status_badge("unknown")
    assert_match(/badge-ghost/, result)
  end

  # delivery_status_badge tests
  test "delivery_status_badge returns ghost badge for pending status" do
    result = delivery_status_badge("pending")
    assert_match(/badge-ghost/, result)
    assert_match(/Pending/, result)
  end

  test "delivery_status_badge returns ghost badge for queued status" do
    result = delivery_status_badge("queued")
    assert_match(/badge-ghost/, result)
    assert_match(/Queued/, result)
  end

  test "delivery_status_badge returns info badge for delivering status" do
    result = delivery_status_badge("delivering")
    assert_match(/badge-info/, result)
    assert_match(/Delivering/, result)
  end

  test "delivery_status_badge returns success badge for success status" do
    result = delivery_status_badge("success")
    assert_match(/badge-success/, result)
    assert_match(/Success/, result)
  end

  test "delivery_status_badge returns error badge for failed status" do
    result = delivery_status_badge("failed")
    assert_match(/badge-error/, result)
    assert_match(/Failed/, result)
  end

  # delivery_status_summary tests
  test "delivery_status_summary returns dash when no deliveries" do
    event = events(:stripe_payment_event)
    event.deliveries.destroy_all
    event.reload

    result = delivery_status_summary(event)
    assert_equal "—", result
  end

  test "delivery_status_summary shows success when all deliveries successful" do
    event = events(:stripe_payment_event)
    event.deliveries.destroy_all
    event.deliveries.create!(
      connection: connections(:stripe_to_production),
      destination: destinations(:production_api),
      status: :success,
      max_attempts: 5
    )
    event.reload

    result = delivery_status_summary(event)
    assert_match(/text-success/, result)
    assert_match(/1\/1 ✓/, result)
  end

  test "delivery_status_summary shows error when all deliveries failed" do
    event = events(:stripe_payment_event)
    event.deliveries.destroy_all
    event.deliveries.create!(
      connection: connections(:stripe_to_production),
      destination: destinations(:production_api),
      status: :failed,
      max_attempts: 5,
      attempt_count: 5
    )
    event.reload

    result = delivery_status_summary(event)
    assert_match(/text-error/, result)
    assert_match(/0\/1 ✗/, result)
  end

  test "delivery_status_summary shows warning when mixed results" do
    event = events(:stripe_payment_event)
    event.deliveries.destroy_all
    event.deliveries.create!(
      connection: connections(:stripe_to_production),
      destination: destinations(:production_api),
      status: :success,
      max_attempts: 5
    )
    event.deliveries.create!(
      connection: connections(:github_to_staging),
      destination: destinations(:staging_api),
      status: :failed,
      max_attempts: 5,
      attempt_count: 5
    )
    event.reload

    result = delivery_status_summary(event)
    assert_match(/text-warning/, result)
    assert_match(/1\/2 ⚠/, result)
  end

  # relative_time tests
  test "relative_time returns dash for nil time" do
    result = relative_time(nil)
    assert_equal "—", result
  end

  test "relative_time returns time ago with title" do
    time = 5.minutes.ago
    result = relative_time(time)
    assert_match(/ago/, result)
    assert_match(/title=/, result)
  end

  # next_retry_display tests
  test "next_retry_display returns dash when no next_attempt_at" do
    delivery = deliveries(:successful_delivery)
    delivery.next_attempt_at = nil

    result = next_retry_display(delivery)
    assert_equal "—", result
  end

  test "next_retry_display shows time remaining for future retry" do
    delivery = deliveries(:retrying_delivery)
    delivery.next_attempt_at = 10.minutes.from_now

    result = next_retry_display(delivery)
    assert_match(/In/, result)
  end

  test "next_retry_display shows Pending for past retry time" do
    delivery = deliveries(:retrying_delivery)
    delivery.next_attempt_at = 1.minute.ago

    result = next_retry_display(delivery)
    assert_equal "Pending", result
  end
end
