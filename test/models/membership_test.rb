# frozen_string_literal: true

require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "valid membership with user and organization" do
    membership = Membership.new(
      user: users(:unconfirmed),
      organization: organizations(:acme),
      role: :member
    )
    assert membership.valid?
  end

  test "requires user" do
    membership = Membership.new(
      organization: organizations(:acme),
      role: :member
    )
    assert_not membership.valid?
    assert_includes membership.errors[:user], "must exist"
  end

  test "requires organization" do
    membership = Membership.new(
      user: users(:owner),
      role: :member
    )
    assert_not membership.valid?
    assert_includes membership.errors[:organization], "must exist"
  end

  test "user can only have one membership per organization" do
    existing = memberships(:owner_acme)
    membership = Membership.new(
      user: existing.user,
      organization: existing.organization,
      role: :member
    )
    assert_not membership.valid?
    assert membership.errors[:user_id].any?
  end

  test "role enum includes member admin and owner" do
    assert_equal 0, Membership.roles[:member]
    assert_equal 1, Membership.roles[:admin]
    assert_equal 2, Membership.roles[:owner]
  end

  test "default role is member" do
    membership = Membership.new
    assert membership.member?
  end

  test "owner role is correctly assigned" do
    membership = memberships(:owner_acme)
    assert membership.owner?
    assert_not membership.admin?
    assert_not membership.member?
  end

  test "admin role is correctly assigned" do
    membership = memberships(:admin_acme)
    assert membership.admin?
    assert_not membership.owner?
    assert_not membership.member?
  end

  test "member role is correctly assigned" do
    membership = memberships(:member_acme)
    assert membership.member?
    assert_not membership.owner?
    assert_not membership.admin?
  end

  test "only one owner per organization" do
    membership = Membership.new(
      user: users(:unconfirmed),
      organization: organizations(:acme),
      role: :owner
    )
    assert_not membership.valid?
    assert membership.errors[:role].any?
  end

  test "can have owner in different organization" do
    membership = Membership.new(
      user: users(:admin),
      organization: organizations(:other),
      role: :owner
    )
    assert membership.valid?
  end
end
