module Alto
  class BoardAccessService
    def self.accessible_boards_for(current_user, current_user_is_admin: false)
      ::Alto::Board.accessible_to_user(current_user, current_user_is_admin: current_user_is_admin)
                   .ordered
                   .includes(:tickets)
    end

    def self.set_current_board_if_needed(boards, session)
      return unless boards.any? && session[:current_board_slug].blank?

      session[:current_board_slug] = boards.first.slug
    end
  end
end
