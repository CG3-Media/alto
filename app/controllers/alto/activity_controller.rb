module Alto
  class ActivityController < ::Alto::ApplicationController
    before_action :set_board, if: -> { params[:board_slug].present? }

    def index
      activity_data = load_activity_data
      @activity_items = ::Alto::ActivityTimelineBuilder.new(activity_data, board: @board).build
    end

    private

    def set_board
      @board = ::Alto::Board.find(params[:board_slug])
      set_current_board(@board)
    end

    def load_activity_data
      if @board
        ::Alto::BoardActivityLoader.new(@board).load
      else
        ::Alto::GlobalActivityLoader.new.load
      end
    end
  end
end
