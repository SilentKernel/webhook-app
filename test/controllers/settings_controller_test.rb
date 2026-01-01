# frozen_string_literal: true

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @admin = users(:admin)
    @member = users(:member)
    @organization = organizations(:acme)
  end

  test "redirects to login when not authenticated" do
    get settings_path(locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
  end

  test "owner can access settings" do
    sign_in @owner

    get settings_path(locale: :en)
    assert_response :success
  end

  test "admin cannot access settings" do
    sign_in @admin

    get settings_path(locale: :en)
    assert_redirected_to dashboard_path(locale: :en)
  end

  test "member cannot access settings" do
    sign_in @member

    get settings_path(locale: :en)
    assert_redirected_to dashboard_path(locale: :en)
  end

  test "owner can update organization name" do
    sign_in @owner

    patch settings_path(locale: :en), params: {
      organization: { name: "New Company Name" }
    }

    assert_redirected_to settings_path(locale: :en)

    @organization.reload
    assert_equal "New Company Name", @organization.name
  end

  test "admin cannot update organization" do
    sign_in @admin
    original_name = @organization.name

    patch settings_path(locale: :en), params: {
      organization: { name: "Hacked Name" }
    }

    assert_redirected_to dashboard_path(locale: :en)

    @organization.reload
    assert_equal original_name, @organization.name
  end

  test "update fails with blank name" do
    sign_in @owner

    patch settings_path(locale: :en), params: {
      organization: { name: "" }
    }

    assert_response :unprocessable_entity
    @organization.reload
    assert_equal "Acme Corp", @organization.name
  end

  test "owner can update organization timezone" do
    sign_in @owner

    patch settings_path(locale: :en), params: {
      organization: { timezone: "Pacific Time (US & Canada)" }
    }

    assert_redirected_to settings_path(locale: :en)

    @organization.reload
    assert_equal "Pacific Time (US & Canada)", @organization.timezone
  end

  test "update fails with invalid timezone" do
    sign_in @owner
    original_timezone = @organization.timezone

    patch settings_path(locale: :en), params: {
      organization: { timezone: "Invalid/Timezone" }
    }

    assert_response :unprocessable_entity
    @organization.reload
    assert_equal original_timezone, @organization.timezone
  end
end
