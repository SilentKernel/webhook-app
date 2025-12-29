ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Parallel tests disabled due to pg gem segfault with Ruby 3.4
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

class ActiveJob::TestCase
  include ActionMailer::TestHelper
end
