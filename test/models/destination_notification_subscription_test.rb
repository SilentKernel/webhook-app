# frozen_string_literal: true

require "test_helper"

class DestinationNotificationSubscriptionTest < ActiveSupport::TestCase
  test "valid subscription with user and destination in same organization" do
    # Use disabled_destination which has no fixture subscriptions
    subscription = DestinationNotificationSubscription.new(
      user: users(:owner),
      destination: destinations(:disabled_destination)
    )
    assert subscription.valid?
  end

  test "requires destination" do
    subscription = DestinationNotificationSubscription.new(
      user: users(:owner)
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:destination], "must exist"
  end

  test "requires user" do
    subscription = DestinationNotificationSubscription.new(
      destination: destinations(:production_api)
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:user], "must exist"
  end

  test "user can only have one subscription per destination" do
    existing = destination_notification_subscriptions(:owner_production_api)
    subscription = DestinationNotificationSubscription.new(
      user: existing.user,
      destination: existing.destination
    )
    assert_not subscription.valid?
    assert subscription.errors[:user_id].any?
  end

  test "user must belong to destination's organization" do
    # owner belongs to acme, other_org_destination belongs to other
    subscription = DestinationNotificationSubscription.new(
      user: users(:owner),
      destination: destinations(:other_org_destination)
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:user], "must belong to the destination's organization"
  end

  test "user can subscribe to multiple destinations" do
    subscription = DestinationNotificationSubscription.new(
      user: users(:owner),
      destination: destinations(:staging_api)
    )
    assert subscription.valid?
  end

  test "multiple users can subscribe to same destination" do
    subscription = DestinationNotificationSubscription.new(
      user: users(:member),
      destination: destinations(:production_api)
    )
    assert subscription.valid?
  end
end
