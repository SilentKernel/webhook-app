require "test_helper"

class DatabaseConnectionTest < ActionDispatch::IntegrationTest
  test "database adapter is PostgreSQL" do
    assert_equal "PostgreSQL", ActiveRecord::Base.connection.adapter_name
  end

  test "can execute SQL queries" do
    result = ActiveRecord::Base.connection.execute("SELECT 1 AS value")
    assert_equal 1, result.first["value"]
  end

  test "PostgreSQL version is 17.x" do
    result = ActiveRecord::Base.connection.execute("SELECT version()")
    version_string = result.first["version"]
    assert_match(/PostgreSQL 17/, version_string)
  end

  test "database name matches test environment" do
    result = ActiveRecord::Base.connection.execute("SELECT current_database()")
    assert_equal "webhook_test", result.first["current_database"]
  end
end
