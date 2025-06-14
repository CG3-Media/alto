module Alto
  # Service object to build a sorted timeline from various activity sources
  class ActivityTimelineBuilder
    def initialize(activity_data, board: nil)
      @recent_tickets = activity_data[:recent_tickets]
      @recent_comments = activity_data[:recent_comments]
      @recent_upvotes = activity_data[:recent_upvotes]
      @board = board
    end

    def build
      items = []
      items.concat(ticket_events)
      items.concat(comment_events)
      items.concat(upvote_events)

      # Sort by timestamp descending and limit items
      items.sort_by { |item| item[:timestamp] }.reverse.first(limit)
    end

    private

    attr_reader :recent_tickets, :recent_comments, :recent_upvotes, :board

    def ticket_events
      recent_tickets.map do |ticket|
        {
          type: :ticket_created,
          timestamp: ticket.created_at,
          ticket: ticket,
          board: ticket.board,
          user_id: ticket.user_id
        }
      end
    end

    def comment_events
      recent_comments.map do |comment|
        {
          type: :comment_created,
          timestamp: comment.created_at,
          comment: comment,
          ticket: comment.ticket,
          board: comment.ticket.board,
          user_id: comment.user_id
        }
      end
    end

    def upvote_events
      recent_upvotes.map do |upvote|
        {
          type: :upvote_created,
          timestamp: upvote.created_at,
          upvote: upvote,
          upvotable: upvote.upvotable,
          board: upvote.upvotable.board,
          user_id: upvote.user_id
        }
      end
    end

    def limit
      @board ? 20 : 30
    end
  end
end
