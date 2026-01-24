require "application_system_test_case"

class TurnstilePasswordResetTest < ApplicationSystemTestCase
  TURNSTILE_VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  setup do
    @user = users(:owner)
    # Stub Turnstile verification to succeed (dummy keys auto-pass anyway)
    stub_request(:post, TURNSTILE_VERIFY_URL)
      .to_return(status: 200, body: { success: true }.to_json)
  end

  test "password reset form includes turnstile widget container" do
    visit new_user_password_path(locale: :en)

    assert_selector "form[data-controller='turnstile']"
    assert_selector "[data-turnstile-target='container']"
    assert_selector "[data-sitekey]"
  end

  test "can request password reset with turnstile" do
    visit new_user_password_path(locale: :en)

    fill_in "user[email]", with: @user.email

    # Wait for Turnstile widget to load and auto-verify (dummy keys auto-pass)
    sleep 1

    click_button "Send Reset Instructions"

    # Should show success message or redirect
    assert_text(/reset|sent|email/i, wait: 5)
  end
end
