# frozen_string_literal: true

require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
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
        }
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
        }
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
        }
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
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
