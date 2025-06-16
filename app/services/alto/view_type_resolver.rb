require 'ostruct'

module Alto
  # Service object to determine which view type to use for tickets
  # Handles board preferences, user preferences, and URL overrides
  class ViewTypeResolver
    def initialize(board, view_param, session)
      @board = board
      @view_param = view_param
      @session = session
    end

    def resolve
      if board_enforces_single_view?
        resolve_board_enforced_view
      elsif user_explicitly_chose_view?
        resolve_explicit_user_choice
      else
        resolve_from_stored_preference
      end
    end

    def show_toggle?
      !board_enforces_single_view?
    end

    private

    attr_reader :board, :view_param, :session

    def board_enforces_single_view?
      @board.single_view.present?
    end

    def resolve_board_enforced_view
      OpenStruct.new(
        view_type: @board.single_view,
        show_toggle: false
      )
    end

    def user_explicitly_chose_view?
      view_param.present?
    end

    def resolve_explicit_user_choice
      view_type = view_param == "list" ? "list" : "card"
      store_user_preference(view_type)

      OpenStruct.new(
        view_type: view_type,
        show_toggle: true
      )
    end

    def resolve_from_stored_preference
      stored_preferences = session[:view_preferences] || {}
      view_type = stored_preferences[@board.slug] || "list"

      OpenStruct.new(
        view_type: view_type,
        show_toggle: true
      )
    end

    def store_user_preference(view_type)
      session[:view_preferences] ||= {}
      session[:view_preferences][@board.slug] = view_type
    end
  end
end
