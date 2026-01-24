# frozen_string_literal: true

require "test_helper"

class DeliveriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    @organization = organizations(:acme)
    @pending_delivery = deliveries(:pending_delivery)
    @successful_delivery = deliveries(:successful_delivery)
    @failed_delivery = deliveries(:failed_delivery)
    @retrying_delivery = deliveries(:retrying_delivery)
    @destination = destinations(:production_api)
    @event = events(:stripe_payment_event)
    sign_in @user
  end

  # Index tests
  test "should get index" do
    get deliveries_url(locale: :en)
    assert_response :success
  end

  test "redirects to login when not authenticated" do
    sign_out @user
    get deliveries_url(locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
  end

  test "index filters by status" do
    get deliveries_url(locale: :en, status: "pending")
    assert_response :success
  end

  test "index filters by destination_id" do
    get deliveries_url(locale: :en, destination_id: @destination.id)
    assert_response :success
  end

  test "index filters by event_id" do
    get deliveries_url(locale: :en, event_id: @event.id)
    assert_response :success
  end

  # Show tests
  test "should show delivery" do
    get delivery_url(@pending_delivery, locale: :en)
    assert_response :success
  end

  test "should not show delivery from another organization" do
    other_org_event = events(:other_org_event)
    other_org_connection = connections(:other_org_connection)
    other_org_destination = destinations(:other_org_destination)
    other_org_delivery = Delivery.create!(
      event: other_org_event,
      connection: other_org_connection,
      destination: other_org_destination,
      status: :pending,
      max_attempts: 5
    )

    get delivery_url(other_org_delivery, locale: :en)
    assert_response :not_found
  end

  # Replay tests
  test "replay creates new delivery and redirects to it" do
    assert @failed_delivery.can_replay?
    original_delivery_count = Delivery.count

    assert_enqueued_with(job: DeliverWebhookJob) do
      post replay_delivery_url(@failed_delivery, locale: :en)
    end

    assert_equal original_delivery_count + 1, Delivery.count

    new_delivery = Delivery.last
    assert_redirected_to delivery_path(new_delivery, locale: :en)
    assert_equal "A new delivery has been created.", flash[:notice]

    # Verify new delivery has same attributes
    assert_equal @failed_delivery.event, new_delivery.event
    assert_equal @failed_delivery.connection, new_delivery.connection
    assert_equal @failed_delivery.destination, new_delivery.destination
    assert_equal @failed_delivery.max_attempts, new_delivery.max_attempts
    assert new_delivery.pending?
    assert_equal 0, new_delivery.attempt_count
  end

  test "replay shows alert when cannot replay successful delivery" do
    assert_not @successful_delivery.can_replay?

    assert_no_difference "Delivery.count" do
      post replay_delivery_url(@successful_delivery, locale: :en)
    end

    assert_redirected_to delivery_path(@successful_delivery, locale: :en)
    assert_equal "This delivery cannot be replayed.", flash[:alert]
  end

  test "replay should not work for delivery from another organization" do
    other_org_event = events(:other_org_event)
    other_org_connection = connections(:other_org_connection)
    other_org_destination = destinations(:other_org_destination)
    other_org_delivery = Delivery.create!(
      event: other_org_event,
      connection: other_org_connection,
      destination: other_org_destination,
      status: :failed,
      attempt_count: 1,
      max_attempts: 5
    )

    assert_no_difference "Delivery.count" do
      post replay_delivery_url(other_org_delivery, locale: :en)
    end
    assert_response :not_found
  end
end
