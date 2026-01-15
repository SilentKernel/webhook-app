# frozen_string_literal: true

require "test_helper"

class SourceTypeTest < ActiveSupport::TestCase
  test "valid source type with required attributes" do
    source_type = SourceType.new(
      name: "Custom",
      slug: "custom",
      verification_type: verification_types(:none)
    )
    assert source_type.valid?
  end

  test "requires name" do
    source_type = SourceType.new(
      slug: "custom",
      verification_type: verification_types(:none)
    )
    assert_not source_type.valid?
    assert_includes source_type.errors[:name], "can't be blank"
  end

  test "requires slug" do
    source_type = SourceType.new(
      name: "Custom",
      verification_type: verification_types(:none)
    )
    assert_not source_type.valid?
    assert_includes source_type.errors[:slug], "can't be blank"
  end

  test "requires verification_type" do
    source_type = SourceType.new(
      name: "Custom",
      slug: "custom"
    )
    assert_not source_type.valid?
    assert_includes source_type.errors[:verification_type], "must exist"
  end

  test "slug must be unique" do
    existing = source_types(:stripe)
    source_type = SourceType.new(
      name: "Another Stripe",
      slug: existing.slug,
      verification_type: verification_types(:stripe)
    )
    assert_not source_type.valid?
    assert_includes source_type.errors[:slug], "has already been taken"
  end

  test "active scope returns only active source types" do
    active_types = SourceType.active

    assert_includes active_types, source_types(:stripe)
    assert_includes active_types, source_types(:github)
    assert_not_includes active_types, source_types(:inactive)
  end

  test "has_many sources association" do
    source_type = source_types(:stripe)
    assert_respond_to source_type, :sources
  end

  test "belongs_to verification_type" do
    source_type = source_types(:stripe)
    assert_equal verification_types(:stripe), source_type.verification_type
  end

  test "verification_type_slug returns the slug" do
    source_type = source_types(:stripe)
    assert_equal "stripe", source_type.verification_type_slug
  end

  test "defaults active to true" do
    source_type = SourceType.new(
      name: "New Type",
      slug: "new_type",
      verification_type: verification_types(:none)
    )
    source_type.save!
    assert source_type.active?
  end

  test "defaults default_config to empty hash" do
    source_type = SourceType.new(
      name: "New Type",
      slug: "new_type",
      verification_type: verification_types(:none)
    )
    source_type.save!
    assert_equal({}, source_type.default_config)
  end
end
