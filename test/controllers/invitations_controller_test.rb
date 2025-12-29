# frozen_string_literal: true

require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  test "shows pending invitation page" do
    invitation = invitations(:pending)

    get invitation_path(invitation.token, locale: :en)
    assert_response :success
  end

  test "redirects to login for expired invitation" do
    invitation = invitations(:expired)

    get invitation_path(invitation.token, locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
    assert_equal "This invitation has expired.", flash[:alert]
  end

  test "redirects to login for accepted invitation when not logged in" do
    invitation = invitations(:accepted)

    get invitation_path(invitation.token, locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
  end

  test "redirects to login for invalid token" do
    get invitation_path("invalid_token", locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
    assert_equal "Invitation not found.", flash[:alert]
  end

  test "accepting invitation when not logged in redirects to login with notice" do
    invitation = invitations(:pending)

    post accept_invitation_path(invitation.token, locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
    assert_match /log in or sign up/, flash[:notice]
  end

  test "accepting invitation when already a member redirects to dashboard" do
    invitation = invitations(:pending)
    # The owner is already a member of acme org
    sign_in users(:owner)

    post accept_invitation_path(invitation.token, locale: :en)
    assert_redirected_to dashboard_path(locale: :en)
    assert_equal "You are already a member of this organization.", flash[:notice]
  end

  test "successfully accepting invitation creates membership" do
    invitation = invitations(:pending)
    user = User.create!(
      email: invitation.email,
      password: "password123",
      first_name: "New",
      last_name: "Member",
      confirmed_at: Time.current
    )

    sign_in user

    assert_difference "Membership.count", 1 do
      post accept_invitation_path(invitation.token, locale: :en)
    end

    assert_redirected_to dashboard_path(locale: :en)
    assert_match /joined/, flash[:notice]

    invitation.reload
    assert invitation.accepted?
  end

  test "cannot accept expired invitation" do
    invitation = invitations(:expired)
    user = User.create!(
      email: invitation.email,
      password: "password123",
      first_name: "Late",
      last_name: "User",
      confirmed_at: Time.current
    )

    sign_in user

    assert_no_difference "Membership.count" do
      post accept_invitation_path(invitation.token, locale: :en)
    end

    assert_redirected_to new_user_session_path(locale: :en)
    assert_equal "This invitation has expired.", flash[:alert]
  end

  test "cannot accept already accepted invitation" do
    invitation = invitations(:accepted)
    user = User.create!(
      email: invitation.email,
      password: "password123",
      first_name: "Double",
      last_name: "Accepter",
      confirmed_at: Time.current
    )

    sign_in user

    assert_no_difference "Membership.count" do
      post accept_invitation_path(invitation.token, locale: :en)
    end

    # Accepted invitation redirects to dashboard when logged in
    assert_redirected_to dashboard_path(locale: :en)
  end
end
