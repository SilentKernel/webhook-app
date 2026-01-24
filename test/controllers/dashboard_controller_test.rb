# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    @organization = organizations(:acme)
  end

  test "redirects to login when not authenticated" do
    get dashboard_path(locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
  end

  test "shows dashboard when authenticated" do
    sign_in @user

    get dashboard_path(locale: :en)
    assert_response :success
  end

  test "displays all quick stats sections" do
    sign_in @user

    get dashboard_path(locale: :en)
    assert_response :success

    assert_select ".stat-title", text: "Active Sources"
    assert_select ".stat-title", text: "Active Endpoints"
    assert_select ".stat-title", text: "Events (24h)"
    assert_select ".stat-title", text: "Success Rate (7d)"
  end

  test "displays correct active sources count" do
    sign_in @user

    get dashboard_path(locale: :en)
    assert_response :success

    # ACME org has 2 active sources (stripe_production, github_webhook) and 1 paused
    active_sources = @organization.sources.active.count
    assert_equal 2, active_sources
    assert_match ">#{active_sources}</", response.body
  end

  test "displays correct active destinations count" do
    sign_in @user

    get dashboard_path(locale: :en)
    assert_response :success

    # ACME org has 2 active destinations (production_api, staging_api) and 1 disabled
    active_destinations = @organization.destinations.status_active.count
    assert_equal 2, active_destinations
    assert_match ">#{active_destinations}</", response.body
  end

  test "quick stats are scoped to current organization" do
    sign_in @user

    get dashboard_path(locale: :en)
    assert_response :success

    # ACME has 2 active sources, other org has 1 active source
    # Total active sources across all orgs is 3, but we should only see 2
    total_active_sources = Source.active.count
    org_active_sources = @organization.sources.active.count

    assert total_active_sources > org_active_sources, "Test setup requires other org to have sources"
    assert_match ">#{org_active_sources}</", response.body
  end

  test "success rate displays dash when no completed deliveries in last 7 days" do
    sign_in @user

    # Update all deliveries to have completed_at older than 7 days
    Delivery.update_all(completed_at: 8.days.ago)

    get dashboard_path(locale: :en)
    assert_response :success

    # Should show "—" for success rate when no recent data
    assert_match "—", response.body
  end

  test "success rate calculates percentage from completed deliveries" do
    sign_in @user

    # Ensure we have recent completed deliveries
    successful_delivery = deliveries(:successful_delivery)
    failed_delivery = deliveries(:failed_delivery)
    successful_delivery.update!(completed_at: 1.day.ago)
    failed_delivery.update!(completed_at: 1.day.ago)

    get dashboard_path(locale: :en)
    assert_response :success

    # Should display a percentage (not dash)
    assert_match(/\d+\.\d+%/, response.body)
  end
end
