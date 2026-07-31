ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)
end

class ActionDispatch::IntegrationTest
  def sign_in_as(username = "lumen", password = "lumen")
    post login_url, params: { username: username, password: password }
  end
end
