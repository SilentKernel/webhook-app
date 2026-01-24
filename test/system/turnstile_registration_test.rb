require "application_system_test_case"

class TurnstileRegistrationTest < ApplicationSystemTestCase
  TURNSTILE_VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  setup do
    # Stub Turnstile verification to succeed (dummy keys auto-pass anyway)
    stub_request(:post, TURNSTILE_VERIFY_URL)
      .to_return(status: 200, body: { success: true }.to_json)
  end

  test "registration form includes turnstile widget container" do
    visit new_user_registration_path(locale: :en)

    assert_selector "form[data-controller='turnstile']"
    assert_selector "[data-turnstile-target='container']"
    assert_selector "[data-sitekey]"
  end

  test "can complete registration with turnstile" do
    visit new_user_registration_path(locale: :en)

    fill_in "user[organization_name]", with: "Test Company"
    fill_in "user[first_name]", with: "John"
    fill_in "user[last_name]", with: "Doe"
    fill_in "user[email]", with: "john.doe.#{Time.now.to_i}@example.com"
    fill_in "user[password]", with: "password123"
    fill_in "user[password_confirmation]", with: "password123"

    # Wait for Turnstile widget to load and auto-verify (dummy keys auto-pass)
    sleep 1

    click_button "Create Account"

    # Should redirect to dashboard on success
    assert_current_path dashboard_path(locale: :en), wait: 5
  end
end
