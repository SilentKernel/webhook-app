# frozen_string_literal: true

require "test_helper"

class PaginationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    @organization = organizations(:acme)
    sign_in @user
  end

  # Sources pagination tests
  test "sources index renders successfully" do
    get sources_url(locale: :en)
    assert_response :success
  end

  test "sources index paginates when records exceed limit" do
    # Create enough sources to trigger pagination (default limit is 25)
    30.times do |i|
      Source.create!(
        organization: @organization,
        name: "Pagination Test Source #{i}",
        verification_type: verification_types(:none),
        ingest_token: SecureRandom.alphanumeric(24)
      )
    end

    get sources_url(locale: :en)
    assert_response :success
    assert_select ".join", count: 2 # DaisyUI pagination component appears above and below
    assert_select ".join-item.btn" # Page buttons
  end

  test "sources index page 2 returns success" do
    30.times do |i|
      Source.create!(
        organization: @organization,
        name: "Pagination Test Source #{i}",
        verification_type: verification_types(:none),
        ingest_token: SecureRandom.alphanumeric(24)
      )
    end

    get sources_url(locale: :en, page: 2)
    assert_response :success
    # Verify we're on page 2 by checking for the active button
    assert_select ".join-item.btn-active", text: "2"
  end

  test "sources index does not show pagination when records below limit" do
    get sources_url(locale: :en)
    assert_response :success
    assert_select ".join", count: 0
  end

  # Destinations pagination tests
  test "destinations index renders successfully" do
    get destinations_url(locale: :en)
    assert_response :success
  end

  test "destinations index paginates when records exceed limit" do
    30.times do |i|
      Destination.create!(
        organization: @organization,
        name: "Pagination Test Destination #{i}",
        url: "https://example.com/webhook#{i}",
        http_method: "POST"
      )
    end

    get destinations_url(locale: :en)
    assert_response :success
    assert_select ".join", count: 2 # Pagination appears above and below
    assert_select ".join-item.btn"
  end

  # Connections pagination tests
  test "connections index renders successfully" do
    get connections_url(locale: :en)
    assert_response :success
  end

  test "connections index paginates when records exceed limit" do
    # Create multiple destinations to avoid uniqueness constraint
    30.times do |i|
      destination = Destination.create!(
        organization: @organization,
        name: "Pagination Dest #{i}",
        url: "https://example#{i}.com/webhook",
        http_method: "POST"
      )
      Connection.create!(
        source: sources(:stripe_production),
        destination: destination,
        name: "Pagination Test Connection #{i}",
        status: :active,
        priority: 0
      )
    end

    get connections_url(locale: :en)
    assert_response :success
    assert_select ".join", count: 2 # Pagination appears above and below
    assert_select ".join-item.btn"
  end

  # Events pagination tests
  test "events index renders successfully" do
    get events_url(locale: :en)
    assert_response :success
  end

  test "events index paginates when records exceed limit" do
    source = sources(:stripe_production)

    30.times do |i|
      Event.create!(
        source: source,
        uid: "test_pagination_event_#{i}_#{SecureRandom.hex(4)}",
        event_type: "test.event",
        payload: { test: i },
        headers: { "content-type" => "application/json" },
        query_params: {},
        received_at: Time.current
      )
    end

    get events_url(locale: :en)
    assert_response :success
    assert_select ".join", count: 2 # Pagination appears above and below
    assert_select ".join-item.btn"
  end

  test "events index preserves filters with pagination" do
    source = sources(:stripe_production)

    30.times do |i|
      Event.create!(
        source: source,
        uid: "filter_pagination_event_#{i}_#{SecureRandom.hex(4)}",
        event_type: "payment.completed",
        payload: { test: i },
        headers: {},
        query_params: {},
        received_at: Time.current
      )
    end

    get events_url(locale: :en, source_id: source.id, event_type: "payment.completed", page: 2)
    assert_response :success

    # Verify filter params are preserved in pagination links
    assert_select "a[href*='source_id=#{source.id}']"
    assert_select "a[href*='event_type=payment.completed']"
  end

  # Deliveries pagination tests
  test "deliveries index renders successfully" do
    get deliveries_url(locale: :en)
    assert_response :success
  end

  test "deliveries index paginates when records exceed limit" do
    event = events(:stripe_payment_event)
    connection = connections(:stripe_to_production)
    destination = destinations(:production_api)

    30.times do
      Delivery.create!(
        event: event,
        connection: connection,
        destination: destination,
        status: :pending,
        max_attempts: 5
      )
    end

    get deliveries_url(locale: :en)
    assert_response :success
    assert_select ".join", count: 2 # Pagination appears above and below
    assert_select ".join-item.btn"
  end

  test "deliveries index preserves filters with pagination" do
    event = events(:stripe_payment_event)
    connection = connections(:stripe_to_production)
    destination = destinations(:production_api)

    30.times do
      Delivery.create!(
        event: event,
        connection: connection,
        destination: destination,
        status: :success,
        max_attempts: 5
      )
    end

    get deliveries_url(locale: :en, status: "success", destination_id: destination.id, page: 2)
    assert_response :success

    # Verify filter params are preserved in pagination links
    assert_select "a[href*='status=success']"
    assert_select "a[href*='destination_id=#{destination.id}']"
  end
end
