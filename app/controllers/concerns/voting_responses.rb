# Handles standardized responses for voting actions
module VotingResponses
  extend ActiveSupport::Concern

  private

  def respond_with_vote_success(upvotable, upvoted)
    respond_to do |format|
      format.html { redirect_back(fallback_location: fallback_path) }
      format.json { render json: { upvotes_count: upvotable.upvotes_count, upvoted: upvoted } }
    end
  end

  def respond_with_vote_error(message)
    respond_to do |format|
      format.html { redirect_back(fallback_location: fallback_path, alert: message) }
      format.json { render json: { error: message }, status: :unprocessable_entity }
    end
  end

  def respond_with_permission_denied
    respond_to do |format|
      format.html { redirect_back(fallback_location: fallback_path, alert: "You do not have permission to vote") }
      format.json { render json: { error: "Permission denied" }, status: :forbidden }
    end
  end

  def fallback_path
    if @upvotable.is_a?(Alto::Ticket)
      alto.board_tickets_path(@board)
    elsif @upvotable.is_a?(Alto::Comment)
      alto.board_ticket_path(@board, @upvotable.ticket)
    else
      alto.alto_home_path
    end
  end
end
