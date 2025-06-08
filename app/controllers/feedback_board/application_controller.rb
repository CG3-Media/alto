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

      # Check if main app has overridden this method
      if main_app_controller.respond_to?(:can_access_feedback_board?, true)
        main_app_controller.send(:can_access_feedback_board?)
      else
        # Default implementation
        true
      end
    end

    def can_submit_tickets?
      return false unless current_user

      # Check if main app has overridden this method
      if main_app_controller.respond_to?(:can_submit_tickets?, true)
        main_app_controller.send(:can_submit_tickets?)
      else
        # Default implementation
        true
      end
    end

    def can_comment?
      return false unless current_user

      # Check if main app has overridden this method
      if main_app_controller.respond_to?(:can_comment?, true)
        main_app_controller.send(:can_comment?)
      else
        # Default implementation
        true
      end
    end

    def can_vote?
      return false unless current_user

      # Check if main app has overridden this method
      if main_app_controller.respond_to?(:can_vote?, true)
        main_app_controller.send(:can_vote?)
      else
        # Default implementation
        true
      end
    end

    def can_edit_tickets?
      return false unless current_user

      # Check if main app has overridden this method
      if main_app_controller.respond_to?(:can_edit_tickets?, true)
        main_app_controller.send(:can_edit_tickets?)
      else
        # Default implementation - secure by default
        false
      end
    end

    def can_access_admin?
      return false unless current_user

      # Check if main app has overridden this method
      if main_app_controller.respond_to?(:can_access_admin?, true)
        main_app_controller.send(:can_access_admin?)
      else
        # Default implementation - secure by default, fallback to can_edit_tickets
        can_edit_tickets?
      end
    end

    # Helper method to get main app controller for delegation
    def main_app_controller
      @main_app_controller ||= main_app.try(:application_controller) || ::ApplicationController.new
    end
  end
end
