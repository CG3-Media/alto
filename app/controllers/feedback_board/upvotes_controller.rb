module FeedbackBoard
  class UpvotesController < ApplicationController
    before_action :check_vote_permission
    before_action :set_upvotable

    def create
      @upvote = @upvotable.upvotes.build(user_id: current_user.id)

      if @upvote.save
        respond_to do |format|
          format.html { redirect_back(fallback_location: feedback_board.tickets_path) }
          format.json { render json: { upvotes_count: @upvotable.upvotes_count, upvoted: true } }
        end
      else
        respond_to do |format|
          format.html { redirect_back(fallback_location: feedback_board.tickets_path, alert: 'Unable to upvote') }
          format.json { render json: { error: 'Unable to upvote' }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @upvote = @upvotable.upvotes.find_by(user_id: current_user.id)

      if @upvote&.destroy
        respond_to do |format|
          format.html { redirect_back(fallback_location: feedback_board.tickets_path) }
          format.json { render json: { upvotes_count: @upvotable.upvotes_count, upvoted: false } }
        end
      else
        respond_to do |format|
          format.html { redirect_back(fallback_location: feedback_board.tickets_path, alert: 'Unable to remove upvote') }
          format.json { render json: { error: 'Unable to remove upvote' }, status: :unprocessable_entity }
        end
      end
    end

    private

    def set_upvotable
      if params[:ticket_id]
        @upvotable = Ticket.find(params[:ticket_id])
      elsif params[:comment_id]
        @upvotable = Comment.find(params[:comment_id])
      else
        redirect_to feedback_board.tickets_path, alert: 'Invalid upvote target'
      end
    end

    def check_vote_permission
      unless can_vote?
        respond_to do |format|
          format.html { redirect_back(fallback_location: feedback_board.tickets_path, alert: 'You do not have permission to vote') }
          format.json { render json: { error: 'Permission denied' }, status: :forbidden }
        end
      end
    end
  end
end
