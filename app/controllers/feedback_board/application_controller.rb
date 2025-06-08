module FeedbackBoard
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :authenticate_user!
    before_action :check_feedback_board_access!

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

    def can_access_feedback_board?
      return false unless current_user
      # Default implementation - override in host application
      # Example: current_user.can?(:access_feedback_board)
      true
    end

    def can_submit_tickets?
      return false unless current_user
      # Default implementation - override in host application
      # Example: current_user.can?(:submit_feedback_tickets)
      true
    end

    def can_comment?
      return false unless current_user
      # Default implementation - override in host application
      # Example: current_user.can?(:comment_on_feedback)
      true
    end

    def can_vote?
      return false unless current_user
      # Default implementation - override in host application
      # Example: current_user.can?(:vote_on_feedback)
      true
    end
  end
end
