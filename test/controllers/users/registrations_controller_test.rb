# frozen_string_literal: true

require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  TURNSTILE_VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  setup do
    stub_request(:post, TURNSTILE_VERIFY_URL)
      .to_return(status: 200, body: { success: true }.to_json)
  end

  test "shows registration form" do
    get new_user_registration_path(locale: :en)
    assert_response :success
    assert_select "form"
    assert_select "input[name='user[first_name]']"
    assert_select "input[name='user[last_name]']"
    assert_select "input[name='user[organization_name]']"
  end

  test "creates user with organization" do
    assert_difference ["User.count", "Organization.count", "Membership.count"], 1 do
      post user_registration_path(locale: :en), params: {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123",
          first_name: "New",
          last_name: "User",
          organization_name: "New Org"
        },
        "cf-turnstile-response": "valid_token"
      }
    end

    user = User.find_by(email: "newuser@example.com")
    assert_not_nil user
    assert_equal "New", user.first_name
    assert_equal "User", user.last_name

    org = Organization.find_by(name: "New Org")
    assert_not_nil org

    membership = Membership.find_by(user: user, organization: org)
    assert_not_nil membership
    assert membership.owner?
  end

  test "registration fails with missing organization name" do
    assert_no_difference ["User.count", "Organization.count", "Membership.count"] do
      post user_registration_path(locale: :en), params: {
        user: {
          email: "failuser@example.com",
          password: "password123",
          password_confirmation: "password123",
          first_name: "Fail",
          last_name: "User",
          organization_name: ""
        },
        "cf-turnstile-response": "valid_token"
      }
    end

    assert_response :unprocessable_entity
  end

  test "registration fails with missing first name" do
    assert_no_difference ["User.count", "Organization.count"] do
      post user_registration_path(locale: :en), params: {
        user: {
          email: "failuser@example.com",
          password: "password123",
          password_confirmation: "password123",
          first_name: "",
          last_name: "User",
          organization_name: "Some Org"
        },
        "cf-turnstile-response": "valid_token"
      }
    end

    assert_response :unprocessable_entity
  end

  test "registration fails with duplicate email" do
    existing = users(:owner)

    assert_no_difference ["User.count", "Organization.count"] do
      post user_registration_path(locale: :en), params: {
        user: {
          email: existing.email,
          password: "password123",
          password_confirmation: "password123",
          first_name: "Duplicate",
          last_name: "User",
          organization_name: "Duplicate Org"
        },
        "cf-turnstile-response": "valid_token"
      }
    end

    assert_response :unprocessable_entity
  end

  test "registration fails with invalid turnstile token" do
    stub_request(:post, TURNSTILE_VERIFY_URL)
      .to_return(status: 200, body: { success: false, "error-codes": ["invalid-input-response"] }.to_json)

    assert_no_difference ["User.count", "Organization.count"] do
      post user_registration_path(locale: :en), params: {
        user: {
          email: "turnstile-fail@example.com",
          password: "password123",
          password_confirmation: "password123",
          first_name: "Turnstile",
          last_name: "Fail",
          organization_name: "Test Org"
        },
        "cf-turnstile-response": "invalid_token"
      }
    end

    assert_response :unprocessable_entity
    assert_select ".alert", /verification failed/i
  end

  test "registration fails with missing turnstile token" do
    # No stub needed - service returns early for blank token without API call

    assert_no_difference ["User.count", "Organization.count"] do
      post user_registration_path(locale: :en), params: {
        user: {
          email: "turnstile-missing@example.com",
          password: "password123",
          password_confirmation: "password123",
          first_name: "No",
          last_name: "Token",
          organization_name: "Test Org"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".alert", /complete the verification challenge/i
  end

  test "form data preserved after turnstile failure" do
    stub_request(:post, TURNSTILE_VERIFY_URL)
      .to_return(status: 200, body: { success: false, "error-codes": ["invalid-input-response"] }.to_json)

    post user_registration_path(locale: :en), params: {
      user: {
        email: "preserved@example.com",
        password: "password123",
        password_confirmation: "password123",
        first_name: "Preserved",
        last_name: "Data",
        organization_name: "My Company"
      },
      "cf-turnstile-response": "invalid_token"
    }

    assert_response :unprocessable_entity
    assert_select "input[name='user[email]'][value='preserved@example.com']"
    assert_select "input[name='user[first_name]'][value='Preserved']"
    assert_select "input[name='user[last_name]'][value='Data']"
  end
end
