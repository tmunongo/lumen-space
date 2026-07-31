require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_username = ENV["LUMEN_USERNAME"]
    @original_password = ENV["LUMEN_PASSWORD"]
    ENV["LUMEN_USERNAME"] = "lumen"
    ENV["LUMEN_PASSWORD"] = "secret123"
  end

  teardown do
    ENV["LUMEN_USERNAME"] = @original_username
    ENV["LUMEN_PASSWORD"] = @original_password
  end

  test "should get login page" do
    get login_url
    assert_response :success
    assert_select ".auth-card__title", "Lumen Space"
  end

  test "should redirect protected route to login when unauthenticated" do
    get root_url
    assert_redirected_to login_url(return_to: "/")
  end

  test "should log in with valid credentials" do
    post login_url, params: { username: "lumen", password: "secret123" }
    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
  end

  test "should fail login with invalid password" do
    post login_url, params: { username: "lumen", password: "wrongpassword" }
    assert_response :unprocessable_entity
    assert_select ".auth-alert--error", text: /Invalid username or password/
  end

  test "should log out and clear session" do
    post login_url, params: { username: "lumen", password: "secret123" }
    assert_redirected_to root_url

    delete logout_url
    assert_redirected_to login_url
  end
end
