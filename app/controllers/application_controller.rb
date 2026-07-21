class ApplicationController < ActionController::Base
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  before_action :authenticate!
  before_action :set_current_user_preferences

  private

  def authenticate!
    username = ENV['LUMEN_USERNAME'].presence || 'lumen'
    password = ENV['LUMEN_PASSWORD'].presence
    return unless password.present?

    authenticate_or_request_with_http_basic('Lumen Space') do |u, p|
      ActiveSupport::SecurityUtils.secure_compare(u, username) &
        ActiveSupport::SecurityUtils.secure_compare(p, password)
    end
  end

  def set_current_user_preferences
    @sort_by = session[:sort_by] || 'modified'
    @show_archived = session[:show_archived] || false
  end
end
