# frozen_string_literal: true

require "test_helper"

class VerificationTypeTest < ActiveSupport::TestCase
  test "valid verification type with required attributes" do
    verification_type = VerificationType.new(
      name: "Custom",
      slug: "custom_vtype"
    )
    assert verification_type.valid?
  end

  test "requires name" do
    verification_type = VerificationType.new(
      slug: "custom_vtype"
    )
    assert_not verification_type.valid?
    assert_includes verification_type.errors[:name], "can't be blank"
  end

  test "requires slug" do
    verification_type = VerificationType.new(
      name: "Custom"
    )
    assert_not verification_type.valid?
    assert_includes verification_type.errors[:slug], "can't be blank"
  end

  test "slug must be unique" do
    existing = verification_types(:stripe)
    verification_type = VerificationType.new(
      name: "Another Stripe",
      slug: existing.slug
    )
    assert_not verification_type.valid?
    assert_includes verification_type.errors[:slug], "has already been taken"
  end

  test "active scope returns only active verification types ordered by position" do
    active_types = VerificationType.active

    assert_includes active_types, verification_types(:stripe)
    assert_includes active_types, verification_types(:github)
    assert_not_includes active_types, verification_types(:inactive_vtype)

    # Check ordering by position
    positions = active_types.pluck(:position)
    assert_equal positions.sort, positions
  end

  test "has_many sources association" do
    verification_type = verification_types(:stripe)
    assert_respond_to verification_type, :sources
  end

  test "has_many source_types association" do
    verification_type = verification_types(:stripe)
    assert_respond_to verification_type, :source_types
  end

  test "defaults active to true" do
    verification_type = VerificationType.new(
      name: "New Type",
      slug: "new_vtype"
    )
    verification_type.save!
    assert verification_type.active?
  end

  test "defaults position to 0" do
    verification_type = VerificationType.new(
      name: "New Type",
      slug: "new_vtype"
    )
    verification_type.save!
    assert_equal 0, verification_type.position
  end

  test "find_by_slug! returns verification type" do
    verification_type = VerificationType.find_by_slug!("stripe")
    assert_equal verification_types(:stripe), verification_type
  end

  test "find_by_slug! raises for unknown slug" do
    assert_raises ActiveRecord::RecordNotFound do
      VerificationType.find_by_slug!("unknown")
    end
  end

  test "cannot delete verification type with sources" do
    verification_type = verification_types(:stripe)
    assert verification_type.sources.count > 0

    assert_raises ActiveRecord::RecordNotDestroyed do
      verification_type.destroy!
    end
  end

  test "cannot delete verification type with source_types" do
    verification_type = verification_types(:stripe)
    assert verification_type.source_types.count > 0

    assert_raises ActiveRecord::RecordNotDestroyed do
      verification_type.destroy!
    end
  end
end
