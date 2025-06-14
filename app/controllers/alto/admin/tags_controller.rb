module Alto
  module Admin
    class TagsController < ::Alto::ApplicationController
      before_action :ensure_can_manage_boards
      before_action :set_board
      before_action :set_tag, only: [:show, :edit, :update, :destroy]

      def index
        @tags = @board.tags.ordered.includes(:taggings)
        @tag_stats = {
          total: @tags.count,
          used: @tags.used.count,
          unused: @tags.unused.count
        }
      end

      def show
        @tagged_tickets = @tag.tickets.includes(:user, :board).limit(10)
      end

      def new
        @tag = @board.tags.build
      end

      def create
        @tag = @board.tags.build(tag_params)

        if @tag.save
          redirect_to admin_board_tags_path(@board),
                      notice: "Tag '#{@tag.name}' was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @tag.update(tag_params)
          redirect_to admin_board_tags_path(@board),
                      notice: "Tag '#{@tag.name}' was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        tag_name = @tag.name
        usage_count = @tag.usage_count

        if usage_count > 0 && !params[:force]
          redirect_to admin_board_tags_path(@board),
                      alert: "Cannot delete tag '#{tag_name}' - it's used by #{usage_count} #{usage_count == 1 ? 'ticket' : 'tickets'}. Use 'Force Delete' if you're sure."
          return
        end

        @tag.destroy!
        redirect_to admin_board_tags_path(@board),
                    notice: "Tag '#{tag_name}' was successfully deleted."
      end

      private

      def set_board
        @board = ::Alto::Board.find(params[:board_slug])
      end

      def set_tag
        @tag = @board.tags.find(params[:id])
      end

      def tag_params
        params.require(:tag).permit(:name, :color)
      end

      def ensure_can_manage_boards
        unless can_manage_boards?
          redirect_to alto_home_path, alert: "You do not have permission to manage tags."
        end
      end
    end
  end
end
