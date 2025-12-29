# frozen_string_literal: true

require "test_helper"

class TeamControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @admin = users(:admin)
    @member = users(:member)
    @organization = organizations(:acme)
  end

  test "redirects to login when not authenticated" do
    get team_index_path(locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
  end

  test "shows team list when authenticated" do
    sign_in @owner

    get team_index_path(locale: :en)
    assert_response :success
  end

  test "owner can access new invite page" do
    sign_in @owner

    get invite_team_index_path(locale: :en)
    assert_response :success
  end

  test "admin can access new invite page" do
    sign_in @admin

    get invite_team_index_path(locale: :en)
    assert_response :success
  end

  test "member cannot access new invite page" do
    sign_in @member

    get invite_team_index_path(locale: :en)
    assert_redirected_to dashboard_path(locale: :en)
  end

  test "owner can create invitation" do
    sign_in @owner

    assert_difference "Invitation.count", 1 do
      post invite_team_index_path(locale: :en), params: {
        invitation: {
          email: "newinvite@example.com",
          role: "member"
        }
      }
    end

    assert_redirected_to team_index_path(locale: :en)
  end

  test "admin can create invitation" do
    sign_in @admin

    assert_difference "Invitation.count", 1 do
      post invite_team_index_path(locale: :en), params: {
        invitation: {
          email: "anotherinvite@example.com",
          role: "member"
        }
      }
    end

    assert_redirected_to team_index_path(locale: :en)
  end

  test "member cannot create invitation" do
    sign_in @member

    assert_no_difference "Invitation.count" do
      post invite_team_index_path(locale: :en), params: {
        invitation: {
          email: "blocked@example.com",
          role: "member"
        }
      }
    end

    assert_redirected_to dashboard_path(locale: :en)
  end

  test "owner can remove member" do
    sign_in @owner
    membership = memberships(:member_acme)

    assert_difference "Membership.count", -1 do
      delete team_path(membership, locale: :en)
    end

    assert_redirected_to team_index_path(locale: :en)
  end

  test "owner cannot remove themselves" do
    sign_in @owner
    membership = memberships(:owner_acme)

    assert_no_difference "Membership.count" do
      delete team_path(membership, locale: :en)
    end

    assert_redirected_to team_index_path(locale: :en)
  end

  test "member cannot remove other members" do
    sign_in @member
    membership = memberships(:admin_acme)

    assert_no_difference "Membership.count" do
      delete team_path(membership, locale: :en)
    end

    assert_redirected_to dashboard_path(locale: :en)
  end

  test "owner can update member role" do
    sign_in @owner
    membership = memberships(:member_acme)

    patch role_team_path(membership, locale: :en), params: { role: "admin" }

    assert_redirected_to team_index_path(locale: :en)
    membership.reload
    assert membership.admin?
  end

  test "member cannot update roles" do
    sign_in @member
    membership = memberships(:admin_acme)

    patch role_team_path(membership, locale: :en), params: { role: "member" }

    assert_redirected_to dashboard_path(locale: :en)
    membership.reload
    assert membership.admin?
  end
end
