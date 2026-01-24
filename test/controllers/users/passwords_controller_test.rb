# frozen_string_literal: true

require "test_helper"

class Users::PasswordsControllerTest < ActionDispatch::IntegrationTest
  TURNSTILE_VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  setup do
    @user = users(:owner)
    stub_request(:post, TURNSTILE_VERIFY_URL)
      .to_return(status: 200, body: { success: true }.to_json)
  end

  test "shows password reset form" do
    get new_user_password_path(locale: :en)
    assert_response :success
    assert_select "form"
    assert_select "input[name='user[email]']"
    assert_select "[data-turnstile-target='container']"
  end

  test "sends password reset instructions with valid turnstile" do
    post user_password_path(locale: :en), params: {
      user: { email: @user.email },
      "cf-turnstile-response": "valid_token"
    }

    assert_redirected_to new_user_session_path(locale: :en)
  end

  test "password reset fails with invalid turnstile token" do
    stub_request(:post, TURNSTILE_VERIFY_URL)
      .to_return(status: 200, body: { success: false, "error-codes": ["invalid-input-response"] }.to_json)

    post user_password_path(locale: :en), params: {
      user: { email: @user.email },
      "cf-turnstile-response": "invalid_token"
    }

    assert_response :unprocessable_entity
    assert_select ".alert", /verification failed/i
  end

  test "password reset fails with missing turnstile token" do
    # No stub needed - service returns early for blank token without API call

    post user_password_path(locale: :en), params: {
      user: { email: @user.email }
    }

    assert_response :unprocessable_entity
    assert_select ".alert", /complete the verification challenge/i
  end

  test "form data preserved after turnstile failure" do
    stub_request(:post, TURNSTILE_VERIFY_URL)
      .to_return(status: 200, body: { success: false, "error-codes": ["invalid-input-response"] }.to_json)

    post user_password_path(locale: :en), params: {
      user: { email: "test@example.com" },
      "cf-turnstile-response": "invalid_token"
    }

    assert_response :unprocessable_entity
    assert_select "input[name='user[email]'][value='test@example.com']"
  end
end
