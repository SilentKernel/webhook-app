# frozen_string_literal: true

require "test_helper"

class DestinationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    @organization = organizations(:acme)
    @destination = destinations(:production_api)
    @other_org_destination = destinations(:other_org_destination)
    sign_in @user
  end

  # Index tests
  test "should get index" do
    get destinations_url(locale: :en)
    assert_response :success
  end

  test "redirects to login when not authenticated" do
    sign_out @user
    get destinations_url(locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
  end

  # Show tests
  test "should show destination" do
    get destination_url(@destination, locale: :en)
    assert_response :success
  end

  test "should not show destination from another organization" do
    get destination_url(@other_org_destination, locale: :en)
    assert_response :not_found
  end

  # New tests
  test "should get new" do
    get new_destination_url(locale: :en)
    assert_response :success
  end

  # Create tests
  test "should create destination with valid params" do
    assert_difference("Destination.count") do
      post destinations_url(locale: :en), params: {
        destination: {
          name: "New Destination",
          url: "https://example.com/webhooks",
          http_method: "POST",
          auth_type: "none",
          status: "active"
        }
      }
    end

    destination = Destination.last
    assert_redirected_to destination_url(destination, locale: :en)
    assert_equal @organization.id, destination.organization_id
  end

  test "should not create destination with invalid URL" do
    assert_no_difference("Destination.count") do
      post destinations_url(locale: :en), params: {
        destination: {
          name: "Invalid Destination",
          url: "not-a-valid-url",
          http_method: "POST"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should create destination with headers as JSON" do
    assert_difference("Destination.count") do
      post destinations_url(locale: :en), params: {
        destination: {
          name: "Destination with Headers",
          url: "https://example.com/webhooks",
          http_method: "POST",
          auth_type: "none",
          status: "active",
          headers: '{"Content-Type": "application/json"}'
        }
      }
    end

    destination = Destination.last
    assert_equal({ "Content-Type" => "application/json" }, destination.headers)
  end

  # Edit tests
  test "should get edit" do
    get edit_destination_url(@destination, locale: :en)
    assert_response :success
  end

  test "should not get edit for destination from another organization" do
    get edit_destination_url(@other_org_destination, locale: :en)
    assert_response :not_found
  end

  # Update tests
  test "should update destination" do
    patch destination_url(@destination, locale: :en), params: {
      destination: {
        name: "Updated Destination Name"
      }
    }

    assert_redirected_to destination_url(@destination, locale: :en)
    @destination.reload
    assert_equal "Updated Destination Name", @destination.name
  end

  test "should not update destination with invalid params" do
    patch destination_url(@destination, locale: :en), params: {
      destination: {
        url: "invalid-url"
      }
    }

    assert_response :unprocessable_entity
  end

  test "should not update destination from another organization" do
    patch destination_url(@other_org_destination, locale: :en), params: {
      destination: {
        name: "Hacked Name"
      }
    }

    assert_response :not_found
  end

  # Destroy tests
  test "should destroy destination" do
    # Use a destination without connections to avoid foreign key issues
    destination = destinations(:disabled_destination)

    assert_difference("Destination.count", -1) do
      delete destination_url(destination, locale: :en)
    end

    assert_redirected_to destinations_url(locale: :en)
  end

  test "should not destroy destination from another organization" do
    assert_no_difference("Destination.count") do
      delete destination_url(@other_org_destination, locale: :en)
    end

    assert_response :not_found
  end

  # Notification subscribers tests
  test "should create destination with notification subscribers" do
    assert_difference("Destination.count") do
      assert_difference("DestinationNotificationSubscription.count", 2) do
        post destinations_url(locale: :en), params: {
          destination: {
            name: "Destination with Subscribers",
            url: "https://example.com/webhooks",
            http_method: "POST",
            auth_type: "none",
            status: "active",
            notification_subscriber_ids: [users(:owner).id, users(:admin).id]
          }
        }
      end
    end

    destination = Destination.last
    assert_equal 2, destination.notification_subscribers.count
    assert_includes destination.notification_subscribers, users(:owner)
    assert_includes destination.notification_subscribers, users(:admin)
  end

  test "should update destination notification subscribers" do
    # Add a subscriber first
    @destination.notification_subscribers << users(:member)

    patch destination_url(@destination, locale: :en), params: {
      destination: {
        notification_subscriber_ids: [users(:owner).id]
      }
    }

    @destination.reload
    assert_equal 1, @destination.notification_subscribers.count
    assert_includes @destination.notification_subscribers, users(:owner)
    assert_not_includes @destination.notification_subscribers, users(:member)
  end

  test "should load org members in new action" do
    get new_destination_url(locale: :en)
    assert_response :success
    # Verify the form has the failure notifications section
    assert_select "div.divider", text: "Failure Notifications"
  end

  test "should load org members in edit action" do
    get edit_destination_url(@destination, locale: :en)
    assert_response :success
    # Verify the form has the failure notifications section
    assert_select "div.divider", text: "Failure Notifications"
  end
end
