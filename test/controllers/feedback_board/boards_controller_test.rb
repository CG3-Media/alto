require 'test_helper'

module FeedbackBoard
  class BoardsControllerTest < ActionController::TestCase
    def setup
      @public_board = Board.create!(name: "Public Board", is_admin_only: false)
      @admin_board = Board.create!(name: "Admin Board", is_admin_only: true)
    end

    test "index shows only public boards for regular users" do
      # Mock regular user permissions
      @controller.define_singleton_method(:can_access_admin?) { false }
      @controller.define_singleton_method(:current_user) { double("user", id: 1) }

      get :index
      assert_response :success

      # Should include public board
      assert_includes assigns(:boards), @public_board
      # Should not include admin board
      assert_not_includes assigns(:boards), @admin_board
    end

    test "index shows all boards for admin users" do
      # Mock admin user permissions
      @controller.define_singleton_method(:can_access_admin?) { true }
      @controller.define_singleton_method(:current_user) { double("admin", id: 1) }

      get :index
      assert_response :success

      # Should include both boards
      assert_includes assigns(:boards), @public_board
      assert_includes assigns(:boards), @admin_board
    end

    test "redirect_to_default finds public board for regular users" do
      # Mock regular user permissions
      @controller.define_singleton_method(:can_access_admin?) { false }
      @controller.define_singleton_method(:can_manage_boards?) { false }
      @controller.define_singleton_method(:current_user) { double("user", id: 1) }

      # Mock the ensure_current_board_set method to avoid session issues
      @controller.define_singleton_method(:ensure_current_board_set) { |board| @current_board = board }

      get :redirect_to_default

      # Should redirect to a public board (not admin-only)
      assert_response :redirect
      # The redirect should not be to admin board path
      assert_not_match(/admin/, @response.location)
    end

    test "redirect_to_default finds any board for admin users" do
      # Mock admin user permissions
      @controller.define_singleton_method(:can_access_admin?) { true }
      @controller.define_singleton_method(:can_manage_boards?) { true }
      @controller.define_singleton_method(:current_user) { double("admin", id: 1) }

      # Mock the ensure_current_board_set method to avoid session issues
      @controller.define_singleton_method(:ensure_current_board_set) { |board| @current_board = board }

      get :redirect_to_default

      # Should redirect successfully
      assert_response :redirect
    end

    private

    def double(name, attributes = {})
      obj = Object.new
      attributes.each do |key, value|
        obj.define_singleton_method(key) { value }
      end
      obj
    end
  end
end
