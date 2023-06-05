require "test_helper"

class RecommendationsControllerTest < ActionDispatch::IntegrationTest
  test "should get search" do
    get recommendations_search_url
    assert_response :success
  end

  test "should get index" do
    get recommendations_index_url
    assert_response :success
  end

  test "should get show" do
    get recommendations_show_url
    assert_response :success
  end
end
