module Alto
  # Service object to load recent activity for a specific board
  class BoardActivityLoader
    def initialize(board)
      @board = board
    end

    def load
      {
        recent_tickets: load_recent_tickets,
        recent_comments: load_recent_comments,
        recent_upvotes: load_recent_upvotes
      }
    end

    private

    attr_reader :board

    def load_recent_tickets
      @board.tickets
            .active
            .includes(:comments, :upvotes)
            .recent
            .limit(10)
    end

    def load_recent_comments
      ::Alto::Comment
        .joins(:ticket)
        .where(ticket: { board: @board, archived: false })
        .includes(:ticket, :upvotes)
        .recent
        .limit(10)
    end

    def load_recent_upvotes
      ::Alto::Upvote
        .joins("JOIN alto_tickets ON alto_upvotes.upvotable_type = 'Alto::Ticket' AND alto_upvotes.upvotable_id = alto_tickets.id")
        .where(alto_tickets: { board_id: @board.id, archived: false })
        .includes(:upvotable)
        .order(created_at: :desc)
        .limit(10)
    end
  end
end
