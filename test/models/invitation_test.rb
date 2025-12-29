# frozen_string_literal: true

require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "valid invitation with required attributes" do
    invitation = Invitation.new(
      organization: organizations(:acme),
      email: "newuser@example.com",
      invited_by: users(:owner)
    )
    assert invitation.valid?
  end

  test "requires organization" do
    invitation = Invitation.new(
      email: "newuser@example.com"
    )
    assert_not invitation.valid?
    assert_includes invitation.errors[:organization], "must exist"
  end

  test "requires email" do
    invitation = Invitation.new(
      organization: organizations(:acme)
    )
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "can't be blank"
  end

  test "requires valid email format" do
    invitation = Invitation.new(
      organization: organizations(:acme),
      email: "invalid-email"
    )
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "is invalid"
  end

  test "email must be unique per organization" do
    existing = invitations(:pending)
    invitation = Invitation.new(
      organization: existing.organization,
      email: existing.email
    )
    assert_not invitation.valid?
    assert invitation.errors[:email].any?
  end

  test "same email can be invited to different organizations" do
    invitation = Invitation.new(
      organization: organizations(:other),
      email: invitations(:pending).email
    )
    assert invitation.valid?
  end

  test "automatically generates token" do
    invitation = Invitation.create!(
      organization: organizations(:acme),
      email: "tokentest@example.com",
      invited_by: users(:owner)
    )
    assert_not_nil invitation.token
    assert invitation.token.length > 20
  end

  test "automatically sets expires_at to 7 days from now" do
    invitation = Invitation.create!(
      organization: organizations(:acme),
      email: "expirytest@example.com",
      invited_by: users(:owner)
    )
    assert_not_nil invitation.expires_at
    assert_in_delta 7.days.from_now, invitation.expires_at, 1.minute
  end

  test "role enum includes member and admin" do
    assert_equal 0, Invitation.roles[:member]
    assert_equal 1, Invitation.roles[:admin]
  end

  test "default role is member" do
    invitation = Invitation.new
    assert invitation.member?
  end

  test "pending? returns true for non-accepted non-expired invitation" do
    invitation = invitations(:pending)
    assert invitation.pending?
  end

  test "pending? returns false for accepted invitation" do
    invitation = invitations(:accepted)
    assert_not invitation.pending?
  end

  test "pending? returns false for expired invitation" do
    invitation = invitations(:expired)
    assert_not invitation.pending?
  end

  test "expired? returns true when expires_at is in the past" do
    invitation = invitations(:expired)
    assert invitation.expired?
  end

  test "expired? returns false when expires_at is in the future" do
    invitation = invitations(:pending)
    assert_not invitation.expired?
  end

  test "accepted? returns true when accepted_at is set" do
    invitation = invitations(:accepted)
    assert invitation.accepted?
  end

  test "accepted? returns false when accepted_at is nil" do
    invitation = invitations(:pending)
    assert_not invitation.accepted?
  end

  test "accept! sets accepted_at and creates membership" do
    invitation = invitations(:pending)
    user = User.create!(
      email: invitation.email,
      password: "password123",
      first_name: "New",
      last_name: "User",
      confirmed_at: Time.current
    )

    assert_difference "Membership.count", 1 do
      invitation.accept!(user)
    end

    invitation.reload
    assert invitation.accepted?
    assert_includes user.organizations, invitation.organization
  end

  test "pending scope returns only pending invitations" do
    pending_invitations = Invitation.pending
    assert_includes pending_invitations, invitations(:pending)
    assert_not_includes pending_invitations, invitations(:accepted)
    assert_not_includes pending_invitations, invitations(:expired)
  end

  test "invited_by is optional" do
    invitation = Invitation.new(
      organization: organizations(:acme),
      email: "noinviter@example.com"
    )
    assert invitation.valid?
  end

  test "belongs to organization" do
    invitation = invitations(:pending)
    assert_equal organizations(:acme), invitation.organization
  end

  test "belongs to invited_by user" do
    invitation = invitations(:pending)
    assert_equal users(:owner), invitation.invited_by
  end
end
