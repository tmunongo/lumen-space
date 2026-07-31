class ApplicationController < ActionController::Base
  before_action :authenticate!
  before_action :set_current_user_preferences

  helper_method :logged_in?, :current_user_name, :auth_required?

  private

  def auth_required?
    ENV["LUMEN_AUTH_DISABLED"].to_s.downcase != "true"
  end

  def logged_in?
    !auth_required? || session[:authenticated] == true
  end

  def current_user_name
    session[:username].presence || ENV["LUMEN_USERNAME"].presence || "lumen"
  end

  def authenticate!
    return unless auth_required?
    return if logged_in?

    respond_to do |format|
      format.html do
        redirect_to login_path(return_to: request.fullpath), alert: "Please sign in to access Lumen Space."
      end
      format.all do
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end

  def set_current_user_preferences
    @sort_by = session[:sort_by] || "modified"
    @show_archived = session[:show_archived] || false
  end
end
