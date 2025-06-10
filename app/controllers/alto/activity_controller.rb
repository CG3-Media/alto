module Alto
  class ActivityController < ::Alto::ApplicationController
    before_action :set_board, if: -> { params[:board_slug].present? }

    def index
      if @board
        # Board-specific activity
        load_board_activity
      else
        # Global activity across all boards
        load_global_activity
      end

      # Combine and sort all activity by timestamp
      @activity_items = build_activity_timeline
    end

    private

    def set_board
      @board = ::Alto::Board.find(params[:board_slug])
      set_current_board(@board)
    end

    def load_board_activity
      @recent_tickets = @board.tickets
                              .includes(:comments, :upvotes)
                              .recent
                              .limit(10)

      @recent_comments = ::Alto::Comment
                          .joins(:ticket)
                          .where(ticket: { board: @board })
                          .includes(:ticket, :upvotes)
                          .recent
                          .limit(10)

      @recent_upvotes = ::Alto::Upvote
                         .joins("JOIN alto_tickets ON alto_upvotes.upvotable_type = 'Alto::Ticket' AND alto_upvotes.upvotable_id = alto_tickets.id")
                         .where(alto_tickets: { board_id: @board.id })
                         .includes(:upvotable)
                         .order(created_at: :desc)
                         .limit(10)
    end

    def load_global_activity
      @recent_tickets = ::Alto::Ticket
                         .includes(:board, :comments, :upvotes)
                         .recent
                         .limit(15)

      @recent_comments = ::Alto::Comment
                          .includes(ticket: :board, upvotes: [])
                          .recent
                          .limit(15)

      @recent_upvotes = ::Alto::Upvote
                         .joins("JOIN alto_tickets ON alto_upvotes.upvotable_type = 'Alto::Ticket' AND alto_upvotes.upvotable_id = alto_tickets.id")
                         .includes(upvotable: :board)
                         .order(created_at: :desc)
                         .limit(15)
    end

    def build_activity_timeline
      items = []
      limit = @board ? 20 : 30

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

      # Sort by timestamp descending and limit items
      items.sort_by { |item| item[:timestamp] }.reverse.first(limit)
    end
  end
end
