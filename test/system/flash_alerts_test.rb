require "application_system_test_case"

class FlashAlertsTest < ApplicationSystemTestCase
  setup do
    @user = users(:owner)
    sign_in @user
  end

  test "flash alert can be dismissed with close button" do
    # Navigate to trigger a flash message (e.g., update settings)
    visit settings_path(locale: :en)

    # Update settings to trigger a success flash
    fill_in "Organization Name", with: "Updated Org Name"
    click_button "Save Changes"

    # Verify flash alert is visible
    assert_selector "[data-controller='notification']", text: /updated|saved/i

    # Click the close button
    find("[data-controller='notification'] button[data-action='notification#hide']").click

    # Verify flash alert is gone
    assert_no_selector "[data-controller='notification']"
  end

  test "flash alert has auto-dismiss configured" do
    visit settings_path(locale: :en)

    fill_in "Organization Name", with: "Test Org"
    click_button "Save Changes"

    # Verify the notification controller is attached with 10 second delay
    notification = find("[data-controller='notification']")
    assert_equal "10000", notification["data-notification-delay-value"]
  end

  test "flash alert has proper accessibility attributes" do
    visit settings_path(locale: :en)

    fill_in "Organization Name", with: "Accessible Org"
    click_button "Save Changes"

    # Verify close button has aria-label
    close_button = find("[data-controller='notification'] button[data-action='notification#hide']")
    assert_equal "Dismiss", close_button["aria-label"]
  end

  private

  def sign_in(user)
    visit new_user_session_path(locale: :en)
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Login"
  end
end
