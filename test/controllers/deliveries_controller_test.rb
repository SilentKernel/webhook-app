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

  # Retry tests
  test "retry updates status to pending when can_retry is true" do
    assert @retrying_delivery.can_retry?

    post retry_delivery_url(@retrying_delivery, locale: :en)

    assert_redirected_to delivery_path(@retrying_delivery, locale: :en)
    assert_match(/queued for retry/, flash[:notice])

    @retrying_delivery.reload
    assert @retrying_delivery.pending?
    assert_nil @retrying_delivery.next_attempt_at
  end

  test "retry shows alert when cannot retry" do
    assert_not @failed_delivery.can_retry?

    post retry_delivery_url(@failed_delivery, locale: :en)

    assert_redirected_to delivery_path(@failed_delivery, locale: :en)
    assert_equal "This delivery cannot be retried.", flash[:alert]
  end

  test "retry should not work for delivery from another organization" do
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

    post retry_delivery_url(other_org_delivery, locale: :en)
    assert_response :not_found
  end
end
