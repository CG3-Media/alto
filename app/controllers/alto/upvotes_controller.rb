module Alto
  class UpvotesController < ::Alto::ApplicationController
    before_action :check_vote_permission
    before_action :set_board_and_upvotable
    before_action :ensure_not_archived

    def create
      @upvote = @upvotable.upvotes.build(user_id: current_user.id)

      if @upvote.save
        respond_to do |format|
          format.html { redirect_back(fallback_location: fallback_path) }
          format.json { render json: { upvotes_count: @upvotable.upvotes_count, upvoted: true } }
        end
      else
        respond_to do |format|
          format.html { redirect_back(fallback_location: fallback_path, alert: "Unable to upvote") }
          format.json { render json: { error: "Unable to upvote" }, status: :unprocessable_entity }
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
          format.html { redirect_back(fallback_location: fallback_path, alert: "Unable to remove upvote") }
          format.json { render json: { error: "Unable to remove upvote" }, status: :unprocessable_entity }
        end
      end
    end

    def toggle
      @upvote = @upvotable.upvotes.find_by(user_id: current_user.id)

      if @upvote
        # User has already upvoted, remove it
        @upvote.destroy
        upvoted = false
      else
        # User hasn't upvoted, create new upvote
        @upvote = @upvotable.upvotes.create!(user_id: current_user.id)
        upvoted = true
      end

      respond_to do |format|
        format.html { redirect_back(fallback_location: fallback_path) }
        format.json { render json: { upvotes_count: @upvotable.upvotes_count, upvoted: upvoted } }
      end
    rescue ActiveRecord::RecordInvalid => e
      respond_to do |format|
        format.html { redirect_back(fallback_location: fallback_path, alert: "Unable to toggle upvote") }
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end

    private

    def set_board_and_upvotable
      if params[:ticket_id]
        @board = Board.find(params[:board_slug])
        @upvotable = @board.tickets.find(params[:ticket_id])
      elsif params[:comment_id]
        @upvotable = Comment.find(params[:comment_id])
        @board = @upvotable.ticket.board
      else
        redirect_to alto.alto_home_path, alert: "Invalid upvote target"
      end
    end

    def fallback_path
      if @upvotable.is_a?(Ticket)
        board_tickets_path(@board)
      elsif @upvotable.is_a?(Comment)
        board_ticket_path(@board, @upvotable.ticket)
      else
        alto.alto_home_path
      end
    end

    def check_vote_permission
      unless can_vote?
        respond_to do |format|
          format.html { redirect_back(fallback_location: fallback_path, alert: "You do not have permission to vote") }
          format.json { render json: { error: "Permission denied" }, status: :forbidden }
        end
      end
    end

    def ensure_not_archived
      # Check if upvotable is a ticket and archived, or if it's a comment on an archived ticket
      archived = if @upvotable.is_a?(Ticket)
                   @upvotable.archived?
      elsif @upvotable.is_a?(Comment)
                   @upvotable.ticket.archived?
      else
                   false
      end

      if archived
        respond_to do |format|
          format.html { redirect_back(fallback_location: fallback_path, alert: "Archived content cannot be upvoted") }
          format.json { render json: { error: "Archived content cannot be upvoted" }, status: :unprocessable_entity }
        end
      end
    end
  end
end
