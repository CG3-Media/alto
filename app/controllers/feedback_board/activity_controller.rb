module FeedbackBoard
  class ActivityController < ::FeedbackBoard::ApplicationController
    before_action :set_board

    def index
      # Load recent tickets, comments, and upvotes for the board
      # Use a union-like approach to get mixed activity types
      @recent_tickets = @board.tickets
                              .includes(:comments, :upvotes)
                              .recent
                              .limit(10)

      @recent_comments = ::FeedbackBoard::Comment
                          .joins(:ticket)
                          .where(ticket: { board: @board })
                          .includes(:ticket, :upvotes)
                          .recent
                          .limit(10)

      @recent_upvotes = ::FeedbackBoard::Upvote
                         .joins("JOIN feedback_board_tickets ON feedback_board_upvotes.upvotable_type = 'FeedbackBoard::Ticket' AND feedback_board_upvotes.upvotable_id = feedback_board_tickets.id")
                         .where(feedback_board_tickets: { board_id: @board.id })
                         .includes(:upvotable)
                         .order(created_at: :desc)
                         .limit(10)

      # Combine and sort all activity by timestamp
      @activity_items = build_activity_timeline
    end

    private

    def set_board
      @board = ::FeedbackBoard::Board.find(params[:board_slug])
      set_current_board(@board)
    end

    def build_activity_timeline
      items = []

      # Add ticket creation events
      @recent_tickets.each do |ticket|
        items << {
          type: :ticket_created,
          timestamp: ticket.created_at,
          ticket: ticket,
          user_id: ticket.user_id
        }
      end

      # Add comment events
      @recent_comments.each do |comment|
        items << {
          type: :comment_created,
          timestamp: comment.created_at,
          comment: comment,
          ticket: comment.ticket,
          user_id: comment.user_id
        }
      end

      # Add upvote events (only for tickets in this implementation)
      @recent_upvotes.each do |upvote|
        items << {
          type: :upvote_created,
          timestamp: upvote.created_at,
          upvote: upvote,
          upvotable: upvote.upvotable,
          user_id: upvote.user_id
        }
      end

      # Sort by timestamp descending and limit to recent 20 items
      items.sort_by { |item| item[:timestamp] }.reverse.first(20)
    end
  end
end
