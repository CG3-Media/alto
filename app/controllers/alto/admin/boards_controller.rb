module Alto
  module Admin
    class BoardsController < ::Alto::ApplicationController
      before_action :ensure_admin_access
      before_action :set_board, only: [ :edit, :update, :destroy ]

      def index
        @boards = ::Alto::Board.includes(:tickets).ordered
        @board_stats = @boards.map do |board|
          {
            board: board,
            tickets_count: board.tickets_count,
            recent_tickets: board.recent_tickets(3),
            popular_tickets: board.popular_tickets(3)
          }
        end
      end

      def new
        @board = ::Alto::Board.new
        # Build one initial field so form shows at least one field by default
        @board.fields.build(position: 0)
      end

      def create
        @board = ::Alto::Board.new(board_params)

        if @board.save
          redirect_to admin_boards_path, notice: "Board '#{@board.name}' was successfully created."
        else
          # Ensure at least one field is present for re-rendering the form
          @board.fields.build(position: 0) if @board.fields.empty?
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @board.update(board_params)
          redirect_to board_path(@board), notice: "Board '#{@board.name}' was successfully updated."
        else
          # Ensure at least one field is present for re-rendering the form
          @board.fields.build(position: 0) if @board.fields.empty?
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        unless @board.can_be_deleted?
          redirect_to admin_boards_path, alert: "Cannot delete board with tickets. Move or delete tickets first."
          return
        end

        @board.destroy
        redirect_to admin_boards_path, notice: "Board '#{@board.name}' was successfully deleted."
      end

      private

      def set_board
        @board = ::Alto::Board.find(params[:slug])
      end

      def board_params
        params.require(:board).permit(
          :name, :description, :item_label_singular, :status_set_id,
          :is_admin_only, :single_view, :fields_data, :allow_public_tagging, :allow_voting,
          fields_attributes: [
            :id, :label, :field_type, :required, :placeholder,
            :position, :_destroy, field_options: []
          ]
        )
      end
    end
  end
end
