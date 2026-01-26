# frozen_string_literal: true

require "test_helper"

class ConnectionTest < ActiveSupport::TestCase
  test "valid connection with required attributes" do
    connection = Connection.new(
      source: sources(:github_webhook),
      destination: destinations(:disabled_destination)
    )
    assert connection.valid?
  end

  test "requires source" do
    connection = Connection.new(
      destination: destinations(:production_api)
    )
    assert_not connection.valid?
    assert_includes connection.errors[:source], "must exist"
  end

  test "requires destination" do
    connection = Connection.new(
      source: sources(:stripe_production)
    )
    assert_not connection.valid?
    assert_includes connection.errors[:destination], "must exist"
  end

  test "same source destination and rules combination is invalid" do
    existing = connections(:stripe_to_production)
    connection = Connection.new(
      source: existing.source,
      destination: existing.destination,
      rules: existing.rules
    )
    assert_not connection.valid?
    assert connection.errors[:base].any?
    assert_includes connection.errors[:base], "a connection with the same source, destination, and rules already exists"
  end

  test "same source destination with different rules is valid" do
    existing = connections(:stripe_to_production)
    connection = Connection.new(
      source: existing.source,
      destination: existing.destination,
      rules: [{ "type" => "filter", "config" => { "event_types" => ["checkout.session.completed"] } }]
    )
    assert connection.valid?
  end

  test "same source destination with different delay rules is valid" do
    existing = connections(:stripe_to_production)
    connection = Connection.new(
      source: existing.source,
      destination: existing.destination,
      rules: [{ "type" => "delay", "config" => { "seconds" => 60 } }]
    )
    assert connection.valid?
  end

  test "updating connection with same rules is valid" do
    connection = connections(:stripe_to_production)
    connection.name = "Updated Name"
    assert connection.valid?
  end

  test "same source can connect to different destinations" do
    source = sources(:stripe_production)
    destination = destinations(:disabled_destination)

    connection = Connection.new(
      source: source,
      destination: destination
    )
    assert connection.valid?
  end

  test "same destination can receive from different sources" do
    source = sources(:paused_source)
    destination = destinations(:production_api)

    connection = Connection.new(
      source: source,
      destination: destination
    )
    assert connection.valid?
  end

  test "source and destination must belong to same organization" do
    connection = Connection.new(
      source: sources(:stripe_production),
      destination: destinations(:other_org_destination)
    )
    assert_not connection.valid?
    assert connection.errors[:base].any?
    assert_includes connection.errors[:base], "source and destination must belong to the same organization"
  end

  test "status enum includes active paused and disabled" do
    assert_equal 0, Connection.statuses[:active]
    assert_equal 1, Connection.statuses[:paused]
    assert_equal 2, Connection.statuses[:disabled]
  end

  test "default status is active" do
    connection = Connection.new(
      source: sources(:github_webhook),
      destination: destinations(:disabled_destination)
    )
    connection.save!
    assert connection.active?
  end

  test "paused connection" do
    connection = connections(:paused_connection)
    assert connection.paused?
  end

  test "active scope returns only active connections" do
    active_connections = Connection.active

    assert_includes active_connections, connections(:stripe_to_production)
    assert_includes active_connections, connections(:github_to_staging)
    assert_not_includes active_connections, connections(:paused_connection)
  end

  test "ordered scope returns connections by priority ascending" do
    ordered = Connection.ordered

    priorities = ordered.pluck(:priority)
    assert_equal priorities.sort, priorities
  end

  test "default priority is 0" do
    connection = Connection.new(
      source: sources(:github_webhook),
      destination: destinations(:disabled_destination)
    )
    connection.save!
    assert_equal 0, connection.priority
  end

  test "default rules is empty array" do
    connection = Connection.new(
      source: sources(:github_webhook),
      destination: destinations(:disabled_destination)
    )
    connection.save!
    assert_equal [], connection.rules
  end

  test "belongs_to source" do
    connection = connections(:stripe_to_production)
    assert_equal sources(:stripe_production), connection.source
  end

  test "belongs_to destination" do
    connection = connections(:stripe_to_production)
    assert_equal destinations(:production_api), connection.destination
  end

  test "has_one organization through source" do
    connection = connections(:stripe_to_production)
    assert_equal organizations(:acme), connection.organization
  end

  test "name is optional" do
    connection = Connection.new(
      source: sources(:github_webhook),
      destination: destinations(:disabled_destination),
      name: nil
    )
    assert connection.valid?
  end

  test "can set name" do
    connection = Connection.new(
      source: sources(:github_webhook),
      destination: destinations(:disabled_destination),
      name: "Custom Name"
    )
    connection.save!
    assert_equal "Custom Name", connection.name
  end
end
