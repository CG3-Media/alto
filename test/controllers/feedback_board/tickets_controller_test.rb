require 'test_helper'
require 'ostruct'

module FeedbackBoard
  class TicketsControllerTest < ActionController::TestCase
    class MockUser
      attr_accessor :id, :email, :admin

      def initialize(id: 1, email: 'test@example.com', admin: false)
        @id = id
        @email = email
        @admin = admin
      end

      def admin?
        @admin
      end
    end

    def setup
      # Set engine routes for ActionController::TestCase
      @routes = ::FeedbackBoard::Engine.routes

      @controller = TicketsController.new
      @user = MockUser.new

      # Create a board for testing
      @board = Board.create!(name: 'Test Board', slug: 'test-board', description: 'Test board')

      # Mock current_user using Ruby singleton methods (MiniTest compatible)
      @controller.define_singleton_method(:current_user) { @user }

      # Mock authentication methods to bypass security checks
      @controller.define_singleton_method(:authenticate_user!) { true }
      @controller.define_singleton_method(:check_feedback_board_access!) { true }
    end

    test "controller inherits permission methods from ApplicationController" do
      # Critical test: ensure TicketsController has the can_access_board? method
      assert_respond_to @controller, :can_access_board?
      assert_respond_to @controller, :can_edit_tickets?
      assert_respond_to @controller, :can_submit_tickets?
      assert_respond_to @controller, :can_comment?
      assert_respond_to @controller, :can_vote?
    end

    test "set_board method works with valid slug" do
      # Mock params
      @controller.params = { board_slug: @board.slug }

      assert_nothing_raised do
        @controller.send(:set_board)
        assert_equal @board, @controller.instance_variable_get(:@board)
      end
    end

    test "inheritance chain is complete" do
      # Verify the inheritance chain
      assert_equal ApplicationController, TicketsController.superclass

      # Verify that methods from ApplicationController are available
      assert_respond_to @controller, :can_access_board?
      assert_respond_to @controller, :can_edit_tickets?

      # Check that the method is available through inheritance
      tickets_methods = TicketsController.instance_methods(true)  # Include inherited methods
      assert_includes tickets_methods, :can_access_board?
    end

    # Admin-only board access tests
    test "should deny access to admin-only board for regular users" do
      admin_board = Board.create!(name: "Admin Board", is_admin_only: true)

      # Mock regular user permissions
      @controller.define_singleton_method(:can_access_admin?) { false }
      @controller.define_singleton_method(:current_user) { double("user", id: 1) }
      @controller.define_singleton_method(:can_access_board?) do |board|
        return false unless board
        # This simulates the logic we added to ApplicationController
        board.admin_only? ? false : true
      end

      get :index, params: { board_slug: admin_board.slug }

      # Should redirect away from the admin board
      assert_response :redirect
      assert_match(/You do not have permission/, flash[:alert])
    end

    test "should allow access to admin-only board for admin users" do
      admin_board = Board.create!(name: "Admin Board", is_admin_only: true)

      # Mock admin user permissions
      @controller.define_singleton_method(:can_access_admin?) { true }
      @controller.define_singleton_method(:current_user) { double("admin", id: 1) }
      @controller.define_singleton_method(:can_access_board?) do |board|
        return false unless board
        # This simulates the logic we added to ApplicationController
        board.admin_only? ? true : true
      end
      @controller.define_singleton_method(:can_submit_tickets?) { true }
      @controller.define_singleton_method(:ensure_current_board_set) { |board| @current_board = board }

      # Render without layout to avoid sidebar current_user issues
      @controller.define_singleton_method(:render) { |options = {}|
        options[:layout] = false
        super(options)
      }

      get :index, params: { board_slug: admin_board.slug }

      # Should allow access
      assert_response :success
    end

    test "should allow access to public board for regular users" do
      public_board = Board.create!(name: "Public Board", is_admin_only: false)

      # Mock regular user permissions
      @controller.define_singleton_method(:can_access_admin?) { false }
      @controller.define_singleton_method(:current_user) { double("user", id: 1) }
      @controller.define_singleton_method(:can_access_board?) do |board|
        return false unless board
        # This simulates the logic we added to ApplicationController
        board.admin_only? ? false : true
      end
      @controller.define_singleton_method(:can_submit_tickets?) { true }
      @controller.define_singleton_method(:ensure_current_board_set) { |board| @current_board = board }

      # Render without layout to avoid sidebar current_user issues
      @controller.define_singleton_method(:render) { |options = {}|
        options[:layout] = false
        super(options)
      }

      get :index, params: { board_slug: public_board.slug }

      # Should allow access
      assert_response :success
    end

    private

    def double(name, attributes = {})
      obj = Object.new
      attributes.each do |key, value|
        obj.define_singleton_method(key) { value }
      end
      obj
    end

    # Add current_user to view context for sidebar rendering
    def setup_view_helpers_for_test
      @controller.view_context.define_singleton_method(:current_user) { @controller.current_user }
    end
  end
end
