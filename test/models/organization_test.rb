# frozen_string_literal: true

require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "valid organization with name" do
    org = Organization.new(name: "Test Org")
    assert org.valid?
  end

  test "requires name" do
    org = Organization.new
    assert_not org.valid?
    assert_includes org.errors[:name], "can't be blank"
  end

  test "has many memberships" do
    org = organizations(:acme)
    assert_respond_to org, :memberships
    assert_equal 3, org.memberships.count
  end

  test "has many users through memberships" do
    org = organizations(:acme)
    assert_respond_to org, :users
    assert_includes org.users, users(:owner)
    assert_includes org.users, users(:admin)
    assert_includes org.users, users(:member)
  end

  test "has many invitations" do
    org = organizations(:acme)
    assert_respond_to org, :invitations
    assert_equal 3, org.invitations.count
  end

  test "owner returns the organization owner" do
    org = organizations(:acme)
    assert_equal users(:owner), org.owner
  end

  test "owners returns all owners" do
    org = organizations(:acme)
    assert_includes org.owners, users(:owner)
    assert_equal 1, org.owners.count
  end

  test "admins returns admins and owners" do
    org = organizations(:acme)
    # admins method returns admin + owner roles
    assert_includes org.admins, users(:admin)
    assert_includes org.admins, users(:owner)
  end

  test "destroying organization destroys memberships" do
    org = organizations(:acme)
    membership_count = org.memberships.count

    assert_difference "Membership.count", -membership_count do
      org.destroy
    end
  end

  test "destroying organization destroys invitations" do
    org = organizations(:acme)
    invitation_count = org.invitations.count

    assert_difference "Invitation.count", -invitation_count do
      org.destroy
    end
  end

  test "requires timezone" do
    org = Organization.new(name: "Test Org", timezone: nil)
    assert_not org.valid?
    assert_includes org.errors[:timezone], "can't be blank"
  end

  test "timezone must be valid ActiveSupport timezone" do
    org = Organization.new(name: "Test Org", timezone: "Invalid/Timezone")
    assert_not org.valid?
    assert org.errors[:timezone].any?
  end

  test "accepts valid timezone" do
    org = Organization.new(name: "Test Org", timezone: "Eastern Time (US & Canada)")
    assert org.valid?
  end

  test "accepts UTC timezone" do
    org = Organization.new(name: "Test Org", timezone: "UTC")
    assert org.valid?
  end

  test "default timezone is UTC" do
    # The database default is UTC
    org = organizations(:other)
    assert_equal "UTC", org.timezone
  end

  test "timezone can be changed" do
    org = organizations(:acme)
    org.timezone = "London"
    org.save!
    assert_equal "London", org.reload.timezone
  end
end
