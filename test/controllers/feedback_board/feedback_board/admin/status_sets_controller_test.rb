require "test_helper"

module FeedbackBoard
  class FeedbackBoard::Admin::StatusSetsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should get index" do
      get feedback_board_admin_status_sets_index_url
      assert_response :success
    end

    test "should get show" do
      get feedback_board_admin_status_sets_show_url
      assert_response :success
    end

    test "should get new" do
      get feedback_board_admin_status_sets_new_url
      assert_response :success
    end

    test "should get create" do
      get feedback_board_admin_status_sets_create_url
      assert_response :success
    end

    test "should get edit" do
      get feedback_board_admin_status_sets_edit_url
      assert_response :success
    end

    test "should get update" do
      get feedback_board_admin_status_sets_update_url
      assert_response :success
    end

    test "should get destroy" do
      get feedback_board_admin_status_sets_destroy_url
      assert_response :success
    end
  end
end
