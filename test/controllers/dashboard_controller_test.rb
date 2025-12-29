# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
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
end
