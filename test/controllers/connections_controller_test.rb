# frozen_string_literal: true

require "test_helper"

class ConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    @organization = organizations(:acme)
    @connection = connections(:stripe_to_production)
    @other_org_connection = connections(:other_org_connection)
    @source = sources(:stripe_production)
    @destination = destinations(:production_api)
    @other_org_source = sources(:other_org_source)
    @other_org_destination = destinations(:other_org_destination)
    sign_in @user
  end

  # Index tests
  test "should get index" do
    get connections_url(locale: :en)
    assert_response :success
  end

  test "redirects to login when not authenticated" do
    sign_out @user
    get connections_url(locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
  end

  # Show tests
  test "should show connection" do
    get connection_url(@connection, locale: :en)
    assert_response :success
  end

  test "should not show connection from another organization" do
    get connection_url(@other_org_connection, locale: :en)
    assert_response :not_found
  end

  # New tests
  test "should get new" do
    get new_connection_url(locale: :en)
    assert_response :success
  end

  # Create tests
  test "should create connection with valid params" do
    # Use github_webhook source which doesn't have a connection to disabled_destination
    source = sources(:github_webhook)
    destination = destinations(:disabled_destination)

    assert_difference("Connection.count") do
      post connections_url(locale: :en), params: {
        connection: {
          source_id: source.id,
          destination_id: destination.id,
          name: "New Connection",
          status: "active",
          priority: 10
        }
      }
    end

    connection = Connection.last
    assert_redirected_to connection_url(connection, locale: :en)
  end

  test "should not create connection when source belongs to different org" do
    assert_no_difference("Connection.count") do
      post connections_url(locale: :en), params: {
        connection: {
          source_id: @other_org_source.id,
          destination_id: @destination.id,
          name: "Invalid Connection"
        }
      }
    end

    assert_redirected_to connections_url(locale: :en)
    assert_equal "Invalid source.", flash[:alert]
  end

  test "should not create connection when destination belongs to different org" do
    assert_no_difference("Connection.count") do
      post connections_url(locale: :en), params: {
        connection: {
          source_id: @source.id,
          destination_id: @other_org_destination.id,
          name: "Invalid Connection"
        }
      }
    end

    assert_redirected_to connections_url(locale: :en)
    assert_equal "Invalid destination.", flash[:alert]
  end

  test "should not create duplicate connection" do
    # Try to create a connection that already exists (stripe_to_production)
    assert_no_difference("Connection.count") do
      post connections_url(locale: :en), params: {
        connection: {
          source_id: @source.id,
          destination_id: @destination.id,
          name: "Duplicate Connection"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # Edit tests
  test "should get edit" do
    get edit_connection_url(@connection, locale: :en)
    assert_response :success
  end

  test "should not get edit for connection from another organization" do
    get edit_connection_url(@other_org_connection, locale: :en)
    assert_response :not_found
  end

  # Update tests
  test "should update connection" do
    patch connection_url(@connection, locale: :en), params: {
      connection: {
        name: "Updated Connection Name",
        priority: 99
      }
    }

    assert_redirected_to connection_url(@connection, locale: :en)
    @connection.reload
    assert_equal "Updated Connection Name", @connection.name
    assert_equal 99, @connection.priority
  end

  test "should not update connection to use source from another organization" do
    patch connection_url(@connection, locale: :en), params: {
      connection: {
        source_id: @other_org_source.id
      }
    }

    assert_redirected_to connections_url(locale: :en)
    assert_equal "Invalid source.", flash[:alert]
  end

  test "should not update connection to use destination from another organization" do
    patch connection_url(@connection, locale: :en), params: {
      connection: {
        destination_id: @other_org_destination.id
      }
    }

    assert_redirected_to connections_url(locale: :en)
    assert_equal "Invalid destination.", flash[:alert]
  end

  test "should not update connection from another organization" do
    patch connection_url(@other_org_connection, locale: :en), params: {
      connection: {
        name: "Hacked Name"
      }
    }

    assert_response :not_found
  end

  # Destroy tests
  test "should destroy connection" do
    assert_difference("Connection.count", -1) do
      delete connection_url(@connection, locale: :en)
    end

    assert_redirected_to connections_url(locale: :en)
  end

  test "should not destroy connection from another organization" do
    assert_no_difference("Connection.count") do
      delete connection_url(@other_org_connection, locale: :en)
    end

    assert_response :not_found
  end
end
