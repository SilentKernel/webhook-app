# frozen_string_literal: true

require "test_helper"

class SourceTest < ActiveSupport::TestCase
  test "valid source with required attributes" do
    source = Source.new(
      organization: organizations(:acme),
      name: "My Source",
      verification_type: "none"
    )
    assert source.valid?
  end

  test "requires name" do
    source = Source.new(
      organization: organizations(:acme),
      verification_type: "none"
    )
    assert_not source.valid?
    assert_includes source.errors[:name], "can't be blank"
  end

  test "requires verification_type" do
    source = Source.new(
      organization: organizations(:acme),
      name: "My Source"
    )
    assert_not source.valid?
    assert_includes source.errors[:verification_type], "can't be blank"
  end

  test "requires organization" do
    source = Source.new(
      name: "My Source",
      verification_type: "none"
    )
    assert_not source.valid?
    assert_includes source.errors[:organization], "must exist"
  end

  test "verification_type must be valid" do
    source = Source.new(
      organization: organizations(:acme),
      name: "My Source",
      verification_type: "invalid"
    )
    assert_not source.valid?
    assert source.errors[:verification_type].any?
  end

  test "verification_type accepts valid values" do
    %w[stripe shopify github hmac none].each do |vtype|
      source = Source.new(
        organization: organizations(:acme),
        name: "My Source",
        verification_type: vtype
      )
      assert source.valid?, "Expected #{vtype} to be valid"
    end
  end

  test "generates ingest_token on create" do
    source = Source.new(
      organization: organizations(:acme),
      name: "My Source",
      verification_type: "none"
    )
    assert_nil source.ingest_token
    source.save!
    assert_not_nil source.ingest_token
    assert_equal 32, source.ingest_token.length
  end

  test "does not overwrite existing ingest_token" do
    source = Source.new(
      organization: organizations(:acme),
      name: "My Source",
      verification_type: "none",
      ingest_token: "my_custom_token_12345678901234"
    )
    source.save!
    assert_equal "my_custom_token_12345678901234", source.ingest_token
  end

  test "ingest_token must be unique" do
    existing = sources(:stripe_production)
    source = Source.new(
      organization: organizations(:acme),
      name: "Another Source",
      verification_type: "none",
      ingest_token: existing.ingest_token
    )
    assert_not source.valid?
    assert_includes source.errors[:ingest_token], "has already been taken"
  end

  test "inherits verification_type from source_type on create" do
    source = Source.new(
      organization: organizations(:acme),
      source_type: source_types(:stripe),
      name: "Stripe Source"
    )
    source.save!
    assert_equal "stripe", source.verification_type
  end

  test "does not override explicitly set verification_type" do
    source = Source.new(
      organization: organizations(:acme),
      source_type: source_types(:stripe),
      name: "Custom Source",
      verification_type: "hmac"
    )
    source.save!
    assert_equal "hmac", source.verification_type
  end

  test "ingest_url returns correct path" do
    source = sources(:stripe_production)
    assert_equal "/ingest/#{source.ingest_token}", source.ingest_url
  end

  test "status enum includes active and paused" do
    assert_equal 0, Source.statuses[:active]
    assert_equal 1, Source.statuses[:paused]
  end

  test "default status is active" do
    source = Source.new(
      organization: organizations(:acme),
      name: "My Source",
      verification_type: "none"
    )
    source.save!
    assert source.active?
  end

  test "paused source" do
    source = sources(:paused_source)
    assert source.paused?
    assert_not source.active?
  end

  test "belongs_to organization" do
    source = sources(:stripe_production)
    assert_equal organizations(:acme), source.organization
  end

  test "belongs_to source_type optionally" do
    source = sources(:stripe_production)
    assert_equal source_types(:stripe), source.source_type
  end

  test "source_type can be nil" do
    source = Source.new(
      organization: organizations(:acme),
      name: "Custom Source",
      verification_type: "none",
      source_type: nil
    )
    assert source.valid?
  end

  test "has_many connections" do
    source = sources(:stripe_production)
    assert_respond_to source, :connections
    assert source.connections.count >= 1
  end

  test "destroying source destroys connections" do
    source = sources(:stripe_production)
    connection_count = source.connections.count
    assert connection_count > 0

    assert_difference "Connection.count", -connection_count do
      source.destroy
    end
  end
end
