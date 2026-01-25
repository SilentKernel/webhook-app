# frozen_string_literal: true

class HealthController < ActionController::Base
  def show
    check_database!
    check_redis!
    render plain: "OK"
  rescue StandardError => e
    render plain: "Service Unavailable: #{e.message}", status: :service_unavailable
  end

  private

  def check_database!
    ActiveRecord::Base.connection.execute("SELECT 1")
  end

  def check_redis!
    redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
    Redis.new(url: redis_url).ping
  end
end
