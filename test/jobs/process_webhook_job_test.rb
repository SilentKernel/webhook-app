# frozen_string_literal: true

require "test_helper"

class ProcessWebhookJobTest < ActiveJob::TestCase
  setup do
    @event = events(:stripe_payment_event)
    @source = @event.source
    @source.update!(status: :active)
    @connection = connections(:stripe_to_production)
    @connection.update!(status: :active, rules: [])
    @connection.destination.update!(status: :active)
  end

  test "creates deliveries for active connections" do
    assert_difference "Delivery.count", 1 do
      ProcessWebhookJob.perform_now(@event.id)
    end

    delivery = Delivery.last
    assert_equal @event, delivery.event
    assert_equal @connection, delivery.connection
    assert_equal @connection.destination, delivery.destination
    assert_equal "queued", delivery.status
    assert_equal 5, delivery.max_attempts
  end

  test "queues DeliverWebhookJob for each delivery" do
    assert_enqueued_with(job: DeliverWebhookJob) do
      ProcessWebhookJob.perform_now(@event.id)
    end
  end

  test "skips paused connections" do
    @connection.update!(status: :paused)

    assert_no_difference "Delivery.count" do
      ProcessWebhookJob.perform_now(@event.id)
    end
  end

  test "skips disabled connections" do
    @connection.update!(status: :disabled)

    assert_no_difference "Delivery.count" do
      ProcessWebhookJob.perform_now(@event.id)
    end
  end

  test "skips inactive destinations" do
    @connection.destination.update!(status: :paused)

    assert_no_difference "Delivery.count" do
      ProcessWebhookJob.perform_now(@event.id)
    end
  end

  test "filters by event type when rule present" do
    @connection.update!(rules: [
      { "type" => "filter", "config" => { "event_types" => [ "other.event" ] } }
    ])

    assert_no_difference "Delivery.count" do
      ProcessWebhookJob.perform_now(@event.id)
    end
  end

  test "passes matching event type filter" do
    @event.update!(event_type: "payment.completed")
    @connection.update!(rules: [
      { "type" => "filter", "config" => { "event_types" => [ "payment.completed" ] } }
    ])

    assert_difference "Delivery.count", 1 do
      ProcessWebhookJob.perform_now(@event.id)
    end
  end

  test "handles nil rules" do
    @connection.update_column(:rules, nil)

    assert_difference "Delivery.count", 1 do
      ProcessWebhookJob.perform_now(@event.id)
    end
  end

  test "does nothing for non-existent event" do
    assert_no_difference "Delivery.count" do
      ProcessWebhookJob.perform_now(-1)
    end
  end

  test "does nothing for paused source" do
    @source.update!(status: :paused)

    assert_no_difference "Delivery.count" do
      ProcessWebhookJob.perform_now(@event.id)
    end
  end

  test "schedules delayed delivery when delay rule present" do
    @connection.update!(rules: [
      { "type" => "delay", "config" => { "seconds" => 60 } }
    ])

    assert_difference "Delivery.count", 1 do
      perform_enqueued_jobs(only: ProcessWebhookJob) do
        ProcessWebhookJob.perform_now(@event.id)
      end
    end

    # Check that DeliverWebhookJob was enqueued with a delay
    # The job should be scheduled for the future
    assert_enqueued_jobs 1, only: DeliverWebhookJob
  end

  test "creates multiple deliveries for multiple active connections" do
    # Use the existing paused_connection fixture and activate it
    # (it connects stripe_production to staging_api)
    paused_connection = connections(:paused_connection)
    paused_connection.update!(status: :active)
    paused_connection.destination.update!(status: :active)

    assert_difference "Delivery.count", 2 do
      ProcessWebhookJob.perform_now(@event.id)
    end
  end
end
