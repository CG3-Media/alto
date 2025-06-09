module FeedbackBoard
  class UpvotesController < ::FeedbackBoard::ApplicationController
    before_action :check_vote_permission
    before_action :set_board_and_upvotable

    def create
      @upvote = @upvotable.upvotes.build(user_id: current_user.id)

      if @upvote.save
        respond_to do |format|
          format.html { redirect_back(fallback_location: fallback_path) }
          format.json { render json: { upvotes_count: @upvotable.upvotes_count, upvoted: true } }
        end
      else
        respond_to do |format|
          format.html { redirect_back(fallback_location: fallback_path, alert: 'Unable to upvote') }
          format.json { render json: { error: 'Unable to upvote' }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @upvote = @upvotable.upvotes.find_by(user_id: current_user.id)

      if @upvote&.destroy
        respond_to do |format|
          format.html { redirect_back(fallback_location: fallback_path) }
          format.json { render json: { upvotes_count: @upvotable.upvotes_count, upvoted: false } }
        end
      else
        respond_to do |format|
          format.html { redirect_back(fallback_location: fallback_path, alert: 'Unable to remove upvote') }
          format.json { render json: { error: 'Unable to remove upvote' }, status: :unprocessable_entity }
        end
      end
    end

    private

    def set_board_and_upvotable
      if params[:ticket_id]
        @board = Board.find_by!(slug: params[:board_slug])
        @upvotable = @board.tickets.find(params[:ticket_id])
      elsif params[:comment_id]
        @upvotable = Comment.find(params[:comment_id])
        @board = @upvotable.ticket.board
      else
        redirect_to feedback_board.root_path, alert: 'Invalid upvote target'
      end
    end

    def fallback_path
      if @upvotable.is_a?(Ticket)
        board_tickets_path(@board)
      elsif @upvotable.is_a?(Comment)
        board_ticket_path(@board, @upvotable.ticket)
      else
        feedback_board.root_path
      end
    end

    def check_vote_permission
      unless can_vote?
        respond_to do |format|
          format.html { redirect_back(fallback_location: fallback_path, alert: 'You do not have permission to vote') }
          format.json { render json: { error: 'Permission denied' }, status: :forbidden }
        end
      end
    end
  end
end
