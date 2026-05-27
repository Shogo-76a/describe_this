require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "should get top" do
    get games_top_url
    assert_response :success
  end
end
