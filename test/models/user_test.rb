# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user with all required attributes" do
    user = User.new(
      email: "test@example.com",
      password: "password123",
      first_name: "Test",
      last_name: "User"
    )
    assert user.valid?
  end

  test "requires email" do
    user = User.new(
      password: "password123",
      first_name: "Test",
      last_name: "User"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires first name" do
    user = User.new(
      email: "test@example.com",
      password: "password123",
      last_name: "User"
    )
    assert_not user.valid?
    assert_includes user.errors[:first_name], "can't be blank"
  end

  test "requires last name" do
    user = User.new(
      email: "test@example.com",
      password: "password123",
      first_name: "Test"
    )
    assert_not user.valid?
    assert_includes user.errors[:last_name], "can't be blank"
  end

  test "requires unique email" do
    existing = users(:owner)
    user = User.new(
      email: existing.email,
      password: "password123",
      first_name: "Test",
      last_name: "User"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "full_name returns first and last name combined" do
    user = users(:owner)
    assert_equal "John Owner", user.full_name
  end

  test "has many memberships" do
    user = users(:owner)
    assert_respond_to user, :memberships
    assert_kind_of Membership, user.memberships.first
  end

  test "has many organizations through memberships" do
    user = users(:owner)
    assert_respond_to user, :organizations
    assert_includes user.organizations, organizations(:acme)
  end

  test "has many sent invitations" do
    user = users(:owner)
    assert_respond_to user, :sent_invitations
    assert_includes user.sent_invitations, invitations(:pending)
  end

  test "destroying user nullifies sent invitations" do
    user = users(:owner)
    invitation = invitations(:pending)
    assert_equal user, invitation.invited_by

    # Need to destroy memberships first due to foreign key constraints
    user.memberships.destroy_all
    user.destroy

    invitation.reload
    assert_nil invitation.invited_by
  end

  # can_receive_failure_email? tests
  test "can_receive_failure_email? returns true for confirmed user with no previous email" do
    user = users(:owner)
    user.last_failure_email_sent_at = nil

    assert user.can_receive_failure_email?
  end

  test "can_receive_failure_email? returns true when last email was sent more than 10 minutes ago" do
    user = users(:owner)
    user.last_failure_email_sent_at = 11.minutes.ago

    assert user.can_receive_failure_email?
  end

  test "can_receive_failure_email? returns false when last email was sent within 10 minutes" do
    user = users(:owner)
    user.last_failure_email_sent_at = 5.minutes.ago

    assert_not user.can_receive_failure_email?
  end

  test "can_receive_failure_email? returns false for unconfirmed user" do
    user = users(:unconfirmed)
    user.last_failure_email_sent_at = nil

    assert_not user.can_receive_failure_email?
  end

  test "can_receive_failure_email? returns true exactly at 10 minute boundary" do
    user = users(:owner)
    user.last_failure_email_sent_at = 10.minutes.ago - 1.second

    assert user.can_receive_failure_email?
  end

  test "has many destination_notification_subscriptions" do
    user = users(:owner)
    assert_respond_to user, :destination_notification_subscriptions
  end

  test "has many subscribed_destinations through subscriptions" do
    user = users(:owner)
    assert_respond_to user, :subscribed_destinations
    assert_includes user.subscribed_destinations, destinations(:production_api)
  end
end
