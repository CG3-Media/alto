module FeedbackBoard
  class GlobalActivityController < ::FeedbackBoard::ApplicationController

    def index
      # Load recent tickets, comments, and upvotes across all boards
      @recent_tickets = ::FeedbackBoard::Ticket
                         .includes(:board, :comments, :upvotes)
                         .recent
                         .limit(15)

      @recent_comments = ::FeedbackBoard::Comment
                          .includes(:ticket => :board, :upvotes)
                          .recent
                          .limit(15)

      @recent_upvotes = ::FeedbackBoard::Upvote
                         .joins("JOIN feedback_board_tickets ON feedback_board_upvotes.upvotable_type = 'FeedbackBoard::Ticket' AND feedback_board_upvotes.upvotable_id = feedback_board_tickets.id")
                         .includes(:upvotable => :board)
                         .order(created_at: :desc)
                         .limit(15)

      # Combine and sort all activity by timestamp
      @activity_items = build_global_activity_timeline
    end

    private

    def build_global_activity_timeline
      items = []

      # Add ticket creation events
      @recent_tickets.each do |ticket|
        items << {
          type: :ticket_created,
          timestamp: ticket.created_at,
          ticket: ticket,
          board: ticket.board,
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
          board: comment.ticket.board,
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
          board: upvote.upvotable.board,
          user_id: upvote.user_id
        }
      end

      # Sort by timestamp descending and limit to recent 30 items
      items.sort_by { |item| item[:timestamp] }.reverse.first(30)
    end
  end
end
