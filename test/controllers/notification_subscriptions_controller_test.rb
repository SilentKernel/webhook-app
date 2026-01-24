# frozen_string_literal: true

require "test_helper"

class NotificationSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    @subscription = destination_notification_subscriptions(:owner_production_api)
    sign_in @user
  end

  test "should destroy subscription" do
    assert_difference("DestinationNotificationSubscription.count", -1) do
      delete notification_subscription_url(@subscription, locale: :en)
    end

    assert_redirected_to edit_user_registration_path(locale: :en)
  end

  test "should destroy subscription via turbo stream" do
    assert_difference("DestinationNotificationSubscription.count", -1) do
      delete notification_subscription_url(@subscription, locale: :en),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_match "turbo-stream", response.body
  end

  test "redirects to login when not authenticated" do
    sign_out @user
    delete notification_subscription_url(@subscription, locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
  end

  test "cannot destroy another user's subscription" do
    other_subscription = destination_notification_subscriptions(:member_staging_api)

    assert_no_difference("DestinationNotificationSubscription.count") do
      delete notification_subscription_url(other_subscription, locale: :en)
    end

    assert_response :not_found
  end

  test "returns 404 for non-existent subscription" do
    assert_no_difference("DestinationNotificationSubscription.count") do
      delete notification_subscription_url(id: -1, locale: :en)
    end

    assert_response :not_found
  end
end
