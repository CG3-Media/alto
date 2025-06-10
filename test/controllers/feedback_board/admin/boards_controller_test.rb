require 'test_helper'

module FeedbackBoard
  module Admin
    class BoardsControllerTest < ActionController::TestCase
      def setup
        @board = Board.create!(name: "Test Board", is_admin_only: false)

        # Mock admin permissions for all tests
        @controller.define_singleton_method(:can_access_admin?) { true }
        @controller.define_singleton_method(:current_user) { double("admin", id: 1) }
      end

      test "should create board with admin_only flag" do
        assert_difference('Board.count') do
          post :create, params: {
            board: {
              name: "New Admin Board",
              description: "Admin only board",
              item_label_singular: "ticket",
              is_admin_only: true
            }
          }
        end

        created_board = Board.find_by(name: "New Admin Board")
        assert created_board.admin_only?
        assert_redirected_to admin_boards_path
      end

      test "should create public board when admin_only is false" do
        assert_difference('Board.count') do
          post :create, params: {
            board: {
              name: "New Public Board",
              description: "Public board",
              item_label_singular: "ticket",
              is_admin_only: false
            }
          }
        end

        created_board = Board.find_by(name: "New Public Board")
        assert_not created_board.admin_only?
        assert created_board.publicly_accessible?
      end

      test "should update board admin_only status" do
        patch :update, params: {
          slug: @board.slug,
          board: {
            name: @board.name,
            is_admin_only: true
          }
        }

        @board.reload
        assert @board.admin_only?
        assert_redirected_to admin_boards_path
      end

      test "should show all boards in admin index including admin-only ones" do
        admin_board = Board.create!(name: "Admin Board", is_admin_only: true)
        public_board = Board.create!(name: "Public Board", is_admin_only: false)

        get :index
        assert_response :success

        boards = assigns(:board_stats).map { |stat| stat[:board] }
        assert_includes boards, admin_board
        assert_includes boards, public_board
        assert_includes boards, @board
      end

      test "should deny access to non-admin users" do
        # Override admin permission to false
        @controller.define_singleton_method(:can_access_admin?) { false }

        get :index
        assert_response :redirect
        assert_match(/You do not have permission/, flash[:alert])
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
end
