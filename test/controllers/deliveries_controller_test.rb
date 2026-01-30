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

  test "index filters by event_type" do
    get deliveries_url(locale: :en, event_type: "payment.completed")
    assert_response :success
    assert_select "span.badge", text: "payment.completed"
  end

  test "index displays event type column" do
    get deliveries_url(locale: :en)
    assert_response :success
    assert_select "th", text: "Event Type"
    assert_select "span.badge.badge-outline", minimum: 1
  end

  test "index displays source column" do
    get deliveries_url(locale: :en)
    assert_response :success
    assert_select "th", text: "Source"
  end

  # Show tests
  test "should show delivery" do
    get delivery_url(@pending_delivery, locale: :en)
    assert_response :success
  end

  test "show displays event type" do
    get delivery_url(@pending_delivery, locale: :en)
    assert_response :success
    assert_select "th", text: "Event Type"
    assert_select "span.badge.badge-outline", minimum: 1
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
      max_attempts: 18
    )

    get delivery_url(other_org_delivery, locale: :en)
    assert_response :not_found
  end

  # Retry tests
  test "should retry failed delivery" do
    post retry_delivery_url(@failed_delivery, locale: :en)
    assert_redirected_to delivery_url(@failed_delivery, locale: :en)
    assert_equal "Delivery queued for retry.", flash[:notice]

    @failed_delivery.reload
    assert @failed_delivery.queued?
    assert_nil @failed_delivery.next_attempt_at
  end

  test "should not retry successful delivery" do
    post retry_delivery_url(@successful_delivery, locale: :en)
    assert_redirected_to delivery_url(@successful_delivery, locale: :en)
    assert_equal "Cannot retry this delivery.", flash[:alert]

    @successful_delivery.reload
    assert @successful_delivery.success?
  end

  test "should not retry pending delivery" do
    post retry_delivery_url(@pending_delivery, locale: :en)
    assert_redirected_to delivery_url(@pending_delivery, locale: :en)
    assert_equal "Cannot retry this delivery.", flash[:alert]

    @pending_delivery.reload
    assert @pending_delivery.pending?
  end

  test "should enqueue job when retrying failed delivery" do
    assert_enqueued_with(job: DeliverWebhookJob, args: [@failed_delivery.id]) do
      post retry_delivery_url(@failed_delivery, locale: :en)
    end
  end

  test "should not retry delivery from another organization" do
    other_org_event = events(:other_org_event)
    other_org_connection = connections(:other_org_connection)
    other_org_destination = destinations(:other_org_destination)
    other_org_delivery = Delivery.create!(
      event: other_org_event,
      connection: other_org_connection,
      destination: other_org_destination,
      status: :failed,
      max_attempts: 18
    )

    post retry_delivery_url(other_org_delivery, locale: :en)
    assert_response :not_found
  end

  # Cancel tests
  test "should cancel failed delivery with pending retries" do
    # Create a cancellable delivery
    cancellable_delivery = Delivery.create!(
      event: @event,
      connection: connections(:stripe_to_production),
      destination: @destination,
      status: :failed,
      attempt_count: 2,
      max_attempts: 18,
      next_attempt_at: 1.hour.from_now
    )

    post cancel_delivery_url(cancellable_delivery, locale: :en)
    assert_redirected_to delivery_url(cancellable_delivery, locale: :en)
    assert_equal "Delivery cancelled. No more retries will be attempted.", flash[:notice]

    cancellable_delivery.reload
    assert cancellable_delivery.cancelled?
    assert_nil cancellable_delivery.next_attempt_at
    assert_not_nil cancellable_delivery.completed_at
  end

  test "should not cancel successful delivery" do
    post cancel_delivery_url(@successful_delivery, locale: :en)
    assert_redirected_to delivery_url(@successful_delivery, locale: :en)
    assert_equal "Cannot cancel this delivery.", flash[:alert]

    @successful_delivery.reload
    assert @successful_delivery.success?
  end

  test "should not cancel pending delivery" do
    post cancel_delivery_url(@pending_delivery, locale: :en)
    assert_redirected_to delivery_url(@pending_delivery, locale: :en)
    assert_equal "Cannot cancel this delivery.", flash[:alert]

    @pending_delivery.reload
    assert @pending_delivery.pending?
  end

  test "should not cancel failed delivery at max attempts" do
    post cancel_delivery_url(@failed_delivery, locale: :en)
    assert_redirected_to delivery_url(@failed_delivery, locale: :en)
    assert_equal "Cannot cancel this delivery.", flash[:alert]

    @failed_delivery.reload
    assert @failed_delivery.failed?
  end

  test "should not cancel already cancelled delivery" do
    cancelled_delivery = Delivery.create!(
      event: @event,
      connection: connections(:stripe_to_production),
      destination: @destination,
      status: :cancelled,
      attempt_count: 2,
      max_attempts: 18
    )

    post cancel_delivery_url(cancelled_delivery, locale: :en)
    assert_redirected_to delivery_url(cancelled_delivery, locale: :en)
    assert_equal "Cannot cancel this delivery.", flash[:alert]
  end

  test "should not cancel delivery from another organization" do
    other_org_event = events(:other_org_event)
    other_org_connection = connections(:other_org_connection)
    other_org_destination = destinations(:other_org_destination)
    other_org_delivery = Delivery.create!(
      event: other_org_event,
      connection: other_org_connection,
      destination: other_org_destination,
      status: :failed,
      attempt_count: 2,
      max_attempts: 18,
      next_attempt_at: 1.hour.from_now
    )

    post cancel_delivery_url(other_org_delivery, locale: :en)
    assert_response :not_found
  end
end
