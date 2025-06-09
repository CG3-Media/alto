module FeedbackBoard
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :authenticate_user!
    before_action :check_feedback_board_access!

    # Make these methods available to views
    helper_method :can_access_feedback_board?, :can_submit_tickets?, :can_comment?,
                  :can_vote?, :can_edit_tickets?, :can_access_admin?, :can_manage_boards?,
                  :can_access_board?, :current_board, :default_board

    # Permission methods with sensible defaults
    # Host apps can override these methods to customize behavior

    def can_access_feedback_board?
      return false unless current_user
      true # Default: allow access if user is logged in
    end

    def can_submit_tickets?
      return false unless current_user
      true # Default: allow ticket submission if user is logged in
    end

    def can_comment?
      return false unless current_user
      true # Default: allow commenting if user is logged in
    end

    def can_vote?
      return false unless current_user
      true # Default: allow voting if user is logged in
    end

    def can_edit_tickets?
      return false unless current_user
      false # Default: secure by default - only admins should edit
    end

    def can_access_admin?
      return false unless current_user
      can_edit_tickets? # Default: fallback to edit permission
    end

    def can_manage_boards?
      return false unless current_user
      can_edit_tickets? # Default: fallback to edit permission
    end

    def can_access_board?(board)
      return false unless current_user
      true # Default: allow access to all boards if user is logged in
    end

    # Current board session management
    def current_board
      @current_board ||= begin
        if session[:current_board_slug].present?
          FeedbackBoard::Board.find_by(slug: session[:current_board_slug]) || default_board
        else
          default_board
        end
      end
    end

    def set_current_board(board)
      session[:current_board_slug] = board.slug
      @current_board = board
    end

    def default_board
      @default_board ||= FeedbackBoard::Board.find_by(slug: 'feedback') ||
                          FeedbackBoard::Board.create!(
                            name: 'Feedback',
                            slug: 'feedback',
                            description: 'General feedback and feature requests'
                          )
    end

    private

    def authenticate_user!
      redirect_to main_app.root_path unless current_user
    end

    def check_feedback_board_access!
      unless can_access_feedback_board?
        redirect_to main_app.root_path, alert: 'You do not have access to the feedback board'
      end
    end

    def current_user
      # This should be overridden by the host application
      # Default implementation looks for main_app's current_user
      main_app.current_user if main_app.respond_to?(:current_user)
    end
  end
end
