require "test_helper"
require "redis"

class RedisConnectionTest < ActionDispatch::IntegrationTest
  setup do
    @redis = Redis.new(host: "localhost", port: 6380)
  end

  teardown do
    @redis.close
  end

  test "can connect to Redis" do
    assert_equal "PONG", @redis.ping
  end

  test "Redis version is 8.x" do
    info = @redis.info("server")
    assert_match(/^8\./, info["redis_version"])
  end

  test "can perform basic set and get operations" do
    @redis.set("test_key", "test_value")
    assert_equal "test_value", @redis.get("test_key")
    @redis.del("test_key")
  end

  test "can perform increment operations" do
    @redis.set("counter", 0)
    @redis.incr("counter")
    @redis.incr("counter")
    assert_equal "2", @redis.get("counter")
    @redis.del("counter")
  end
end
