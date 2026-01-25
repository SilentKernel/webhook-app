# frozen_string_literal: true

require "test_helper"

class DestinationTest < ActiveSupport::TestCase
  test "valid destination with required attributes" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "https://api.example.com/webhooks"
    )
    assert destination.valid?
  end

  test "requires name" do
    destination = Destination.new(
      organization: organizations(:acme),
      url: "https://api.example.com/webhooks"
    )
    assert_not destination.valid?
    assert_includes destination.errors[:name], "can't be blank"
  end

  test "requires url" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API"
    )
    assert_not destination.valid?
    assert_includes destination.errors[:url], "can't be blank"
  end

  test "requires organization" do
    destination = Destination.new(
      name: "My API",
      url: "https://api.example.com/webhooks"
    )
    assert_not destination.valid?
    assert_includes destination.errors[:organization], "must exist"
  end

  test "url must be valid http url" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "https://api.example.com/webhooks"
    )
    assert destination.valid?
  end

  test "url must be valid https url" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "http://api.example.com/webhooks"
    )
    assert destination.valid?
  end

  test "url rejects invalid format" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "not-a-url"
    )
    assert_not destination.valid?
    assert destination.errors[:url].any?
  end

  test "url rejects ftp protocol" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "ftp://example.com/file"
    )
    assert_not destination.valid?
    assert destination.errors[:url].any?
  end

  test "http_method must be valid" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "https://api.example.com/webhooks",
      http_method: "INVALID"
    )
    assert_not destination.valid?
    assert destination.errors[:http_method].any?
  end

  test "http_method accepts valid values" do
    %w[POST PUT PATCH GET DELETE].each do |method|
      destination = Destination.new(
        organization: organizations(:acme),
        name: "My API",
        url: "https://api.example.com/webhooks",
        http_method: method
      )
      assert destination.valid?, "Expected #{method} to be valid"
    end
  end

  test "default http_method is POST" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "https://api.example.com/webhooks"
    )
    destination.save!
    assert_equal "POST", destination.http_method
  end

  test "timeout_seconds must be greater than zero" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "https://api.example.com/webhooks",
      timeout_seconds: 0
    )
    assert_not destination.valid?
    assert destination.errors[:timeout_seconds].any?
  end

  test "timeout_seconds can be nil" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "https://api.example.com/webhooks",
      timeout_seconds: nil
    )
    assert destination.valid?
  end

  test "max_delivery_rate must be greater than zero if present" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "https://api.example.com/webhooks",
      max_delivery_rate: 0
    )
    assert_not destination.valid?
    assert destination.errors[:max_delivery_rate].any?
  end

  test "max_delivery_rate can be nil" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "https://api.example.com/webhooks",
      max_delivery_rate: nil
    )
    assert destination.valid?
  end

  test "status enum includes active paused and disabled" do
    assert_equal 0, Destination.statuses[:active]
    assert_equal 1, Destination.statuses[:paused]
    assert_equal 2, Destination.statuses[:disabled]
  end

  test "default status is active" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "https://api.example.com/webhooks"
    )
    destination.save!
    assert destination.status_active?
  end

  test "disabled destination" do
    destination = destinations(:disabled_destination)
    assert destination.status_disabled?
  end

  test "auth_type enum includes none bearer basic and api_key" do
    assert_equal 0, Destination.auth_types[:none]
    assert_equal 1, Destination.auth_types[:bearer]
    assert_equal 2, Destination.auth_types[:basic]
    assert_equal 3, Destination.auth_types[:api_key]
  end

  test "default auth_type is none" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "https://api.example.com/webhooks"
    )
    destination.save!
    assert destination.auth_type_none?
  end

  test "bearer auth type" do
    destination = destinations(:staging_api)
    assert destination.auth_type_bearer?
  end

  test "belongs_to organization" do
    destination = destinations(:production_api)
    assert_equal organizations(:acme), destination.organization
  end

  test "has_many connections" do
    destination = destinations(:production_api)
    assert_respond_to destination, :connections
    assert destination.connections.count >= 1
  end

  test "destroying destination destroys connections" do
    destination = destinations(:production_api)
    connection_count = destination.connections.count
    assert connection_count > 0

    assert_difference "Connection.count", -connection_count do
      destination.destroy
    end
  end

  test "default headers is empty hash" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "https://api.example.com/webhooks"
    )
    destination.save!
    assert_equal({}, destination.headers)
  end

  test "default timeout_seconds is 30" do
    destination = Destination.new(
      organization: organizations(:acme),
      name: "My API",
      url: "https://api.example.com/webhooks"
    )
    destination.save!
    assert_equal 30, destination.timeout_seconds
  end
end
