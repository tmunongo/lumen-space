class SessionsController < ApplicationController
  skip_before_action :authenticate!

  def new
    redirect_to root_path if logged_in?
  end

  def create
    expected_username = ENV["LUMEN_USERNAME"].presence || "lumen"
    expected_password = ENV["LUMEN_PASSWORD"].presence || "lumen"

    username_input = params[:username].to_s
    password_input = params[:password].to_s

    valid_username = ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(username_input),
      Digest::SHA256.hexdigest(expected_username)
    )

    valid_password = ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(password_input),
      Digest::SHA256.hexdigest(expected_password)
    )

    if valid_username && valid_password
      reset_session
      session[:authenticated] = true
      session[:username] = username_input
      redirect_to params[:return_to].presence || root_path, notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid username or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Signed out successfully."
  end
end
