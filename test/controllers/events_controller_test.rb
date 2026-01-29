# frozen_string_literal: true

require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    @organization = organizations(:acme)
    @event = events(:stripe_payment_event)
    @github_event = events(:github_push_event)
    @other_org_event = events(:other_org_event)
    @source = sources(:stripe_production)
    @connection = connections(:stripe_to_production)
    sign_in @user
  end

  # Index tests
  test "should get index" do
    get events_url(locale: :en)
    assert_response :success
  end

  test "redirects to login when not authenticated" do
    sign_out @user
    get events_url(locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
  end

  test "index filters by source_id" do
    get events_url(locale: :en, source_id: @source.id)
    assert_response :success
  end

  test "index filters by event_type" do
    get events_url(locale: :en, event_type: "payment.completed")
    assert_response :success
  end

  test "index filters by since date" do
    get events_url(locale: :en, since: 30.minutes.ago.iso8601)
    assert_response :success
  end

  test "index filters by until date" do
    get events_url(locale: :en, until: 30.minutes.ago.iso8601)
    assert_response :success
  end

  # Show tests
  test "should show event" do
    get event_url(@event, locale: :en)
    assert_response :success
  end

  test "should not show event from another organization" do
    get event_url(@other_org_event, locale: :en)
    assert_response :not_found
  end

  # Replay tests
  test "replay creates queued deliveries for active connections and enqueues jobs" do
    initial_delivery_count = @event.deliveries.count
    active_connections_count = @event.source.connections.active.count

    assert_enqueued_jobs active_connections_count, only: DeliverWebhookJob do
      post replay_event_url(@event, locale: :en)
    end

    assert_redirected_to event_path(@event, locale: :en)
    assert_match(/queued for replay/, flash[:notice])

    @event.reload
    assert @event.deliveries.count > initial_delivery_count

    new_delivery = @event.deliveries.order(created_at: :desc).first
    assert new_delivery.queued?
    assert_equal Delivery::DEFAULT_MAX_ATTEMPTS, new_delivery.max_attempts
  end

  test "replay shows alert when no active connections" do
    source_without_connections = sources(:paused_source)
    event_without_connections = Event.create!(
      source: source_without_connections,
      uid: "test_uid_no_connections",
      event_type: "test.event",
      raw_body: '{"test": true}',
      headers: {},
      query_params: {},
      received_at: Time.current
    )

    post replay_event_url(event_without_connections, locale: :en)

    assert_redirected_to event_path(event_without_connections, locale: :en)
    assert_equal "No active connections to replay to.", flash[:alert]
  end

  test "replay should not work for event from another organization" do
    post replay_event_url(@other_org_event, locale: :en)
    assert_response :not_found
  end

  test "replay creates deliveries for all active connections on source" do
    active_connections = @event.source.connections.active

    assert_difference("Delivery.count", active_connections.count) do
      post replay_event_url(@event, locale: :en)
    end
  end
end
