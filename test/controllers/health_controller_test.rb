# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "returns 200 when database and redis are available" do
    get rails_health_check_url

    assert_response :ok
    assert_equal "OK", response.body
  end

  test "returns 503 when database is unavailable" do
    # Create a mock connection that raises on execute
    mock_connection = Object.new
    mock_connection.define_singleton_method(:execute) do |_query|
      raise ActiveRecord::ConnectionNotEstablished, "Database connection failed"
    end

    ActiveRecord::Base.stub(:connection, mock_connection) do
      get rails_health_check_url

      assert_response :service_unavailable
      assert_includes response.body, "Service Unavailable"
      assert_includes response.body, "Database connection failed"
    end
  end

  test "returns 503 when redis is unavailable" do
    # Create a mock Redis that raises on ping
    failing_redis = Object.new
    failing_redis.define_singleton_method(:ping) do
      raise Redis::CannotConnectError, "Redis connection failed"
    end

    Redis.stub(:new, failing_redis) do
      get rails_health_check_url

      assert_response :service_unavailable
      assert_includes response.body, "Service Unavailable"
      assert_includes response.body, "Redis connection failed"
    end
  end
end
