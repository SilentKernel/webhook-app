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
end
