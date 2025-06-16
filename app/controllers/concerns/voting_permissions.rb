# Voting permission and validation concern
module VotingPermissions
  extend ActiveSupport::Concern

  private

  def check_vote_permission
    unless can_vote?
      respond_with_permission_denied
    end
  end

  def ensure_not_archived
    if upvotable_archived?
      respond_with_vote_error("Archived content cannot be upvoted")
    end
  end

  def upvotable_archived?
    case @upvotable
    when Alto::Ticket
      @upvotable.archived?
    when Alto::Comment
      @upvotable.ticket.archived?
    else
      false
    end
  end

  def set_board_and_upvotable
    if params[:ticket_id]
      @board = Alto::Board.find(params[:board_slug])
      @upvotable = @board.tickets.find(params[:ticket_id])
    elsif params[:comment_id]
      @upvotable = Alto::Comment.find(params[:comment_id])
      @board = @upvotable.ticket.board
    else
      redirect_to alto.alto_home_path, alert: "Invalid upvote target"
    end
  end
end
